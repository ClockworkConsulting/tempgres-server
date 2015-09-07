package tempgres.server.settings

import com.typesafe.config.Config

case class HttpSettings(
  listenPort: Int)

object HttpSettings {

  def apply(config: Config): HttpSettings = HttpSettings(
    listenPort = config.getInt("listen-port"))

}
