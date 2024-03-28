# shellcheck shell=bash

herokuish-test() {
  declare name="$1" script="$2"
  # shellcheck disable=SC2046,SC2154
  docker run $([[ "$CI" ]] || echo "--rm") -v "$PWD:/mnt" \
    "herokuish:dev" bash -c "set -e; $script" \
    || $T_fail "$name exited non-zero"
}

fn-source() {
  # use this if you want to write tests
  # in functions instead of strings.
  # see test-binary for trivial example
  # shellcheck disable=SC2086
  declare -f $1 | tail -n +2
}

function cleanup {
  echo "Tests cleanup"
  local procfile
  procfile="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/Procfile"
  if [[ -f "$procfile" ]]; then
    rm -f "$procfile"
  fi
}

trap cleanup EXIT

T_binary() {
  _test-binary() {
    # shellcheck disable=SC2317
    herokuish
  }
  herokuish-test "test-binary" "$(fn-source _test-binary)"
}

T_default-user() {
  _test-user() {
    # shellcheck disable=SC2317
    id herokuishuser
  }
  herokuish-test "test-user" "$(fn-source _test-user)"
}

T_generate-slug() {
  herokuish-test "test-slug-generate" "
		herokuish slug generate
		tar tzf /tmp/slug.tgz"
}
