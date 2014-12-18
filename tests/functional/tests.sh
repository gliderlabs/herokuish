
source "$(dirname $BASH_SOURCE)/../cedarish.sh"

fn-source() {
	# use this if you want to write tests 
	# in functions instead of strings.
	# see test-binary for trivial example
	declare fn="$1"
	declare -f $fn | tail -n +2
}

run-cedarish() {
	declare name="$1" script="$2"
	[[ -x "$PWD/build/linux/herokuish" ]] || {
		echo "!! Tests need to be run from project root,"
		echo "!! and Linux build needs to exist."
		exit 127
	}
	check-cedarish || import-cedarish
	docker run $([[ "$CI" ]] || echo "--rm") -v "$PWD:/mnt" \
		"$cedarish_image:$cedarish_version" bash -c "$script" \
		|| fail "$name exited non-zero"
}

test-binary() {
	_test-binary() {
		/mnt/build/linux/herokuish
	}
	run-cedarish "test-binary" "$(fn-source _test-binary)"
}

test-generate() {
	run-cedarish "test-generate" "
		/mnt/build/linux/herokuish slug generate
		tar tzf /tmp/slug.tgz"
}