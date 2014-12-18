
source "$(dirname $BASH_SOURCE)/../runner.sh"

test-x-app-ruby-sinatra() {
	run-app-test ruby-sinatra "ruby-sinatra"
}
