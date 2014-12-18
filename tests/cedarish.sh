
readonly cedarish_version="v2"
readonly cedarish_image="progrium/cedarish"

check-cedarish() {
	docker images | grep "$cedarish_image" | grep "$cedarish_version" > /dev/null
}

download-cedarish() {
	local version imagetag
	version="$(docker version | head -1 | cut -d' ' -f 3)"
	# CircleCI is running a fork of Docker 1.2
	if [[ "${version:0:3}" == "1.2" ]]; then
		imagetag="$cedarish_image $cedarish_version"
	else
		imagetag="$cedarish_image:$cedarish_version"
	fi
	docker import \
		"https://github.com/progrium/cedarish/releases/download/$cedarish_version/cedarish-cedar14_$cedarish_version.tar.gz" \
		$imagetag
	echo
}