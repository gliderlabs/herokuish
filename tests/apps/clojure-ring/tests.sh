
source "$(dirname $BASH_SOURCE)/../runner.sh"

test-x-app-clojure-ring() {
	run-app-test clojure-ring "clojure-ring"
}
