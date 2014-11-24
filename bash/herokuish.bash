
if [[ "$BASH_VERSINFO" -lt "4" ]]; then
	echo "!! Your system Bash is out of date: $BASH_VERSION"
	echo "!! Please upgrade to Bash 4 or greater."
	exit 2
fi

readonly app_path="${APP_PATH:-/app}"
readonly env_path="${ENV_PATH:-/tmp/env}"
readonly build_path="${BUILD_PATH:-/tmp/build}"
readonly cache_path="${CACHE_PATH:-/tmp/cache}"
readonly buildpack_path="${BUILDPACK_PATH:-/tmp/buildpacks}"

ensure-paths() {
	mkdir -p \
		"$app_path" \
		"$env_path" \
		"$build_path" \
		"$cache_path" \
		"$buildpack_path"
}

paths() {
	declare desc="Shows path settings"
	echo "APP_PATH=$app_path"
	echo "ENV_PATH=$env_path"
	echo "BUILD_PATH=$build_path"
	echo "CACHE_PATH=$cache_path"
	echo "BUILDPACK_PATH=$buildpack_path"
}

version() {
	declare desc="todo: show version and supported version info"
}

title() {
	echo $'\e[1G----->' $*
}

indent() {
	while read line; do
		if [[ "$line" == --* ]]; then
			echo $'\e[1G'$line
		else
			echo $'\e[1G      ' "$line"
		fi
	done
}

unprivileged() {
	setuidgid nobody $@
}

main() {
	set -eo pipefail; [[ "$TRACE" ]] && set -x

	cmd-export paths
	cmd-export version

	cmd-export-ns buildpack "Use and install buildpacks"
	cmd-export buildpack-build
	cmd-export buildpack-install
	cmd-export buildpack-list

	cmd-export-ns slug "Manage application slugs"
	cmd-export slug-import
	cmd-export slug-generate
	cmd-export slug-export

	cmd-export-ns procfile "Parse and execute Procfiles"
	cmd-export procfile-start
	cmd-export procfile-exec
	cmd-export procfile-parse
	
	cmd-ns "" "$@"
}