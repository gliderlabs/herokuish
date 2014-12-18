
source "$(dirname $BASH_SOURCE)/../runner.sh"

test-z0-app-nodejs-express() {
	run-app-test nodejs-express "nodejs-express"
}
