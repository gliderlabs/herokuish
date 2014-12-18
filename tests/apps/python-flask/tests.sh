
source "$(dirname $BASH_SOURCE)/../runner.sh"

test-x-app-python-flask() {
	run-app-test python-flask "python-flask"
}
