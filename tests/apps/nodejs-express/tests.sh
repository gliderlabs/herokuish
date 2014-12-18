
source "$(dirname $BASH_SOURCE)/../runner.sh"

test-x-app-nodejs-express() {
	run-app-test nodejs-express "nodejs-express"
}
