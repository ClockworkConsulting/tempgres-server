package tempgres.server.http

import io.netty.channel.ChannelHandler.Sharable
import java.util.UUID
import java.util.concurrent.Executors
import javax.sql.DataSource
import org.apache.logging.log4j.{Logger, LogManager}
import resource._
import scala.util.control.NonFatal
import tempgres.server.settings.{DatabaseSettings, HttpSettings}
import unfiltered.Cycle.Intent
import unfiltered.netty.{ServerErrorResponse, cycle}
import unfiltered.request.POST
import unfiltered.response.ResponseString

class ServerComponent(dataSource: DataSource, httpSettings: HttpSettings, databaseSettings: DatabaseSettings) {

  private[this] val logger: Logger = LogManager.getLogger(classOf[ServerComponent])

  /**
   * Mutex we use to ensure that only one server thread is copying the template database
   * at any given time. Without this, spurious conflicts can occur if multiple server threads
   * are cloning the database and it takes long enough for the timeout to expire.
   */
  private[this] val mutex: Object = new Object()

  /**
   * Executor for delayed deletion of temporary databases.
   */
  private[this] val scheduledExecutor = Executors.newScheduledThreadPool(8)

  /**
   * Quote an identifier.
   */
  private[this] def quoteIdentifier(s: String): String =
    if (s.contains('\'') || s.contains('"')) {
     throw new IllegalArgumentException(s"Cannot handle identifiers with embedded quotes: $s")
    } else {
      "\"" + s + "\""
    }

  /**
   * Force-drop database
   */
  private[this] def dropDatabase(name: String): Unit = {
    // Since this is running in a separate thread we need explicit
    // exception handling to avoid silent exceptions.
    try {
      // Get a connection to the database.
      managed(dataSource.getConnection).acquireAndGet { connection =>
        // Create a Statement that we're going to reuse
        managed(connection.createStatement()).acquireAndGet { stmt =>
          // We need to block new connections to the temporary database; otherwise
          // a reconnect during the destruction could foil our attempt to drop.
          stmt.execute(
            s""" UPDATE pg_database
                    SET datallowconn = FALSE
                  WHERE datname = '$name'""")
          // Now we can kill the backends, i.e. terminate all the connections. No
          // new connections can be created because of the previous block.
          stmt.execute(
            s""" SELECT pg_terminate_backend(pid)
                   FROM pg_stat_activity
                  WHERE pid <> pg_backend_pid()
                    AND datname = '$name'""")
          // Finally, we can drop.
          stmt.execute(
            s"DROP DATABASE IF EXISTS ${quoteIdentifier(name)}")
          logger.info(s"Dropped temporary database: $name")
        }
      }
    } catch {
      case NonFatal(e) =>
        logger.error("Exception occurred while creating temporary database", e)
    }
  }

  /**
   * Create temporary database with given name. Automatically schedules deletion of the database.
   */
  private[this] def createTemporaryDatabase(name: String): Unit = {
    // Connect to the administrative database.
    managed(dataSource.getConnection()).acquireAndGet { connection =>
      // Since only one client can copy the template database at a time, we need
      // a mutex here.
      mutex synchronized {
        // Create the temporary database
        managed(connection.createStatement()).acquireAndGet { stmt =>
          stmt.execute(
            s"""
              CREATE DATABASE ${quoteIdentifier(name)}
                WITH TEMPLATE ${quoteIdentifier(databaseSettings.templateDatabase)}
                        OWNER ${quoteIdentifier(databaseSettings.clientCredentials.user)}""")
        }
        logger.info(s"Created temporary database: $name")
      }
      // Register a scheduled task to kill the database after the appropriate certain delay.
      val cleanUpRunnable = new Runnable {
        override def run(): Unit = {
          dropDatabase(name)
        }
      }
      scheduledExecutor.schedule(cleanUpRunnable, databaseSettings.duration.length, databaseSettings.duration.unit)
    }
  }

  /**
   * Start the HTTP service
   */
  def start(): Unit = {
    // Build the HTTP server
    @Sharable
    object NettyResourceServer extends cycle.Plan with cycle.DeferralExecutor with cycle.DeferredIntent with ServerErrorResponse {
      override val underlying =
        Executors.newCachedThreadPool()
      override def intent: Intent[Any, Any] = {
        case httpReq @ POST(_) => {
          // Generate a random name
          val temporaryDatabaseName = "temp_" + UUID.randomUUID().toString.replace('-','_')
          // Create the database and register clean-up
          createTemporaryDatabase(temporaryDatabaseName)
          // Build the response
          val clientCredentials = databaseSettings.clientCredentials
          val server: String = databaseSettings.publishedAddress.host
          val port: Int = databaseSettings.publishedAddress.port
          ResponseString(s"${clientCredentials.user}\n${clientCredentials.password}\n$server\n$port\n$temporaryDatabaseName")
        }
      }
    }
    // Start it up.
    unfiltered.netty.Server
      .http(port = httpSettings.listenPort)
      .chunked(1024 * 1024)
      .plan(NettyResourceServer)
      .start()
  }

}
