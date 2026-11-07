#!/usr/bin/env bats
# shellcheck shell=bash

@test "envfile-parse" {
  # shellcheck disable=SC1091
  source "${BATS_TEST_DIRNAME}/../../include/buildpack.bash"
  local fixture_filename
  local foo_expected='Hello'$'\n'' '\''world'\'' '
  local bar_expected='te'\''st'
  local nested_foo_expected=foo
  local nested_bar_expected=foo

  fixture_filename="${BATS_TEST_DIRNAME}/fixtures/complicated_envfile"
  eval "$(_envfile-parse <"$fixture_filename")"

  # shellcheck disable=2154
  if [[ ! "$foo_expected" == "$foo" ]]; then
    echo "Expected foo = $foo_expected got: $foo"
    return 1
  fi

  # shellcheck disable=2154
  if [[ ! "$bar_expected" == "$bar" ]]; then
    echo "Expected bar = $bar_expected got: $bar"
    return 2
  fi

  # shellcheck disable=2154
  if [[ ! "$nested_foo_expected" == "$nested_foo" ]]; then
    echo "Expected nested_foo = $nested_foo_expected got: $nested_foo"
    return 3
  fi

  # shellcheck disable=2154
  if [[ ! "$nested_bar_expected" == "$nested_bar" ]]; then
    echo "Expected nested_bar = $nested_bar_expected got: $nested_bar"
    return 4
  fi
}

@test "buildpack-install-invalid-url" {
  # Regression test for gliderlabs/herokuish#553: a non-URL input like "ruby"
  # must fail up-front with an actionable error instead of silently installing
  # an empty buildpack directory.
  # shellcheck disable=SC1091
  source "${BATS_TEST_DIRNAME}/../../include/buildpack.bash"

  # Stub out ensure-paths and scope buildpack_path to a temp dir so the test
  # does not touch /tmp/buildpacks or require the outer scope vars.
  local tmpdir
  tmpdir="$(mktemp -d)"
  # shellcheck disable=SC2317
  ensure-paths() { :; }
  # shellcheck disable=SC2034
  local buildpack_path="$tmpdir"

  run buildpack-install "ruby" "" "custom"
  rm -rf "$tmpdir"

  [[ "$status" -ne 0 ]] || {
    echo "Expected non-zero exit code for invalid URL, got 0"
    echo "output: $output"
    return 1
  }
  [[ "$output" == *"Invalid buildpack URL: 'ruby'"* ]] || {
    echo "Expected 'Invalid buildpack URL' message, got: $output"
    return 2
  }
}

@test "buildpack-install-unrecognised-archive" {
  # An http(s) URL that is not a known archive extension and is not a reachable
  # git remote should fail with an explicit "not a recognised archive" error
  # rather than silently running tar with empty args.
  # shellcheck disable=SC1091
  source "${BATS_TEST_DIRNAME}/../../include/buildpack.bash"

  local tmpdir
  tmpdir="$(mktemp -d)"
  # shellcheck disable=SC2317
  ensure-paths() { :; }
  # shellcheck disable=SC2034
  local buildpack_path="$tmpdir"

  # Use a reserved-for-documentation host so git ls-remote definitely fails
  # and the tarball branch is reached without network access attempting real
  # downloads.
  run buildpack-install "https://example.invalid/not-an-archive" "" "custom"
  rm -rf "$tmpdir"

  [[ "$status" -ne 0 ]] || {
    echo "Expected non-zero exit code for unrecognised archive URL, got 0"
    echo "output: $output"
    return 1
  }
  [[ "$output" == *"not a reachable git remote or a recognised archive"* ]] || {
    echo "Expected 'not a reachable git remote or a recognised archive' message, got: $output"
    return 2
  }
}

