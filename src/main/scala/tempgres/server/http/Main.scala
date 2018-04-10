package tempgres.server.http

import com.typesafe.config.ConfigFactory
import org.apache.logging.log4j.LogManager
import org.apache.logging.log4j.Logger
import org.postgresql.ds.PGPoolingDataSource
import resource._
import tempgres.server.settings.{DatabaseSettings, HttpSettings}

object Main {

  private[this] val logger: Logger = LogManager.getLogger(classOf[ServerComponent])

  def main(args: Array[String]) {
    // Load configuration
    val configuration = ConfigFactory.load()
    val databaseSettings = DatabaseSettings(configuration.getConfig("database"))
    val httpSettings = HttpSettings(configuration.getConfig("http"))

    // Show HTTP configuration
    logger.info(s"HTTP configuration: $httpSettings")

    // Load PostgreSQL driver.
    Class.forName("org.postgresql.Driver")

    // Data Source
    val dataSource = new PGPoolingDataSource()
    dataSource.setServerName(databaseSettings.backendAddress.host)
    dataSource.setPortNumber(databaseSettings.backendAddress.port)
    dataSource.setDatabaseName(databaseSettings.database)
    dataSource.setUser(databaseSettings.administratorCredentials.user)
    dataSource.setPassword(databaseSettings.administratorCredentials.password)
    dataSource.setMaxConnections(32) // We shouldn't need more than one since we're using a mutex anyway

    // Test the connection immediately -- just to avoid delaying
    // configuration problems until a client actually tries to
    // use the service
    managed(dataSource.getConnection()).acquireAndGet { connection =>
      connection.setAutoCommit(false) // Some versions don't like "naked" commit with AutoCommit on
      connection.commit()
    }

    // Start -- the server never terminates
    new ServerComponent(dataSource, httpSettings, databaseSettings).start()
  }

}
