
source "$(dirname $BASH_SOURCE)/../runner.sh"

test-x-app-java-jetty() {
	run-app-test java-jetty "java-jetty"
}
