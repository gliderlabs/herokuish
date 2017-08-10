(defproject opdemand-helloworld "1.0.0-SNAPSHOT"
  :description "OpDemand Example Application"
  :min-lein-version "2.0.0"
  :dependencies [[org.clojure/clojure "1.7.0"]
                 [compojure "1.3.4"]
                 [ring/ring-core "1.3.2"]
                 [ring/ring-jetty-adapter "1.3.2"]
                 [lein-ring "0.8.13"]]
  :profiles
  {:dev {:dependencies [[ring/ring-mock "0.3.0"]]}}
  :ring {:handler helloworld.web/handler}
  :main helloworld.web)
