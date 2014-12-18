
source "$(dirname $BASH_SOURCE)/../runner.sh"

test-z3-app-scala() {
	run-app-test scala "scala"
}
