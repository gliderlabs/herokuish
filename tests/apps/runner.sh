
run-app-test() {
	declare app="$1" expected="$2"
	[[ -x "$PWD/build/linux/herokuish" ]] || {
		echo "!! Tests need to be run from project root,"
		echo "!! and Linux build needs to exist."
		exit 127
	}
	time $PWD/tests/util/run-app $PWD/tests/apps/$app "$expected" \
		|| fail "Unable to build app or app output not: $expected"
}
