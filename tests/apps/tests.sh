
readonly herokuish_root="$(dirname $(dirname $(dirname $PWD/${BASH_SOURCE/\.\//})))"

run-app-test() {
	declare app="$1" expected="$2"
	$herokuish_root/tests/util/test-app $herokuish_root/tests/apps/$app "$expected" \
		|| fail "Unable to build app or app output not: $expected"
}
