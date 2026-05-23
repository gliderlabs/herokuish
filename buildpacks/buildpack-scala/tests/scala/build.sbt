name := """scala-getting-started"""
organization := "com.heroku"

version := "1.0-SNAPSHOT"

lazy val root = (project in file(".")).enablePlugins(PlayScala)

scalaVersion := "2.13.18"

libraryDependencies += guice
libraryDependencies += jdbc
libraryDependencies += "org.scalatestplus.play" %% "scalatestplus-play" % "7.0.1" % Test
libraryDependencies += "org.postgresql" % "postgresql" % "42.7.10"

// Adds additional packages into Twirl
//TwirlKeys.templateImports += "com.heroku.controllers._"

// Adds additional packages into conf/routes
// play.sbt.routes.RoutesKeys.routesImport += "com.heroku.binders._"
