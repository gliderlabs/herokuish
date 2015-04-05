
buildpack-build() {
	declare desc="Build an application using installed buildpacks"
	ensure-paths
	[[ "$USER" ]] || randomize-unprivileged
	buildpack-setup > /dev/null
	buildpack-execute | indent
	procfile-types | indent
}

buildpack-install() {
	declare desc="Install buildpack from Git URL and optional committish"
	declare url="$1" commit="$2" name="$3"
	ensure-paths
	if [[ ! "$url" ]]; then
		asset-cat include/buildpacks.txt | while read url commit; do
			buildpack-install "$url" "$commit"
		done
		return
	fi
	local target_path="$buildpack_path/${name:-$(basename $url)}"
	if [[ "$commit" ]]; then
		if ! git clone --branch "$commit" --quiet --depth 1 "$url" "$target_path" &>/dev/null; then
			# if the shallow clone failed partway through, clean up and try a full clone
			rm -rf "$target_path"
			git clone "$url" "$target_path"
			cd "$target_path"
			git checkout --quiet "$commit"
			cd - > /dev/null
		else
			echo "Cloning into '$target_path'..."
		fi
	else
		git clone --depth=1 "$url" "$target_path"
	fi
	rm -rf "$target_path/.git"
}

buildpack-list() {
	declare desc="List installed buildpacks"
	ensure-paths
	ls -1 "$buildpack_path"
}

buildpack-setup() {
	# Buildpack expectations
	export APP_DIR="$app_path"
	export HOME="$app_path"
	export REQUEST_ID="build-$RANDOM"
	export STACK="cedar-14"
	cp -r "$app_path/." "$build_path"

	# Prepare dropped privileges
	usermod --home "$HOME" "$unprivileged_user" > /dev/null 2>&1
	chown -R "$unprivileged_user:$unprivileged_group" \
		"$app_path" \
		"$build_path" \
		"$cache_path" \
		"$buildpack_path"

	# Useful settings / features
	export CURL_CONNECT_TIMEOUT="30"

	# Buildstep backwards compatibility
	if [[ -f "$app_path/.env" ]]; then
		source "$app_path/.env"
	fi
}

buildpack-execute() {
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
				&& selected_path="$buildpack_path/heroku-buildpack-multi"
		fi
		if [[ ! "$selected_path" ]]; then
			local buildpacks=($buildpack_path/*)
			for buildpack in "${buildpacks[@]}"; do
				selected_name="$(unprivileged $buildpack/bin/detect $build_path)" \
					&& selected_path="$buildpack" \
					&& break
			done
		fi
	fi
	if [[ "$selected_path" ]]; then
		title "$selected_name app detected"
	else
		title "Unable to select a buildpack"
		exit 1
	fi

	cd "$build_path"
	unprivileged "$selected_path/bin/compile" "$build_path" "$cache_path" "$env_path"
	unprivileged "$selected_path/bin/release" "$build_path" "$cache_path" > "$build_path/.release"
	cd - > /dev/null

	shopt -s dotglob nullglob
	rm -rf $app_path/*
	mv $build_path/* $app_path
	shopt -u dotglob nullglob
}
