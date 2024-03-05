
yaml-esque-keys() {
	declare desc="Get process type keys from colon-separated structure"
	while read -r line || [[ -n "$line" ]]; do
		[[ "$line" =~ ^#.* ]] && continue
		[[ "$line" == *:* ]] || continue
		key=${line%%:*}
		echo "$key"
	done <<< "$(cat)"
}

yaml-esque-get() {
	declare desc="Get key value from colon-separated structure"
	declare key="$1"
	local inputkey cmd
	while read -r line || [[ -n "$line" ]]; do
		[[ "$line" =~ ^#.* ]] && continue
		inputkey=${line%%:*}
		cmd=${line#*:}
		if [[ "$inputkey" == "$key" ]]; then
			echo "$cmd"
			break
		fi
	done <<< "$(cat)"
}

procfile-parse() {
	declare desc="Get command string for a process type from Procfile"
	declare type="$1"
	# app_path is defined in outer scope
	# shellcheck disable=SC2154
	cat "$app_path/Procfile" | yaml-esque-get "$type"
}

procfile-start() {
	declare desc="Run process type command from Procfile through exec"
	declare type="$1"
	local processcmd
	processcmd="$(procfile-parse "$type")"
	if [[ -z "$processcmd" ]]; then
		echo "Proc entrypoint ${type} does not exist. Please check your Procfile"
		exit 1
	else
		procfile-exec "$processcmd"
	fi
}

procfile-exec() {
	declare desc="Run as unprivileged user with Heroku-like env"
	[[ "$USER" ]] || detect-unprivileged
	procfile-setup-home
	cd "$app_path" || return 1
	procfile-load-env
	procfile-load-profile
	# unprivileged_user is defined in outer scope
	# shellcheck disable=SC2154,SC2046
	if [[ "$HEROKUISH_SETUIDGUID" == "false" ]]; then
		exec $(eval echo "$@")
	else
		exec setuidgid "$unprivileged_user" $(eval echo "$@")
	fi
}

procfile-types() {
	title "Discovering process types"
	if [[ -f "$app_path/Procfile" ]]; then
		local types
		types="$(cat "$app_path/Procfile" | yaml-esque-keys | sort | uniq | xargs echo)"
		echo "Procfile declares types -> ${types// /, }"
		return
	fi
	if [[ -s "$app_path/.release" ]]; then
		local default_types
		default_types="$(cat "$app_path/.release" | yaml-keys default_process_types | xargs echo)"
		# selected_name is defined in outer scope
		# shellcheck disable=SC2154
		[[ "$default_types" ]] && \
			echo "Default types for $selected_name -> ${default_types// /, }"
		for type in $default_types; do
			echo "$type: $(cat "$app_path/.release" | yaml-get default_process_types "$type")" >> "$app_path/Procfile"
		done
		return
	fi
	echo "No process types found"
}

procfile-load-env() {
	local varname
	# env_path is defined in outer scope
	# shellcheck disable=SC2154
	if [[ -d "$env_path" ]]; then
		shopt -s nullglob
		for e in $env_path/*; do
			varname=$(basename "$e")
			export "$varname=$(cat "$e")"
		done
	fi
}

procfile-load-profile() {
	shopt -s nullglob
	for file in /etc/profile.d/*.sh; do
		# shellcheck disable=SC1090
		source "$file"
	done
	mkdir -p "$app_path/.profile.d"
	for file in $app_path/.profile.d/*.sh; do
		# shellcheck disable=SC1090
		source "$file"
	done
	if [[ -s "$app_path/.profile" ]]; then
		# shellcheck disable=SC1090
		source "$app_path/.profile"
	fi
	shopt -u nullglob
	hash -r
}

procfile-setup-home() {
	export HOME="$app_path"
	usermod --home "$app_path" "$unprivileged_user" >/dev/null 2>&1
	if [[ "$HEROKUISH_DISABLE_CHOWN" == "true" ]]; then
		# unprivileged_user & unprivileged_group are defined in outer scope
		# shellcheck disable=SC2154
		find "$app_path" \( \! -user "$unprivileged_user" -o \! -group "$unprivileged_group" \) -print0 | xargs -0 -r chown "$unprivileged_user:$unprivileged_group"
	fi
}
