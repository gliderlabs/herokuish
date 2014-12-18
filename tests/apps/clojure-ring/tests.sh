
source "$(dirname $BASH_SOURCE)/../runner.sh"

test-z3-app-clojure-ring() {
	run-app-test clojure-ring "clojure-ring"
}
