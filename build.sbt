enablePlugins(PackPlugin)

//
// Project metadata
//

name := "tempgres-server"

organization := "dk.cwconsult"

version := "1.1"

//
// Compiler settings
//

scalaVersion in ThisBuild := "2.12.4"

scalacOptions in ThisBuild ++= Seq(
  "-Xlint",
  "-Xfatal-warnings",
  "-deprecation",
  "-unchecked",
  "-feature",
  "-encoding", "utf8")

//
// Packaging
//

packMain := Map("tempgres-server" -> "tempgres.server.http.Main")

//
// Projects
//

libraryDependencies ++= Seq(
  Dependencies.javAssist,
  Dependencies.log4jApi,
  Dependencies.postgreSQLJDBC4,
  Dependencies.scalaArm,
  Dependencies.typeSafeConfig,
  Dependencies.unfiltered,
  Dependencies.unfilteredNetty,
  Dependencies.unfilteredNettyServer
)

libraryDependencies ++= Dependencies.log4jImpl
