
source "$(dirname $BASH_SOURCE)/../runner.sh"

test-z1-app-python-django() {
	run-app-test python-django "python-django"
}
