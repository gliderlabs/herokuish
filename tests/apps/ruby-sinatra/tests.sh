
source "$(dirname $BASH_SOURCE)/../helper.sh"

test-x-app-ruby-sinatra() {
	run-app-test ruby-sinatra "ruby-sinatra"
}