# Helpers for the issue #554 _select-buildpack tests. Each test calls
# _select-buildpack-setup first to source buildpack.bash, scope buildpack_path
# and build_path to a tmpdir, stub outer-scope dependencies (title/indent/
# chown/unprivileged/buildpack-install), and set up a capture file at
# $_select_buildpack_install_args. The stubbed buildpack-install records its
# args and fabricates $buildpack_path/custom/bin/detect so the post-install
# detect step in _select-buildpack still produces a selected_name.
_select-buildpack-setup() {
  # shellcheck disable=SC1091
  source "${BATS_TEST_DIRNAME}/../../include/buildpack.bash"
  _select_buildpack_root="$(mktemp -d)"
  # shellcheck disable=SC2034
  buildpack_path="$_select_buildpack_root/buildpacks"
  # shellcheck disable=SC2034
  build_path="$_select_buildpack_root/build"
  mkdir -p "$buildpack_path" "$build_path"
  # shellcheck disable=SC2034
  unprivileged_user="$(id -un)"
  # shellcheck disable=SC2034
  unprivileged_group="$(id -gn)"
  _select_buildpack_install_args="$_select_buildpack_root/install-args"
  : >"$_select_buildpack_install_args"
  # shellcheck disable=SC2317
  title() { echo "-----> $*"; }
  # shellcheck disable=SC2317
  indent() { sed -e 's/^/       /'; }
  # shellcheck disable=SC2317
  chown() { :; }
  # shellcheck disable=SC2317
  unprivileged() { command "$@"; }
  # shellcheck disable=SC2317
  buildpack-install() {
    echo "$1|$2|$3" >>"$_select_buildpack_install_args"
    mkdir -p "$buildpack_path/custom/bin"
    cat >"$buildpack_path/custom/bin/detect" <<'DETECT'
#!/usr/bin/env bash
echo Custom
DETECT
    command chmod +x "$buildpack_path/custom/bin/detect"
  }
}

@test "select-buildpack-single-url-in-dotbuildpacks-promoted-to-url" {
  # Issue #554: a single URL in .buildpacks must be treated like BUILDPACK_URL.
  _select-buildpack-setup
  echo "https://github.com/heroku/heroku-buildpack-ruby" >"$build_path/.buildpacks"
  unset BUILDPACK_URL

  run _select-buildpack
  local install_args
  install_args="$(cat "$_select_buildpack_install_args")"
  rm -rf "$_select_buildpack_root"

  [[ "$status" -eq 0 ]] || {
    echo "expected exit 0, got $status; output: $output"
    return 1
  }
  [[ "$install_args" == "https://github.com/heroku/heroku-buildpack-ruby||custom" ]] || {
    echo "expected buildpack-install to be called with the single URL, got: '$install_args'"
    return 2
  }
  [[ "$output" != *"Multiple default buildpacks"* ]] || {
    echo "expected no 'Multiple default buildpacks' warning, got: $output"
    return 3
  }
  [[ "$output" == *"Fetching custom buildpack"* ]] || {
    echo "expected 'Fetching custom buildpack' title, got: $output"
    return 4
  }
}

@test "select-buildpack-single-url-with-comments-and-blanks" {
  # Comments and blank lines must be ignored when counting URLs.
  _select-buildpack-setup
  cat >"$build_path/.buildpacks" <<'EOF'
# this is a comment

  # indented comment
   https://github.com/heroku/heroku-buildpack-ruby

EOF
  unset BUILDPACK_URL

  run _select-buildpack
  local install_args
  install_args="$(cat "$_select_buildpack_install_args")"
  rm -rf "$_select_buildpack_root"

  [[ "$status" -eq 0 ]] || {
    echo "expected exit 0, got $status; output: $output"
    return 1
  }
  [[ "$install_args" == "https://github.com/heroku/heroku-buildpack-ruby||custom" ]] || {
    echo "expected single trimmed URL, got: '$install_args'"
    return 2
  }
  [[ "$output" != *"Multiple default buildpacks"* ]] || {
    echo "expected no 'Multiple default buildpacks' warning, got: $output"
    return 3
  }
}

