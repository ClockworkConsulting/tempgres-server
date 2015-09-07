package tempgres.server.settings

import com.typesafe.config.Config

case class Credentials(user: String, password: String)

object Credentials {

  def apply(config: Config): Credentials = Credentials(
    user = config.getString("user"),
    password = config.getString("password"))

}
