
source "$(dirname $BASH_SOURCE)/../runner.sh"

test-z1-app-python-flask() {
	run-app-test python-flask "python-flask"
}
