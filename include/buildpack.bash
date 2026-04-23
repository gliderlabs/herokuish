_envfile-parse() {
  declare desc="Parse input into shell export commands"
  local key
  local value
  while read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^#.* ]] && continue
    [[ "$line" =~ ^$ ]] && continue
    key=${line%%=*}
    key=${key#*export }
    value="${line#*=}"
    case "$value" in
      \'* | \"*)
        # shellcheck disable=SC2269
        value="${value}"
        ;;
      *)
        value=\""${value}"\"
        ;;
    esac
    echo "export ${key}=${value}"
  done <<<"$(cat)"
}

_move-build-to-app() {
  shopt -s dotglob nullglob
  # shellcheck disable=SC2086
  rm -rf ${app_path:?}/*
  #  build_path defined in outer scope
  # shellcheck disable=SC2086,SC2154
  mv $build_path/* $app_path
  shopt -u dotglob nullglob
}

_select-buildpack() {
  # Issue #554: if .buildpacks declares exactly one buildpack, treat it as
  # BUILDPACK_URL. Bypasses heroku-buildpack-multi (and its misleading
  # "Multiple default buildpacks reported" warning) when the user has only
  # declared a single buildpack — there is nothing "multi" about that case.
  # A caller-provided BUILDPACK_URL always wins.
  # shellcheck disable=SC2154
  if [[ -z "$BUILDPACK_URL" ]] && [[ -f "$build_path/.buildpacks" ]]; then
    local -a _dotbuildpacks_urls=()
    local _dotbuildpacks_line
    while IFS= read -r _dotbuildpacks_line || [[ -n "$_dotbuildpacks_line" ]]; do
      _dotbuildpacks_line="${_dotbuildpacks_line%$'\r'}"
      _dotbuildpacks_line="${_dotbuildpacks_line#"${_dotbuildpacks_line%%[![:space:]]*}"}"
      _dotbuildpacks_line="${_dotbuildpacks_line%"${_dotbuildpacks_line##*[![:space:]]}"}"
      [[ -z "$_dotbuildpacks_line" ]] && continue
      [[ "${_dotbuildpacks_line:0:1}" == "#" ]] && continue
      _dotbuildpacks_urls+=("$_dotbuildpacks_line")
    done <"$build_path/.buildpacks"

    if [[ "${#_dotbuildpacks_urls[@]}" -eq 1 ]]; then
      BUILDPACK_URL="${_dotbuildpacks_urls[0]}"
    fi
  fi

  if [[ -n "$BUILDPACK_URL" ]]; then
    # Compute display name: shorthand for GitHub, full URL otherwise
    local display_name="$BUILDPACK_URL"
    if [[ "$display_name" == https://github.com/* ]]; then
      display_name="${display_name#https://github.com/}"
      display_name="${display_name/.git/}"
    elif [[ "$display_name" == git@github.com:* ]]; then
      display_name="${display_name#git@github.com:}"
      display_name="${display_name/.git/}"
    fi
    title "Fetching custom buildpack $display_name"
    # buildpack_path defined in outer scope
    # shellcheck disable=SC2154
    selected_path="$buildpack_path/custom"
    rm -rf "$selected_path"

    IFS='#' read -r url commit <<<"$BUILDPACK_URL"
    if ! buildpack-install "$url" "$commit" custom; then
      title "Unable to fetch custom buildpack from $url"
      exit 1
    fi
    # unprivileged_user & unprivileged_group defined in outer scope
    # shellcheck disable=SC2154
    chown -R "$unprivileged_user:$unprivileged_group" "$buildpack_path/custom"
    selected_name="$(unprivileged "$selected_path/bin/detect" "$build_path" || true)"
  else
    # shellcheck disable=SC2206
    local buildpacks=($buildpack_path/*)
    local valid_buildpacks=()
    for buildpack in "${buildpacks[@]}"; do
      unprivileged "$buildpack/bin/detect" "$build_path" &>/dev/null && valid_buildpacks+=("$buildpack")
    done
    if [[ ${#valid_buildpacks[@]} -gt 1 ]]; then
      title "Warning: Multiple default buildpacks reported the ability to handle this app. The first buildpack in the list below will be used."
      # shellcheck disable=SC2001
      echo "Detected buildpacks: $(sed -e "s:/tmp/buildpacks/[0-9][0-9]_buildpack-::g" <<<"${valid_buildpacks[@]}")" | indent
    fi
    if [[ ${#valid_buildpacks[@]} -gt 0 ]]; then
      selected_path="${valid_buildpacks[0]}"
      selected_name=$(unprivileged "$selected_path/bin/detect" "$build_path")
    fi
  fi
  if [[ "$selected_path" ]] && [[ "$selected_name" ]]; then
    title "$selected_name app detected"
  else
    title "Unable to select a buildpack"
    exit 1
  fi
}

buildpack-detect() {
  declare desc="Detect suitable buildpack for an application"
  ensure-paths
  [[ "$USER" ]] || randomize-unprivileged
  if [[ -n "$HEROKUISH_WITH_TTY" ]]; then
    usermod -aG tty "$unprivileged_user" 2>/dev/null || true
  fi
  buildpack-setup >/dev/null
  _select-buildpack
}

buildpack-build() {
  declare desc="Build an application using installed buildpacks"
  ensure-paths
  [[ "$USER" ]] || randomize-unprivileged
  if [[ -n "$HEROKUISH_WITH_TTY" ]]; then
    usermod -aG tty "$unprivileged_user" 2>/dev/null || true
  fi
  buildpack-setup >/dev/null
  buildpack-execute | indent
  procfile-types | indent
}

buildpack-install() {
  declare desc="Install buildpack from Git URL and optional committish"
  declare url="$1" commit="$2" name="$3"
  ensure-paths
  if [[ ! "$url" ]]; then
    asset-cat include/buildpacks.txt | while read -r name url commit; do
      buildpack-install "$url" "$commit" "$name"
    done
    return
  fi

  # Reject obviously invalid input up-front so failures surface with a clear
  # message instead of a silent empty install. Accept common git/http/ssh/file
  # URL shapes, git scp-style addresses, and existing local directories.
  if [[ ! -d "$url" ]] \
    && [[ ! "$url" =~ ^(https?|git|ssh|file)://.+ ]] \
    && [[ ! "$url" =~ ^[A-Za-z0-9_.-]+@[A-Za-z0-9_.-]+:.+ ]]; then
    echo "!     Invalid buildpack URL: '$url'" >&2
    echo "!     Expected a git remote (https://, git://, ssh://, git@host:path) or a tarball URL (http(s)://...tar.gz|tgz|tar.bz|tbz|tar)." >&2
    return 1
  fi

  # pipefail ensures the curl|tar pipeline below surfaces either side's
  # failure. `local -` scopes the shell option change to this function.
  local -
  set -o pipefail

  # buildpack_path is defined in outer scope
  # shellcheck disable=SC2154
  local target_path="$buildpack_path/${name:-$(basename "$url")}"
  if git ls-remote "$url" &>/dev/null; then
    if [[ "$commit" ]]; then
      if ! git clone --branch "$commit" --quiet --depth 1 "$url" "$target_path" &>/dev/null; then
        # if the shallow clone failed partway through, clean up and try a full clone
        rm -rf "$target_path"
        if ! git clone "$url" "$target_path"; then
          echo "!     Failed to clone buildpack from '$url'" >&2
          rm -rf "$target_path"
          return 1
        fi
        cd "$target_path" || return 1
        if ! git checkout --quiet "$commit"; then
          echo "!     Failed to checkout '$commit' from '$url'" >&2
          cd - >/dev/null || true
          rm -rf "$target_path"
          return 1
        fi
        cd - >/dev/null || return 1
      else
        echo "Cloning into '$target_path'..."
      fi
    else
      if ! git clone --depth=1 "$url" "$target_path"; then
        echo "!     Failed to clone buildpack from '$url'" >&2
        rm -rf "$target_path"
        return 1
      fi
    fi
  else
    local tar_args
    case "$url" in
      *.tgz | *.tar.gz)
        target_path="${target_path//.tgz/}"
        target_path="${target_path//.tar.gz/}"
        tar_args="-xzC"
        ;;
      *.tbz | *.tar.bz)
        target_path="${target_path//.tbz/}"
        target_path="${target_path//.tar.bz/}"
        tar_args="-xjC"
        ;;
      *.tar)
        target_path="${target_path//.tar/}"
        tar_args="-xC"
        ;;
      *)
        echo "!     Buildpack URL is not a reachable git remote or a recognised archive: '$url'" >&2
        echo "!     Supported archive extensions: .tgz, .tar.gz, .tbz, .tar.bz, .tar" >&2
        return 1
        ;;
    esac
    echo "Downloading '$url' into '$target_path'..."
    mkdir -p "$target_path"
    if ! curl --fail --silent --show-error --location --retry 2 "$url" | tar "$tar_args" "$target_path"; then
      echo "!     Failed to download buildpack from '$url'" >&2
      rm -rf "$target_path"
      return 1
    fi
    chown -R root:root "$target_path"
    chmod 755 "$target_path"
  fi

  find "$buildpack_path" \( \! -user "${unprivileged_user:-32767}" -o \! -group "${unprivileged_group:-32767}" \) -print0 | xargs -P 0 -0 --no-run-if-empty chown --no-dereference "${unprivileged_user:-32767}:${unprivileged_group:-32767}"
}

buildpack-list() {
  declare desc="List installed buildpacks"
  ensure-paths
  ls -1 "$buildpack_path"
}

buildpack-setup() {
  # $import_path is defined in outer scope
  # shellcheck disable=SC2154
  if [[ -d "$import_path" ]] && [[ -n "$(ls -A "$import_path")" ]]; then
    rm -rf "$app_path" && cp -r "$import_path" "$app_path"
  fi

  # Buildpack expectations
  # app_path defined in outer scope
  # shellcheck disable=SC2154
  export APP_DIR="$app_path"
  # shellcheck disable=SC2154
  export HOME="$app_path"
  export REQUEST_ID="build-$RANDOM"
  export STACK="${STACK:-heroku-24}"
  # build_path defined in outer scope
  # shellcheck disable=SC2154
  cp -r "$app_path/." "$build_path"

  # Prepare dropped privileges
  # unprivileged_user defined in outer scope
  # shellcheck disable=SC2154
  usermod --home "$HOME" "$unprivileged_user" >/dev/null 2>&1

  # shellcheck disable=SC2154
  chown "$unprivileged_user:$unprivileged_group" "$HOME"

  # Prepare permissions quicker for slower filesystems
  # vars defined in outer scope
  # shellcheck disable=SC2154
  find "$app_path" \( \! -user "$unprivileged_user" -o \! -group "$unprivileged_group" \) -print0 | xargs -P 0 -0 --no-run-if-empty chown --no-dereference "$unprivileged_user:$unprivileged_group"
  # shellcheck disable=SC2154
  find "$build_path" \( \! -user "$unprivileged_user" -o \! -group "$unprivileged_group" \) -print0 | xargs -P 0 -0 --no-run-if-empty chown --no-dereference "$unprivileged_user:$unprivileged_group"
  # shellcheck disable=SC2154
  find "$cache_path" \( \! -user "$unprivileged_user" -o \! -group "$unprivileged_group" \) -print0 | xargs -P 0 -0 --no-run-if-empty chown --no-dereference "$unprivileged_user:$unprivileged_group"
  # shellcheck disable=SC2154
  find "$env_path" \( \! -user "$unprivileged_user" -o \! -group "$unprivileged_group" \) -print0 | xargs -P 0 -0 --no-run-if-empty chown --no-dereference "$unprivileged_user:$unprivileged_group"
  # shellcheck disable=SC2154
  find "$buildpack_path" \( \! -user "$unprivileged_user" -o \! -group "$unprivileged_group" \) -print0 | xargs -P 0 -0 --no-run-if-empty chown --no-dereference "$unprivileged_user:$unprivileged_group"

  # Useful settings / features
  export CURL_CONNECT_TIMEOUT="30"
  export CURL_TIMEOUT="180"

  # Buildstep backwards compatibility
  if [[ -f "$app_path/.env" ]]; then
    # shellcheck disable=SC2046
    eval $(cat "$app_path/.env" | _envfile-parse)
  fi
}

buildpack-execute() {
  _select-buildpack
  cd "$build_path" || return 1
  unprivileged "$selected_path/bin/compile" "$build_path" "$cache_path" "$env_path"
  if [[ -f "$selected_path/bin/release" ]]; then
    unprivileged "$selected_path/bin/release" "$build_path" "$cache_path" | unprivileged tee "$build_path/.release" >/dev/null
  fi
  if [[ -f "$build_path/.release" ]]; then
    config_vars="$(cat "$build_path/.release" | yaml-get config_vars)"
    unprivileged mkdir -p "$build_path/.profile.d"
    unprivileged touch "$build_path/.profile.d/00_config_vars.sh"
    if [[ "$config_vars" ]]; then
      mkdir -p "$build_path/.profile.d"
      chown "$unprivileged_user:$unprivileged_group" "$build_path/.profile.d"
      OIFS=$IFS
      IFS=$'\n'
      for var in $config_vars; do
        echo "export $(echo "$var" | sed -e 's/=/="/' -e 's/$/"/')" | unprivileged tee -a "$build_path/.profile.d/00_config_vars.sh" >/dev/null
      done
      IFS=$OIFS
    fi
  fi
  cd - >/dev/null || return 1
  _move-build-to-app
}

buildpack-test() {
  declare desc="Build and run tests for an application using installed buildpacks"
  ensure-paths
  [[ "$USER" ]] || randomize-unprivileged
  if [[ -n "$HEROKUISH_WITH_TTY" ]]; then
    usermod -aG tty "$unprivileged_user" 2>/dev/null || true
  fi
  buildpack-setup >/dev/null
  _select-buildpack

  if [[ ! -f "$selected_path/bin/test-compile" ]] || [[ ! -f "$selected_path/bin/test" ]]; then
    echo "Selected buildpack does not support test feature"
    exit 1
  fi

  cd "$build_path" || return 1
  chmod 755 "$selected_path/bin/test-compile"
  unprivileged "$selected_path/bin/test-compile" "$build_path" "$cache_path" "$env_path"

  cd "$app_path" || return 1
  _move-build-to-app
  procfile-load-profile
  chmod 755 "$selected_path/bin/test"
  unprivileged "$selected_path/bin/test" "$app_path" "$env_path"
}
