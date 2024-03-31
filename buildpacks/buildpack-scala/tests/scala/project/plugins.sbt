// Comment to get more information during initialization
logLevel := Level.Warn

// The Typesafe repository
resolvers += "Typesafe Releases Repository" at "https://repo.typesafe.com/typesafe/releases/"

// The Maven repository
resolvers += "Maven Central Server" at "https://repo1.maven.org/maven2"

// The "public" repository
resolvers += "public" at "https://repo1.maven.org/maven2"

addSbtPlugin("com.github.sbt" % "sbt-native-packager" % "1.9.16")
