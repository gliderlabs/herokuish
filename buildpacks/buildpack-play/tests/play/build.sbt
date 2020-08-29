name := "exampleApp"

version := "1.0-SNAPSHOT"

libraryDependencies ++= Seq(
  javaJdbc,
  guice
)

lazy val root = (project in file(".")).enablePlugins(PlayScala)
