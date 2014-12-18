
source "$(dirname $BASH_SOURCE)/../runner.sh"

test-x-app-python-django() {
	run-app-test python-django "python-django"
}