@test "select-buildpack-multiple-urls-uses-default-flow" {
  # 2+ URLs in .buildpacks must fall through to the default (multi) flow,
  # i.e. buildpack-install through the custom path must NOT be invoked.
  _select-buildpack-setup
  cat >"$build_path/.buildpacks" <<'EOF'
https://github.com/heroku/heroku-buildpack-ruby
https://github.com/heroku/heroku-buildpack-nodejs
EOF
  unset BUILDPACK_URL

  # Seed a multi buildpack so the fallthrough path has something to detect.
  mkdir -p "$buildpack_path/00_buildpack-multi/bin"
  cat >"$buildpack_path/00_buildpack-multi/bin/detect" <<'EOF'
#!/usr/bin/env bash
echo Multipack
EOF
  command chmod +x "$buildpack_path/00_buildpack-multi/bin/detect"

  run _select-buildpack
  local install_args
  install_args="$(cat "$_select_buildpack_install_args")"
  rm -rf "$_select_buildpack_root"

  [[ "$status" -eq 0 ]] || {
    echo "expected exit 0, got $status; output: $output"
    return 1
  }
  [[ -z "$install_args" ]] || {
    echo "expected buildpack-install NOT to be called via URL path, got: '$install_args'"
    return 2
  }
  [[ "$output" == *"Multipack app detected"* ]] || {
    echo "expected 'Multipack app detected' via multi flow, got: $output"
    return 3
  }
}

@test "select-buildpack-buildpack-url-wins-over-dotbuildpacks" {
  # Callers that pre-set BUILDPACK_URL must keep precedence over .buildpacks.
  _select-buildpack-setup
  echo "https://github.com/in-file" >"$build_path/.buildpacks"
  export BUILDPACK_URL="https://github.com/from-env"

  run _select-buildpack
  local install_args
  install_args="$(cat "$_select_buildpack_install_args")"
  unset BUILDPACK_URL
  rm -rf "$_select_buildpack_root"

  [[ "$status" -eq 0 ]] || {
    echo "expected exit 0, got $status; output: $output"
    return 1
  }
  [[ "$install_args" == "https://github.com/from-env||custom" ]] || {
    echo "expected BUILDPACK_URL value to be used, got: '$install_args'"
    return 2
  }
}

@test "select-buildpack-comment-only-dotbuildpacks-falls-through" {
  # A .buildpacks file with zero real URLs must fall through to the default
  # flow (same as "no file"), not hijack the custom path with an empty URL.
  _select-buildpack-setup
  cat >"$build_path/.buildpacks" <<'EOF'
# only a comment

EOF
  unset BUILDPACK_URL

  mkdir -p "$buildpack_path/00_buildpack-ruby/bin"
  cat >"$buildpack_path/00_buildpack-ruby/bin/detect" <<'EOF'
#!/usr/bin/env bash
echo Ruby
EOF
  command chmod +x "$buildpack_path/00_buildpack-ruby/bin/detect"

  run _select-buildpack
  local install_args
  install_args="$(cat "$_select_buildpack_install_args")"
  rm -rf "$_select_buildpack_root"

  [[ "$status" -eq 0 ]] || {
    echo "expected exit 0, got $status; output: $output"
    return 1
  }
  [[ -z "$install_args" ]] || {
    echo "expected buildpack-install NOT to be called, got: '$install_args'"
    return 2
  }
  [[ "$output" == *"Ruby app detected"* ]] || {
    echo "expected 'Ruby app detected' via default flow, got: $output"
    return 3
  }
}

@test "select-buildpack-fetch-message-shows-buildpack-name" {
  # The "Fetching custom buildpack" title must include the buildpack identity.
  # GitHub URLs are shortened to owner/repo; non-GitHub URLs are shown in full.
  _select-buildpack-setup

  # GitHub HTTPS with .git suffix and branch
  export BUILDPACK_URL="https://github.com/heroku/heroku-buildpack-python.git#main"
  run _select-buildpack
  rm -rf "$_select_buildpack_root"
  [[ "$output" == *"Fetching custom buildpack heroku/heroku-buildpack-python#main"* ]] || {
    echo "GitHub HTTPS: expected shorthand with branch, got: $output"
    return 1
  }

  # GitHub HTTPS without .git suffix or branch
  _select-buildpack-setup
  export BUILDPACK_URL="https://github.com/heroku/heroku-buildpack-ruby"
  run _select-buildpack
  rm -rf "$_select_buildpack_root"
  [[ "$output" == *"Fetching custom buildpack heroku/heroku-buildpack-ruby"* ]] || {
    echo "GitHub HTTPS plain: expected shorthand, got: $output"
    return 2
  }

  # GitHub SSH with .git suffix
  _select-buildpack-setup
  export BUILDPACK_URL="git@github.com:heroku/heroku-buildpack-nodejs.git"
  run _select-buildpack
  rm -rf "$_select_buildpack_root"
  [[ "$output" == *"Fetching custom buildpack heroku/heroku-buildpack-nodejs"* ]] || {
    echo "GitHub SSH: expected shorthand, got: $output"
    return 3
  }

  # Non-GitHub URL shown in full
  _select-buildpack-setup
  export BUILDPACK_URL="https://example.com/custom-buildpack#v2"
  run _select-buildpack
  rm -rf "$_select_buildpack_root"
  [[ "$output" == *"Fetching custom buildpack https://example.com/custom-buildpack#v2"* ]] || {
    echo "Non-GitHub: expected full URL with branch, got: $output"
    return 4
  }
}

