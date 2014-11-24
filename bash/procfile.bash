
procfile-start() {
	true
}

procfile-exec() {
	true
}

procfile-parse() {
	true
}

procfile-show-types() {
	# TODO: cleanup, use embedded go functions instead of ruby
	title "Discovering process types"
	if [[ -f "$build_path/Procfile" ]]; then
		types=$(ruby -e "require 'yaml';puts YAML.load_file('$build_path/Procfile').keys().join(', ')")
		echo "Procfile declares types -> $types"
	fi
	local default_types=""
	if [[ -s "$build_path/.release" ]]; then
		default_types=$(ruby -e "require 'yaml';puts (YAML.load_file('$build_path/.release')['default_process_types'] || {}).keys().join(', ')")
		[[ "$default_types" ]] && echo "Default process types for $selected_name -> $default_types"
	fi
}