
source "$(dirname $BASH_SOURCE)/../runner.sh"

test-z0-app-ruby-sinatra() {
	run-app-test ruby-sinatra "ruby-sinatra"
}
