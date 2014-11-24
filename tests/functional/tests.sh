
cedarish-run() {
	[[ -x "$PWD/build/linux/herokuish" ]] || {
		echo "!! Tests need to be run from project root,"
		echo "!! and Linux build needs to exist."
		exit 127
	}
	declare -f $1 | tail -n +2 | docker run --rm -i -v "$PWD:/test" progrium/cedarish bash
}

testBinary() {
	_testBinary() {
		/test/build/linux/herokuish
		exit
	}
	cedarish-run _testBinary
}