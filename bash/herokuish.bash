
if [[ "$BASH_VERSINFO" -lt "4" ]]; then
	echo "!! Your system Bash is out of date: $BASH_VERSION"
	echo "!! Please upgrade to Bash 4 or greater."
	exit 2
fi

main() {
	set -eo pipefail; [[ "$TRACE" ]] && set -x
	export BASH_ENV=

	cmd-export-ns buildpack "Use and install buildpacks"
	cmd-export buildpack-build
	cmd-export buildpack-install

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