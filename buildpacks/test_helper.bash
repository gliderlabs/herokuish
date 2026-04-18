# shellcheck shell=bash

# runs the command on buildpack test application
_run-cmd() {
  [[ "$TRACE" ]] && set -x
  declare app="$1"
  local cmd="$2"
  local app_path="${BATS_TEST_DIRNAME}"
  [[ "$CI" ]] || rmflag="--rm"
  [[ "$TRACE" ]] && debug_flag="-e TRACE=true"
  # shellcheck disable=SC2086
  docker run -t $rmflag $debug_flag --env=USER=herokuishuser -e HEROKUISH_WITH_TTY=true -v "$app_path:/tmp/app" herokuish:dev /bin/herokuish $cmd / "$app"
}
