
procfile-start() {
	true
}

procfile-exec() {
	true
}

procfile-parse() {
	true
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