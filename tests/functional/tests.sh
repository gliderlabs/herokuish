
source "$(dirname $BASH_SOURCE)/../cedarish.sh"

fn-source() {
	# use this if you want to write tests
	# in functions instead of strings.
	# see test-binary for trivial example
	declare -f $1 | tail -n +2
}

test-binary() {
	_test-binary() {
		herokuish
	}
	cedarish-test "test-binary" "$(fn-source _test-binary)"
}

test-slug-generate() {
	cedarish-test "test-slug-generate" "
		herokuish slug generate
		tar tzf /tmp/slug.tgz"
}