@test "procfile-parse-valid" {
  # shellcheck disable=SC1091
  source "${BATS_TEST_DIRNAME}/../../include/procfile.bash"
  local expected actual app_path
  app_path="${BATS_TEST_DIRNAME}/fixtures"
  for type in web worker; do
    case "$type" in
      web)
        expected="npm start"
        ;;
      worker)
        expected="npm worker"
        ;;
    esac
    actual=$(procfile-parse "$type" | xargs)
    if [[ "$actual" != "$expected" ]]; then
      echo "$actual != $expected"
      return 1
    fi
  done
}

@test "procfile-parse-merge-conflict" {
  # shellcheck disable=SC1091
  source "${BATS_TEST_DIRNAME}/../../include/procfile.bash"
  local expected actual app_path
  app_path="${BATS_TEST_DIRNAME}/fixtures-merge-conflict"
  for type in web worker; do
    case "$type" in
      web)
        expected="npm start"
        ;;
      worker)
        expected="npm worker"
        ;;
    esac
    actual=$(procfile-parse "$type" | xargs)
    if [[ "$actual" != "$expected" ]]; then
      echo "$actual != $expected"
      return 1
    fi
  done
}

@test "procfile-parse-invalid" {
  # shellcheck disable=SC1091
  source "${BATS_TEST_DIRNAME}/../../include/procfile.bash"
  local expected actual app_path
  app_path="${BATS_TEST_DIRNAME}/fixtures"

  expected="Proc entrypoint invalid-proc does not exist. Please check your Procfile"
  run procfile-start invalid-proc
  [[ "$status" -eq 1 ]]
  [[ "$output" == "$expected" ]] || {
    echo "procfile-start did not throw error for invalid procfile"
    echo "expected: $expected"
    echo "actual:   $output"
    return 1
  }
}

@test "procfile-types" {
  title() {
    # shellcheck disable=SC2317
    :
  }
  # shellcheck disable=SC1091
  source "${BATS_TEST_DIRNAME}/../../include/procfile.bash"
  local expected actual app_path
  app_path="${BATS_TEST_DIRNAME}/fixtures"

  expected="Procfile declares types -> web, worker"
  actual="$(procfile-types invalid-proc | tail -1)"

  if [[ "$actual" != "$expected" ]]; then
    echo "$actual != $expected"
    return 1
  fi
}

@test "procfile-types-merge-conflict" {
  title() {
    # shellcheck disable=SC2317
    :
  }
  # shellcheck disable=SC1091
  source "${BATS_TEST_DIRNAME}/../../include/procfile.bash"
  local expected actual app_path
  app_path="${BATS_TEST_DIRNAME}/fixtures-merge-conflict"

  expected="Procfile declares types -> web, worker"
  actual="$(procfile-types invalid-proc | tail -1)"

  if [[ "$actual" != "$expected" ]]; then
    echo "$actual != $expected"
    return 1
  fi
}

