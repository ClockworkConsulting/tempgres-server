package tempgres.server.settings

import com.typesafe.config.Config

case class Address(host: String, port: Int)

object Address {

  def apply(config: Config): Address = Address(
    host = config.getString("host"),
    port = config.getInt("port"))

}
