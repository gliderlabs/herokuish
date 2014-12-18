
declare cedarish_version="v2"
declare cedarish_image="progrium/cedarish"

check-cedarish() {
	docker images | grep "$cedarish_image" | grep "$cedarish_version" > /dev/null
}

download-cedarish() {
	local version image
	version="$(docker version | head -1 | cut -d' ' -f 3)"
	# CircleCI is running a fork of Docker 1.2
	if [[ "${version:0:3}" == "1.2" ]]; then
		image="$cedarish_image $cedarish_version"
	else
		image="$cedarish_image:$cedarish_version"
	fi
	docker import \
		"https://github.com/progrium/cedarish/releases/download/$cedarish_version/cedarish-cedar14_$cedarish_version.tar.gz" \
		$image
	echo
}