@test "procfile-load-env" {
  # shellcheck disable=SC1091
  source "${BATS_TEST_DIRNAME}/../../include/procfile.bash"
  local expected actual app_path env_path
  env_path="${BATS_TEST_DIRNAME}/fixtures/env"

  procfile-load-env
  actual="$TEST_BUILDPACK_URL"
  expected="$(cat "$env_path/TEST_BUILDPACK_URL")"

  if [[ "$actual" != "$expected" ]]; then
    echo "$actual != $expected"
    return 1
  fi
  unset TEST_BUILDPACK_URL
}

@test "procfile-load-profile" {
  # shellcheck disable=SC1091
  source "${BATS_TEST_DIRNAME}/../../include/procfile.bash"
  local expected actual app_path
  # shellcheck disable=SC2034
  app_path="${BATS_TEST_DIRNAME}/fixtures"

  procfile-load-profile
  actual="$TEST_APP_TYPE"
  expected="nodejs"

  if [[ "$actual" != "$expected" ]]; then
    echo "$actual != $expected"
    return 1
  fi
}

# The following two tests pass an invalid command so the underlying `exec`
# fails before it can hijack the test shell. We assert that procfile-exec
# actually reaches the exec step and that exec emits a "command not found"
# error, which proves the function executed end-to-end.
@test "procfile-exec" {
  # shellcheck disable=SC1091
  source "${BATS_TEST_DIRNAME}/../../include/procfile.bash"
  # shellcheck disable=SC2034
  app_path="${BATS_TEST_DIRNAME}/fixtures"
  # shellcheck disable=SC2034
  env_path="$app_path/env"
  export HEROKUISH_DISABLE_CHOWN=true

  run procfile-exec invalid
  # exec of an unknown command exits 127; older bats lacks `run -127`
  [[ "$status" -eq 127 ]] || {
    echo "expected procfile-exec to exit 127, got $status"
    echo "output: $output"
    return 1
  }
  # On systems with setuidgid the missing binary is `invalid`; without it
  # (e.g. local dev), bash reports `setuidgid: not found`. Either proves
  # the exec step was reached.
  [[ "$output" == *"not found"* ]] || {
    echo "expected 'not found' in output, got: $output"
    return 1
  }
}

@test "procfile-exec-setuidgid-optout" {
  # shellcheck disable=SC1091
  source "${BATS_TEST_DIRNAME}/../../include/procfile.bash"
  # shellcheck disable=SC2034
  app_path="${BATS_TEST_DIRNAME}/fixtures"
  # shellcheck disable=SC2034
  env_path="$app_path/env"
  export HEROKUISH_DISABLE_CHOWN=true
  export HEROKUISH_SETUIDGUID=false

  run procfile-exec invalid
  # exec of an unknown command exits 127; older bats lacks `run -127`
  [[ "$status" -eq 127 ]] || {
    echo "expected procfile-exec to exit 127, got $status"
    echo "output: $output"
    return 1
  }
  # With setuidgid bypassed, exec runs `invalid` directly so the missing
  # binary in the error message is `invalid`.
  [[ "$output" == *"invalid"*"not found"* ]] || {
    echo "expected 'invalid ... not found' in output, got: $output"
    return 1
  }
}

# procfile-ensure-entropy is the runtime hook that seeds /dev/random via rngd
# when operators opt in with HEROKUISH_ENTROPY=true. See gliderlabs/herokuish#659.

@test "procfile-ensure-entropy-default-off" {
  # shellcheck disable=SC1091
  source "${BATS_TEST_DIRNAME}/../../include/procfile.bash"
  unset HEROKUISH_ENTROPY
  export ENTROPY_TEST_MARKER
  ENTROPY_TEST_MARKER="$(mktemp)"
  # Fail loudly if the helper tries to call rngd when the flag is unset.
  # shellcheck disable=SC2317
  rngd() {
    echo "rngd should not have been invoked" >"$ENTROPY_TEST_MARKER"
    return 0
  }
  export -f rngd

  run procfile-ensure-entropy
  local marker="$ENTROPY_TEST_MARKER"
  unset -f rngd
  unset ENTROPY_TEST_MARKER

  [[ "$status" -eq 0 ]] || {
    echo "expected procfile-ensure-entropy to exit 0, got $status"
    echo "output: $output"
    rm -f "$marker"
    return 1
  }
  if [[ -s "$marker" ]]; then
    echo "procfile-ensure-entropy ran rngd without HEROKUISH_ENTROPY=true"
    cat "$marker"
    rm -f "$marker"
    return 2
  fi
  rm -f "$marker"
}

