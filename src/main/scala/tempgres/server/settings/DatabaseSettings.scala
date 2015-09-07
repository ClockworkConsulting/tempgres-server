package tempgres.server.settings

import com.typesafe.config.Config
import scala.concurrent.duration._

case class DatabaseSettings(
  administratorCredentials: Credentials,
  database: String,
  backendAddress: Address,
  publishedAddress: Address,
  clientCredentials: Credentials,
  templateDatabase: String,
  duration: Duration)

object DatabaseSettings {

  def apply(config: Config): DatabaseSettings = DatabaseSettings(
    administratorCredentials = Credentials(config.getConfig("administrator-credentials")),
    database = config.getString("database"),
    backendAddress = Address(config.getConfig("backend-address")),
    publishedAddress = Address(config.getConfig("published-address")),
    clientCredentials = Credentials(config.getConfig("client-credentials")),
    templateDatabase = config.getString("templateDatabase"),
    duration = config.getInt("durationSeconds").seconds)

}
