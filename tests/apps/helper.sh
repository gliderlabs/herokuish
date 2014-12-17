
run-app-test() {
	declare app="$1" expected="$2"
	local tests_root="$(dirname $(dirname $(dirname $PWD/${BASH_SOURCE/\.\//})))"
	$tests_root/util/test-app $tests_root/apps/$app "$expected" \
		|| fail "Unable to build app or app output not: $expected"
}
