
declare selected_path
declare selected_name

buildpack-build() {
	declare desc="Build an application using installed buildpacks"
	ensure-paths
	buildpack-setup > /dev/null
	# use "process substitution" so buildpack-select can set variables in this shell
	buildpack-select > >(indent)
	buildpack-compile | indent
	procfile-types | indent
}

buildpack-install() {
	declare desc="Install buildpack from Git URL and optional committish"
	declare url="$1" commit="$2" name="${3:-$(basename $1)}"
	ensure-paths
	local target_path="$buildpack_path/$name"
	if [[ -n "$commit" ]]; then
		git clone "$url" "$target_path"
		cd "$target_path"
		git checkout --quiet "$commit"
		cd - > /dev/null
	else
		git clone --depth=1 "$url" "$target_path"
	fi
	rm -rf "$target_path/.git"
}

buildpack-list() {
	declare desc="List installed buildpacks"
	ls -1 "$buildpack_path"
}

buildpack-setup() {
	# Buildpack expectations
	export APP_DIR="$app_path"
	export HOME="$app_path"
	export REQUEST_ID="build-$RANDOM"
	export STACK="cedar-14"
	cp -r "$app_path/." "$build_path"
	
	# Dropped privileges
	usermod --home $HOME nobody
	chown -R nobody:nogroup \
		"$app_path" \
		"$build_path" \
		"$cache_path"

	# Useful settings / features
	export CURL_CONNECT_TIMEOUT="30"

	# Buildstep backwards compatibility
	if [[ -f "$app_path/.env" ]]; then
		source "$app_path/.env"
	fi
}

buildpack-select() {
	if [[ -n "$BUILDPACK_URL" ]]; then
		title "Fetching custom buildpack"
		
		selected_path="$buildpack_path/custom"
		rm -rf "$selected_path"

		IFS='#' read url commit <<< "$BUILDPACK_URL"
		buildpack-install "$url" "$commit" custom &> /dev/null

		selected_name="$(unprivileged $selected_path/bin/detect $build_path)"
	else
		# force heroku-buildpack-multi to detect first if exists
		if ls "$buildpack_path/heroku-buildpack-multi" > /dev/null 2>&1; then
			selected_name="$(unprivileged $buildpack_path/heroku-buildpack-multi/bin/detect $build_path)" \
				&& selected_path="$buildpack_path/heroku-buildpack-multi" \
				&& return
		fi
		local buildpacks=($buildpack_path/*)
		for buildpack in "${buildpacks[@]}"; do
			selected_name="$(unprivileged $buildpack/bin/detect $build_path)" \
				&& selected_path="$buildpack" \
				&& break
		done
	fi
	if [[ -n "$selected_path" ]]; then
		title "$selected_name app detected"
	else
		title "Unable to select a buildpack"
		exit 1
	fi
}

buildpack-compile() {
	# TODO: test if this is necessary or if we can always pass $env_path without issue
	if [[ "$(ls -A $env_path)" ]]; then
		unprivileged "$selected_path/bin/compile" "$build_path" "$cache_path" "$env_path"
	else
		unprivileged "$selected_path/bin/compile" "$build_path" "$cache_path"
	fi
	unprivileged "$selected_path/bin/release" "$build_path" "$cache_path" > "$build_path/.release"
}