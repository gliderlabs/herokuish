
procfile-parse() {
	declare desc="Get command string for a process type from Procfile"
	declare type="$1"
	cat "$app_path/Procfile" | yaml-get "$type"
}

procfile-start() {
	declare desc="Run process type command from Procfile through exec"
	declare type="$1"
	procfile-exec $(procfile-parse "$type")
}

procfile-exec() {
	declare desc="Run as random, unprivileged user with Heroku-like env"
	procfile-randomize-user
	procfile-set-home
	procfile-load-env
	procfile-load-profile
	unprivileged $@
}

procfile-types() {
	title "Discovering process types"
	if [[ -f "$build_path/Procfile" ]]; then
		local types
		types="$(cat $build_path/Procfile | yaml-keys | xargs echo)"
		echo "Procfile declares types -> ${types// /, }"
		return
	fi
	if [[ -s "$build_path/.release" ]]; then
		local default_types
		default_types="$(cat $build_path/.release | yaml-keys default_process_types | xargs echo)"
		[[ "$default_types" ]] && \
			echo "Default process types for $selected_name -> ${default_types// /, }"
		return
	fi
	echo "No process types found"
}

procfile-load-env() {
	if [[ -d "$env_path" ]]; then
		for e in $(ls $env_path); do
			export "$e=$(cat $env_path/$e)"
		done
	fi
}

procfile-load-profile() {
	shopt -s nullglob
	mkdir -p "$app_path/.profile.d"
	for file in $app_path/.profile.d/*.sh; do
		source "$file"
	done
	hash -r
}

procfile-set-home() {
	export HOME="$app_path"
	usermod --home "$app_path" "$unprivileged_user"
	chown -R "$unprivileged_user:$unprivileged_group" "$app_path"
}

procfile-randomize-user() {
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