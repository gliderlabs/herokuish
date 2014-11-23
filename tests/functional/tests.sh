
cedarish-run() {
	[[ -x "$PWD/build/linux/herokuish" ]] || {
		echo "!! Tests need to be run from project root,"
		echo "!! and Linux build needs to exist."
		exit 127
	}
	declare -f $1 | tail -n +2 | docker run --rm -i -v "$PWD:/src" progrium/cedarish bash
}

testFoobar() {
	_testFoobar() {
		echo "test"
		sleep 2
		echo "done"
		exit
	}
	cedarish-run _testFoobar
}