@test "procfile-ensure-entropy-missing-rngd" {
  # shellcheck disable=SC1091
  source "${BATS_TEST_DIRNAME}/../../include/procfile.bash"
  export HEROKUISH_ENTROPY=true
  # Shadow `command` so the helper believes rngd is absent without depending
  # on what's installed on the host.
  # shellcheck disable=SC2317
  command() {
    if [[ "$1" == "-v" && "$2" == "rngd" ]]; then
      return 1
    fi
    builtin command "$@"
  }
  export -f command

  run procfile-ensure-entropy
  unset -f command
  unset HEROKUISH_ENTROPY

  [[ "$status" -eq 0 ]] || {
    echo "expected procfile-ensure-entropy to exit 0 when rngd is missing, got $status"
    echo "output: $output"
    return 1
  }
  [[ "$output" == *"rngd is not installed"* ]] || {
    echo "expected warning about missing rngd, got: $output"
    return 2
  }
}

@test "procfile-ensure-entropy-opt-in" {
  # shellcheck disable=SC1091
  source "${BATS_TEST_DIRNAME}/../../include/procfile.bash"
  export HEROKUISH_ENTROPY=true
  export ENTROPY_TEST_MARKER
  ENTROPY_TEST_MARKER="$(mktemp)"
  # Stub pgrep so the helper believes rngd is not yet running, regardless of
  # whether the host has any rngd running.
  # shellcheck disable=SC2317
  pgrep() { return 1; }
  export -f pgrep
  # Stub rngd so starting it is a cheap success that we can observe.
  # Defining it as a function also satisfies `command -v rngd` without any
  # further shadowing.
  # shellcheck disable=SC2317
  rngd() {
    echo "started $*" >"$ENTROPY_TEST_MARKER"
    return 0
  }
  export -f rngd

  run procfile-ensure-entropy
  local marker="$ENTROPY_TEST_MARKER"
  unset -f pgrep rngd
  unset HEROKUISH_ENTROPY ENTROPY_TEST_MARKER

  [[ "$status" -eq 0 ]] || {
    echo "expected procfile-ensure-entropy to exit 0, got $status"
    echo "output: $output"
    rm -f "$marker"
    return 1
  }
  [[ -s "$marker" ]] || {
    echo "procfile-ensure-entropy did not invoke rngd"
    rm -f "$marker"
    return 2
  }
  [[ "$(cat "$marker")" == "started -b" ]] || {
    echo "expected rngd to be started with -b, got: $(cat "$marker")"
    rm -f "$marker"
    return 3
  }
  rm -f "$marker"
}

# Helpers for the issue #2050 unprivileged tests. _unprivileged-setup sources
# herokuish.bash and stubs chown/setuidgid so each test can point stdio at
# /dev/null, a device node or a regular file without touching real ownership.
# The chown stub records its args and fails for the fd in $CHOWN_FAIL_FD.
_unprivileged-setup() {
  # shellcheck disable=SC1091
  source "${BATS_TEST_DIRNAME}/../../include/herokuish.bash"
  _unprivileged_root="$(mktemp -d)"
  # herokuish.bash declares unprivileged_user, which is local when sourced
  # from a function, so set it globally for the tests to see
  # shellcheck disable=SC2034
  declare -g unprivileged_user="herokuishuser"
  _unprivileged_chown_args="$_unprivileged_root/chown-args"
  _unprivileged_setuidgid_args="$_unprivileged_root/setuidgid-args"
  : >"$_unprivileged_chown_args"
  unset CHOWN_FAIL_FD
  # shellcheck disable=SC2317
  chown() {
    echo "$*" >>"$_unprivileged_chown_args"
    [[ -n "$CHOWN_FAIL_FD" && "$2" == */fd/"$CHOWN_FAIL_FD" ]] && return 1
    return 0
  }
  # shellcheck disable=SC2317
  setuidgid() { echo "$*" >"$_unprivileged_setuidgid_args"; }
}

