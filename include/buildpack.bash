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
  if [[ -n "$BUILDPACK_URL" ]]; then
    title "Fetching custom buildpack"
    # buildpack_path defined in outer scope
    # shellcheck disable=SC2154
    selected_path="$buildpack_path/custom"
    rm -rf "$selected_path"

    IFS='#' read -r url commit <<<"$BUILDPACK_URL"
    buildpack-install "$url" "$commit" custom &>/dev/null
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

buildpack-build() {
  declare desc="Build an application using installed buildpacks"
  ensure-paths
  [[ "$USER" ]] || randomize-unprivileged
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
  # buildpack_path is defined in outer scope
  # shellcheck disable=SC2154
  local target_path="$buildpack_path/${name:-$(basename "$url")}"
  if [[ "$(
    git ls-remote "$url" &>/dev/null
    echo $?
  )" -eq 0 ]]; then
    if [[ "$commit" ]]; then
      if ! git clone --branch "$commit" --quiet --depth 1 "$url" "$target_path" &>/dev/null; then
        # if the shallow clone failed partway through, clean up and try a full clone
        rm -rf "$target_path"
        git clone "$url" "$target_path"
        cd "$target_path" || return 1
        git checkout --quiet "$commit"
        cd - >/dev/null || return 1
      else
        echo "Cloning into '$target_path'..."
      fi
    else
      git clone --depth=1 "$url" "$target_path"
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
    esac
    echo "Downloading '$url' into '$target_path'..."
    mkdir -p "$target_path"
    curl -s --retry 2 "$url" | tar "$tar_args" "$target_path"
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
