
herokuish-test() {
	declare name="$1" script="$2"
	# shellcheck disable=SC2046,SC2154
	docker run $([[ "$CI" ]] || echo "--rm") -v "$PWD:/mnt" \
		"herokuish:dev" bash -c "set -e; $script" \
		|| $T_fail "$name exited non-zero"
}

fn-source() {
	# use this if you want to write tests
	# in functions instead of strings.
	# see test-binary for trivial example
	# shellcheck disable=SC2086
	declare -f $1 | tail -n +2
}

function cleanup {
	echo "Tests cleanup"
	local procfile
	procfile="$(cd "$( dirname "${BASH_SOURCE[0]}")" && pwd )/Procfile"
	if [[ -f "$procfile" ]]; then
		rm -f "$procfile"
	fi
}

trap cleanup EXIT

T_binary() {
	_test-binary() {
		herokuish
	}
	herokuish-test "test-binary" "$(fn-source _test-binary)"
}

T_generate_slug() {
	herokuish-test "test-slug-generate" "
		herokuish slug generate
		tar tzf /tmp/slug.tgz"
}

T_default-user() {
	_test-user() {
		id herokuishuser
	}
	herokuish-test "test-user" "$(fn-source _test-user)"
}

T_invalid_proc_process() {
	local dir expected_err_msg err_msg
	dir="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
	echo "Creating Procfile"
	echo "web:" > "$dir/Procfile"
	expected_err_msg="Proc entrypoint invalid-proc does not exist. Please check your Procfile"
	# debug_flag is defined in outer scope
	# shellcheck disable=SC2046,SC2086,2154
	err_msg="$(docker run $([[ "$CI" ]] || echo "--rm") $debug_flag --env=USER=herokuishuser -v "$dir:/tmp/app" herokuish:dev /start invalid-proc)"

	if [[ $err_msg != "$expected_err_msg" ]]; then
		echo "procfile-start did not throw error for invalid procfile"
		exit 1
	fi
}
