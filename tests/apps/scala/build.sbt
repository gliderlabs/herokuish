import NativePackagerKeys._

packageArchetype.java_application

name := "hello"

version := "1.0"

scalaVersion := "2.10.4"

mainClass in Compile := Some("Web")

libraryDependencies ++= Seq(
  "com.twitter" % "finagle-http_2.10" % "6.18.0"
)
