	(ns helloworld.web 
	    (:use compojure.core [ring.adapter.jetty :only [run-jetty]] )
	    (:require [compojure.route :as route]
	              [compojure.handler :as handler]))

	(defn splash []
        {:status 200
    	:headers {"Content-Type" "text/plain"}
		:body "clojure-ring\n"})

	(defroutes main-routes
	  ; what's going on
	  	(GET "/" [] (splash))
	    (route/resources "/")
	    (route/not-found "Page not found")   )


	(def app
	    (handler/api main-routes))
	       
	(defn -main []
            (def port (get (System/getenv) "PORT" 5000))
	    (run-jetty app {:port (Integer. port)}))