@test "unprivileged-stdio-skips-dev-null" {
  # Issue #2050: rootless docker cannot chown /dev/null, so stdio redirected
  # there must be skipped rather than failing the build.
  _unprivileged-setup
  local status=0
  unprivileged true </dev/null >/dev/null 2>/dev/null || status=$?
  local chown_args setuidgid_args
  chown_args="$(cat "$_unprivileged_chown_args")"
  setuidgid_args="$(cat "$_unprivileged_setuidgid_args" 2>/dev/null || true)"
  rm -rf "$_unprivileged_root"

  [[ "$status" -eq 0 ]] || {
    echo "expected exit 0, got $status"
    return 1
  }
  [[ -z "$chown_args" ]] || {
    echo "expected /dev/null not to be chowned, got: '$chown_args'"
    return 2
  }
  [[ "$setuidgid_args" == "herokuishuser true" ]] || {
    echo "expected setuidgid to run the command, got: '$setuidgid_args'"
    return 3
  }
}

@test "unprivileged-stdio-tolerates-device-chown-failure" {
  # Device nodes such as ttys may be owned by an unmapped uid under rootless
  # docker; a failed chown on them must not stop the command from running.
  _unprivileged-setup
  export CHOWN_FAIL_FD=0
  local status=0
  unprivileged true </dev/zero >/dev/null 2>/dev/null || status=$?
  unset CHOWN_FAIL_FD
  local chown_args setuidgid_args
  chown_args="$(cat "$_unprivileged_chown_args")"
  setuidgid_args="$(cat "$_unprivileged_setuidgid_args" 2>/dev/null || true)"
  rm -rf "$_unprivileged_root"

  [[ "$status" -eq 0 ]] || {
    echo "expected exit 0, got $status"
    return 1
  }
  [[ "$chown_args" == "herokuishuser /proc/"*"/fd/0" ]] || {
    echo "expected chown to be attempted on stdin, got: '$chown_args'"
    return 2
  }
  [[ "$setuidgid_args" == "herokuishuser true" ]] || {
    echo "expected setuidgid to run the command, got: '$setuidgid_args'"
    return 3
  }
}

@test "unprivileged-stdio-fails-on-file-chown-failure" {
  # Failures on pipes and regular files are real permission problems and must
  # still fail before the command runs.
  _unprivileged-setup
  export CHOWN_FAIL_FD=1
  local status=0
  unprivileged true </dev/null >"$_unprivileged_root/stdout" 2>/dev/null || status=$?
  unset CHOWN_FAIL_FD
  local setuidgid_ran=false
  [[ -f "$_unprivileged_setuidgid_args" ]] && setuidgid_ran=true
  rm -rf "$_unprivileged_root"

  [[ "$status" -ne 0 ]] || {
    echo "expected non-zero exit when chown of a file fails, got 0"
    return 1
  }
  [[ "$setuidgid_ran" == false ]] || {
    echo "expected setuidgid not to run after a failed chown"
    return 2
  }
}

@test "unprivileged-stdio-chowns-regular-stdio" {
  # Pipes and files are handed to the unprivileged user so buildpacks can
  # reopen /dev/stdout and /dev/stderr.
  _unprivileged-setup
  local status=0
  unprivileged echo hello </dev/null >"$_unprivileged_root/stdout" 2>/dev/null || status=$?
  local chown_args setuidgid_args
  chown_args="$(cat "$_unprivileged_chown_args")"
  setuidgid_args="$(cat "$_unprivileged_setuidgid_args" 2>/dev/null || true)"
  rm -rf "$_unprivileged_root"

  [[ "$status" -eq 0 ]] || {
    echo "expected exit 0, got $status"
    return 1
  }
  [[ "$chown_args" == "herokuishuser /proc/"*"/fd/1" ]] || {
    echo "expected only stdout to be chowned, got: '$chown_args'"
    return 2
  }
  [[ "$setuidgid_args" == "herokuishuser echo hello" ]] || {
    echo "expected setuidgid to run the command, got: '$setuidgid_args'"
    return 3
  }
}
