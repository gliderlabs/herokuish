
source "$(dirname $BASH_SOURCE)/../runner.sh"

test-z3-app-java-jetty() {
	run-app-test java-jetty "java-jetty"
}
