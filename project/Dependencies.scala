import sbt._

object Dependencies {

  private[this] object Version {
    val unfilteredVersion = "0.8.4"
    val log4j = "2.3"
  }

  val scalaArm =
    "com.jsuereth" %% "scala-arm" % "1.4"

  val unfiltered =
    "net.databinder" %% "unfiltered" % Version.unfilteredVersion

  val unfilteredNetty =
    "net.databinder" %% "unfiltered-netty" % Version.unfilteredVersion

  val unfilteredNettyServer =
    "net.databinder" %% "unfiltered-netty-server" % Version.unfilteredVersion

  val postgreSQLJDBC4 =
    "org.postgresql" % "postgresql" % "9.3-1102-jdbc41"

  val typeSafeConfig =
    "com.typesafe" % "config" % "1.2.1" // Kept below 1.3.0 for compatibility with Java 7 in a container

  val javAssist = // Netty reccomends this for better performance
    "org.javassist" % "javassist" % "3.18.2-GA"

  val log4jApi =
    "org.apache.logging.log4j" % "log4j-api" % Version.log4j

  // Dependencies for a logging implementation
  val log4jImpl = Seq(
    "org.apache.logging.log4j" % "log4j-core" % Version.log4j,
    "org.apache.logging.log4j" % "log4j-jcl" % Version.log4j,     // Apache Commons Logging
    "org.apache.logging.log4j" % "log4j-slf4j-impl" % Version.log4j)

}
