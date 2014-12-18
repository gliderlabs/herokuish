
source "$(dirname $BASH_SOURCE)/../runner.sh"

test-z2-app-gradle() {
	run-app-test gradle "gradle"
}
