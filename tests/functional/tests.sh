
herokuish-test() {
	declare name="$1" script="$2"
	docker run $([[ "$CI" ]] || echo "--rm") -v "$PWD:/mnt" \
		"herokuish:dev" bash -c "set -e; $script" \
		|| $T_fail "$name exited non-zero"
}

fn-source() {
	# use this if you want to write tests
	# in functions instead of strings.
	# see test-binary for trivial example
	declare -f $1 | tail -n +2
}

T_binary() {
	_test-binary() {
		herokuish
	}
	herokuish-test "test-binary" "$(fn-source _test-binary)"
}

T_slug-generate() {
	herokuish-test "test-slug-generate" "
		herokuish slug generate
		tar tzf /tmp/slug.tgz"
}
