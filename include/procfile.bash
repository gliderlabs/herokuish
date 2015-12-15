
yaml-esque-keys() {
	declare desc="Get process type keys from colon-separated structure"
	while read line || [[ -n "$line" ]]; do
		[[ -z "$line" ]] && continue
		[[ "$line" =~ ^#.* ]] && continue
		key=${line%%:*}
		echo $key
	done <<< "$(cat)"
}

yaml-esque-get() {
	declare desc="Get key value from colon-separated structure"
	declare key="$1"
	local inputkey
	local cmd
	while read line || [[ -n "$line" ]]; do
		[[ -z "$line" ]] && continue
		[[ "$line" =~ ^#.* ]] && continue
		inputkey=${line%%:*}
		cmd=${line#*:}
		[[ "$inputkey" == "$key" ]] && echo "$cmd"
	done <<< "$(cat)"
}

procfile-parse() {
	declare desc="Get command string for a process type from Procfile"
	declare type="$1"
	cat "$app_path/Procfile" | yaml-esque-get "$type"
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
	exec setuidgid "$unprivileged_user" $(eval echo $@)
}

procfile-types() {
	title "Discovering process types"
	if [[ -f "$app_path/Procfile" ]]; then
		local types
		types="$(cat $app_path/Procfile | yaml-esque-keys | xargs echo)"
		echo "Procfile declares types -> ${types// /, }"
		return
	fi
	if [[ -s "$app_path/.release" ]]; then
		local default_types
		default_types="$(cat $app_path/.release | yaml-keys default_process_types | xargs echo)"
		[[ "$default_types" ]] && \
			echo "Default types for $selected_name -> ${default_types// /, }"
		for type in $default_types; do
			echo "$type: $(cat $app_path/.release | yaml-get default_process_types $type)" >> "$app_path/Procfile"
		done
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
	for file in /etc/profile.d/*.sh; do
		source "$file"
	done
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
