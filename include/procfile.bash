
procfile-parse() {
	declare desc="Get command string for a process type from Procfile"
	declare type="$1"
	cat "$app_path/Procfile" | yaml-get "$type"
}

procfile-start() {
	declare desc="Run process type command from Procfile through exec"
	declare type="$1"
	procfile-exec "$(procfile-parse "$type")"
}

procfile-exec() {
	declare desc="Run as unprivileged user with Heroku-like env"
	[[ "$USER" ]] || detect-unprivileged
	procfile-setup-home
	procfile-load-env
	procfile-load-profile
	cd "$app_path"
	unprivileged /bin/bash -c "$(eval echo $@)"
}

procfile-types() {
	title "Discovering process types"
	if [[ -f "$app_path/Procfile" ]]; then
		local types
		types="$(cat $app_path/Procfile | yaml-keys | xargs echo)"
		echo "Procfile declares types -> ${types// /, }"
		return
	fi
	if [[ -s "$app_path/.release" ]]; then
		local default_types
		default_types="$(cat $app_path/.release | yaml-keys default_process_types | xargs echo)"
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
	shopt -u nullglob
	hash -r
}

procfile-setup-home() {
	export HOME="$app_path"
	usermod --home "$app_path" "$unprivileged_user" > /dev/null 2>&1
	chown -R "$unprivileged_user:$unprivileged_group" "$app_path"
}
