
source "$(dirname $BASH_SOURCE)/../runner.sh"

test-x-app-scala() {
	run-app-test scala "scala"
}
