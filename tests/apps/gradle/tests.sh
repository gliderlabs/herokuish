
source "$(dirname $BASH_SOURCE)/../runner.sh"

test-x-app-gradle() {
	run-app-test gradle "gradle"
}
