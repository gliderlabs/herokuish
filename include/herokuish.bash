
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

readonly cedarish_version="v2"

declare unprivileged_user="nobody"
declare unprivileged_group="nogroup"

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
	printf "%-32s # %s\n" \
		"APP_PATH=$app_path" 		"Application path during runtime" \
		"ENV_PATH=$env_path" 		"Path to files for defining base environment" \
		"BUILD_PATH=$build_path" 	"Working directory during builds" \
		"CACHE_PATH=$cache_path" 	"Buildpack cache location" \
		"BUILDPACK_PATH=$buildpack_path" "Path to installed buildpacks"
}

version() {
	declare desc="Show version and supported version info"
	echo "herokuish version: ${VERSION:-dev}"
	echo "compatible cedarish: $cedarish_version"
	echo "compatible buildpacks:"
	asset-cat include/buildpacks.txt | sed 's/.*heroku\///' | xargs printf "  %-26s %s\n"
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
	setuidgid "$unprivileged_user" $@
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

	cmd-export-ns procfile "Use Procfiles and run app commands"
	cmd-export procfile-start
	cmd-export procfile-exec
	cmd-export procfile-parse
	
	case "$SELF" in 
		/start)		procfile-start "$@";;
		/exec)		procfile-exec "$@";;
		/build)		buildpack-build;;
		*)			cmd-ns "" "$@";
	esac
}