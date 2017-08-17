(ns helloworld.web-test
  (:require [clojure.test :refer :all]
            [ring.mock.request :as mock]
            [helloworld.web :refer :all]))

(deftest test-app
  (testing "main route"
    (let [response (app (mock/request :get "/"))]
      (is (= (:status response) 200))
      (is (= (:body response) "clojure-ring\n"))))

  (testing "not-found route"
    (let [response (app (mock/request :get "/invalid"))]
      (is (= (:status response) 404)))))
