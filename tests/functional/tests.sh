
source "$(dirname $BASH_SOURCE)/../cedarish.sh"

cedarish-run() {
	[[ -x "$PWD/build/linux/herokuish" ]] || {
		echo "!! Tests need to be run from project root,"
		echo "!! and Linux build needs to exist."
		exit 127
	}
	check-cedarish || import-cedarish
	declare -f $1 | tail -n +2 | docker run --rm -i -v "$PWD:/test" "$cedarish_image:$cedarish_version" bash
	assertTrue "$1 failed" "$?"
}

test-binary() {
	_testBinary() {
		/test/build/linux/herokuish
		exit
	}
	cedarish-run _testBinary
}

test-generate() {
	_testGenerate() {
		mkdir /app
		/test/build/linux/herokuish slug generate
		tar tzf /tmp/slug.tgz
		exit
	}
	cedarish-run _testGenerate
}