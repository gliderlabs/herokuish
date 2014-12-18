
source "$(dirname $BASH_SOURCE)/../runner.sh"

test-x-app-go() {
	run-app-test go "go"
}
