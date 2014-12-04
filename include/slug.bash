
readonly slug_path="/tmp/slug.tgz"

slug-import() {
	declare desc="Import a gzipped slug tarball from URL or STDIN "
	declare url="$1"
	if [[ "$(ls -A $app_path)" ]]; then
		return 1
	elif [[ "$url" ]]; then
		curl -s -o /dev/null --retry 2 "$src" | tar -xzC "$app_path"
	else
		cat | tar -xzC "$app_path"
	fi
}

slug-generate() {
	declare desc="Generate a gzipped slug tarball from the current app"
	local pigz_option
	if which pigz > /dev/null; then
		pigz_option="--use-compress-program=pigz"
	fi
	local slugignore_option
	if [[ -f "$build_path/.slugignore" ]]; then
		slugignore_option="-X $build_path/.slugignore"
	fi
	tar $pigz_option $slugignore_option \
		--exclude='.git' \
		-C "$build_path" \
		-cf "$slug_path" \
    	.
	local slug_size="$(du -Sh $slug_path | cut -f1)"
	title "Compiled slug size is $slug_size"
}

slug-export() {
	declare desc="Export generated slug tarball to URL (PUT) or STDOUT"
	declare url="$1"
	if [[ ! -f "$slug_path" ]]; then
		return 1
	fi
	if [[ "$url" ]]; then
		curl -0 -s -o /dev/null --retry 2 -X PUT -T "$slug_path" "$url"
	else
		cat "$slug_path"
	fi
}