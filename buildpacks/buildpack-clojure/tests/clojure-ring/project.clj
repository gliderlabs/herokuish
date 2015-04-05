(defproject opdemand-helloworld "1.0.0-SNAPSHOT"
  :description "OpDemand Example Application"
  :dependencies [
        [org.clojure/clojure "1.2.1"]
        [compojure "1.0.1"]
        [ring/ring-core "1.0.0"]
        [ring/ring-jetty-adapter "1.0.0"]
        [lein-ring "0.5.4"]
        ]
  :dev-dependencies [
    [org.clojure/clojure-contrib "1.2.0"]
    ]
  :ring {:handler helloworld.web/handler}
  :main "helloworld.web")
