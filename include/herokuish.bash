
if [[ "${BASH_VERSINFO[0]}" -lt "4" ]]; then
	echo "!! Your system Bash is out of date: $BASH_VERSION"
	echo "!! Please upgrade to Bash 4 or greater."
	exit 2
fi

readonly app_path="${APP_PATH:-/app}"
readonly env_path="${ENV_PATH:-/tmp/env}"
readonly build_path="${BUILD_PATH:-/tmp/build}"
readonly cache_path="${CACHE_PATH:-/tmp/cache}"
readonly import_path="${IMPORT_PATH:-/tmp/app}"
readonly buildpack_path="${BUILDPACK_PATH:-/tmp/buildpacks}"

declare unprivileged_user="$USER"
declare unprivileged_group="${USER/nobody/nogroup}"

export PS1='\[\033[01;34m\]\w\[\033[00m\] \[\033[01;32m\]$ \[\033[00m\]'

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
		"IMPORT_PATH=$import_path" 	"Mounted path to copy to app path" \
		"BUILDPACK_PATH=$buildpack_path" "Path to installed buildpacks"
}

version() {
	declare desc="Show version and supported version info"
	echo "herokuish: ${HEROKUISH_VERSION:-dev}"
	echo "buildpacks:"
	asset-cat include/buildpacks.txt | sed -e 's/.*heroku\///' -e 's/.*dokku\///' | xargs printf "  %-26s %s\n"
}

title() {
	echo $'\e[1G----->' "$@"
}

indent() {
	while read -r line; do
		if [[ "$line" == --* ]] || [[ "$line" == ==* ]]; then
			# shellcheck disable=SC2086
			echo $'\e[1G'$line
		else
			echo $'\e[1G      ' "$line"
		fi
	done
}

unprivileged() {
	setuidgid "$unprivileged_user" "$@"
}

detect-unprivileged() {
	unprivileged_user="$(stat -c %U "$app_path")"
	unprivileged_group="${unprivileged_user/nobody/nogroup}"
}

randomize-unprivileged() {
	local userid="$((RANDOM+1000))"
	local username="u${userid}"

	addgroup --quiet --gid "$userid" "$username"
	adduser \
		--shell /bin/bash \
		--disabled-password \
		--force-badname \
		--no-create-home \
		--uid "$userid" \
		--gid "$userid" \
		--gecos '' \
		--quiet \
		--home "$app_path" \
		"$username"

	unprivileged_user="$username"
	unprivileged_group="$username"
}

herokuish-test() {
	declare desc="Test running an app through Herokuish"
	declare path="${1:-/}" expected="$2"
	PORT=$(awk 'BEGIN{ srand();print int(rand()*(15600-1000))+1000 }')
	export PORT
	echo "::: BUILDING APP :::"
	buildpack-build
	echo "::: STARTING WEB :::"
	procfile-start web &
	for retry in $(seq 1 30); do
		sleep 1
		if ! nc -z -w 5 localhost "$PORT"; then
			echo "::: RETRYING LISTENER ($retry) :::"
		else
			echo "::: FOUND LISTENER :::" && break
		fi
	done
	echo "::: CHECKING APP :::"
	local output
	output="$(curl --fail --retry 10 --retry-delay 2 -v -s "localhost:${PORT}${path}")"
	if [[ "$expected" ]]; then
		sleep 1
		echo "::: APP OUTPUT :::"
		echo -e "$output"
		if [[ "$output" != "$expected" ]]; then
			echo "::: TEST FAILED :::"
			exit 2
		fi
	fi
	echo "::: TEST FINISHED :::"
}

main() {
	set -eo pipefail; [[ "$TRACE" ]] && set -x

	if [[ -d "$import_path" ]] && [[ -n "$(ls -A "$import_path")" ]]; then
		rm -rf "$app_path" && cp -r "$import_path" "$app_path"
	fi

	cmd-export paths
	cmd-export version
	cmd-export herokuish-test test

	cmd-export-ns buildpack "Use and install buildpacks"
	cmd-export buildpack-build
	cmd-export buildpack-install
	cmd-export buildpack-list
	cmd-export buildpack-test

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
