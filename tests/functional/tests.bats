#!/usr/bin/env bats
# shellcheck shell=bash

herokuish-test() {
  declare name="$1" script="$2"
  # shellcheck disable=SC2046,SC2154
  docker run $([[ "$CI" ]] || echo "--rm") -v "$PWD:/mnt" \
    "herokuish:dev" bash -c "set -e; $script"
}

fn-source() {
  # use this if you want to write tests
  # in functions instead of strings.
  # see test-binary for trivial example
  # shellcheck disable=SC2086
  declare -f $1 | tail -n +2
}

teardown_file() {
  echo "Tests cleanup"
  local procfile
  procfile="${BATS_TEST_DIRNAME}/Procfile"
  if [[ -f "$procfile" ]]; then
    rm -f "$procfile"
  fi
}

@test "binary" {
  _test-binary() {
    # shellcheck disable=SC2317
    herokuish
  }
  herokuish-test "test-binary" "$(fn-source _test-binary)"
}

@test "default-user" {
  _test-user() {
    # shellcheck disable=SC2317
    id herokuishuser
  }
  herokuish-test "test-user" "$(fn-source _test-user)"
}

# rng-tools5 is shipped in the image so operators can opt into seeding
# /dev/random via HEROKUISH_ENTROPY=true. See gliderlabs/herokuish#659.
@test "rng-tools-installed" {
  _test-rngd-present() {
    # shellcheck disable=SC2317
    command -v rngd
  }
  herokuish-test "test-rngd-present" "$(fn-source _test-rngd-present)"
}

@test "generate-slug" {
  herokuish-test "test-slug-generate" "
		herokuish slug generate
		tar tzf /tmp/slug.tgz"
}

@test "buildpack-detect-default" {
  herokuish-test "buildpack-detect-default" "
    set -e
    unset BUILDPACK_URL
    export buildpack_path=/tmp/buildpacks
    export build_path=/tmp/app
    export unprivileged_user=\$(whoami)
    export unprivileged_group=\$(id -gn)

    rm -rf \$buildpack_path && mkdir -p \$buildpack_path

    mkdir -p \$buildpack_path/00_buildpack-ruby/bin
    {
      echo '#!/usr/bin/env bash'
      echo 'echo Ruby'
      echo 'exit 0'
    } > \$buildpack_path/00_buildpack-ruby/bin/detect
    chmod +x \$buildpack_path/00_buildpack-ruby/bin/detect

    herokuish buildpack detect | grep 'Ruby app detected'
  "
}

@test "buildpack-detect-fail" {
  herokuish-test "buildpack-detect-fail" "
    set -e
    unset BUILDPACK_URL
    export buildpack_path=/tmp/buildpacks
    export build_path=/tmp/app
    export unprivileged_user=\$(whoami)
    export unprivileged_group=\$(id -gn)

    rm -rf \$buildpack_path && mkdir -p \$buildpack_path

    mkdir -p \$buildpack_path/00_buildpack-fail/bin
    {
      echo '#!/usr/bin/env bash'
      echo 'exit 1'
    } > \$buildpack_path/00_buildpack-fail/bin/detect
    chmod +x \$buildpack_path/00_buildpack-fail/bin/detect

    herokuish buildpack detect 2>&1 | grep 'Unable to select a buildpack'
  "
}

# Regression tests for gliderlabs/herokuish#553: a failing custom buildpack
# download must exit non-zero with an actionable error instead of stopping
# silently. Each case points BUILDPACK_URL at a different class of bad input.

@test "buildpack-install-invalid-url" {
  herokuish-test "buildpack-install-invalid-url" "
    set +e
    export BUILDPACK_URL=ruby
    output=\$(herokuish buildpack install \"\$BUILDPACK_URL\" 2>&1)
    rc=\$?
    set -e
    if [[ \"\$rc\" -eq 0 ]]; then
      echo 'expected non-zero exit, got 0'
      echo \"\$output\"
      exit 1
    fi
    echo \"\$output\" | grep -q \"Invalid buildpack URL: 'ruby'\"
  "
}

@test "buildpack-install-bad-tarball-url" {
  herokuish-test "buildpack-install-bad-tarball-url" "
    set +e
    export BUILDPACK_URL=https://example.invalid/does-not-exist.tar.gz
    output=\$(herokuish buildpack install \"\$BUILDPACK_URL\" 2>&1)
    rc=\$?
    set -e
    if [[ \"\$rc\" -eq 0 ]]; then
      echo 'expected non-zero exit, got 0'
      echo \"\$output\"
      exit 1
    fi
    echo \"\$output\" | grep -q 'Failed to download buildpack'
  "
}

# Regression test for gliderlabs/herokuish#554: when .buildpacks declares a
# single buildpack, herokuish should route through the custom BUILDPACK_URL
# path — skipping heroku-buildpack-multi and its "Multiple default buildpacks"
# warning — because there is no real ambiguity.
@test "buildpack-detect-single-url-in-dotbuildpacks" {
  herokuish-test "buildpack-detect-single-url-in-dotbuildpacks" "
    set -e
    unset BUILDPACK_URL
    export buildpack_path=/tmp/buildpacks
    export build_path=/tmp/app
    export unprivileged_user=\$(whoami)
    export unprivileged_group=\$(id -gn)

    rm -rf \$buildpack_path && mkdir -p \$buildpack_path
    mkdir -p \$build_path

    # Seed two default buildpacks: a realistic multi that only detects when
    # .buildpacks exists, and a ruby stub that always detects. Under the old
    # flow both would match and trigger the misleading 'Multiple default
    # buildpacks' warning.
    mkdir -p \$buildpack_path/00_buildpack-multi/bin
    {
      echo '#!/usr/bin/env bash'
      echo '[[ -f \"\$1/.buildpacks\" ]] && { echo Multipack; exit 0; }'
      echo 'exit 1'
    } > \$buildpack_path/00_buildpack-multi/bin/detect
    chmod +x \$buildpack_path/00_buildpack-multi/bin/detect

    mkdir -p \$buildpack_path/01_buildpack-ruby/bin
    {
      echo '#!/usr/bin/env bash'
      echo 'echo Ruby'
    } > \$buildpack_path/01_buildpack-ruby/bin/detect
    chmod +x \$buildpack_path/01_buildpack-ruby/bin/detect

    # Build a local git repo to act as the single custom buildpack that
    # .buildpacks points at. Using file:// avoids network dependencies and
    # exercises the real buildpack-install git-clone path.
    local_bp=/tmp/single-custom-buildpack
    rm -rf \$local_bp
    mkdir -p \$local_bp/bin
    {
      echo '#!/usr/bin/env bash'
      echo 'echo SingleCustom'
    } > \$local_bp/bin/detect
    chmod +x \$local_bp/bin/detect
    (
      cd \$local_bp
      git init -q
      git config user.email t@t
      git config user.name t
      git add -A
      git commit -q -m init
    )

    # Declare exactly one buildpack; should be treated like BUILDPACK_URL.
    echo \"file://\$local_bp\" > \$build_path/.buildpacks

    set +e
    output=\$(herokuish buildpack detect 2>&1)
    rc=\$?
    set -e
    if [[ \"\$rc\" -ne 0 ]]; then
      echo 'expected exit 0, got' \"\$rc\"
      echo \"\$output\"
      exit 1
    fi
    if echo \"\$output\" | grep -q 'Multiple default buildpacks reported'; then
      echo 'unexpected multi warning in output:'
      echo \"\$output\"
      exit 1
    fi
    if echo \"\$output\" | grep -q 'Multipack app detected'; then
      echo 'unexpected Multipack selection in output:'
      echo \"\$output\"
      exit 1
    fi
    echo \"\$output\" | grep -q 'SingleCustom app detected'
  "
}

@test "buildpack-detect-bad-buildpack-url" {
  herokuish-test "buildpack-detect-bad-buildpack-url" "
    set +e
    export buildpack_path=/tmp/buildpacks
    export build_path=/tmp/app
    export unprivileged_user=\$(whoami)
    export unprivileged_group=\$(id -gn)
    export BUILDPACK_URL=ruby

    rm -rf \$buildpack_path && mkdir -p \$buildpack_path
    mkdir -p \$build_path

    output=\$(herokuish buildpack detect 2>&1)
    rc=\$?
    set -e
    if [[ \"\$rc\" -eq 0 ]]; then
      echo 'expected non-zero exit, got 0'
      echo \"\$output\"
      exit 1
    fi
    echo \"\$output\" | grep -q \"Invalid buildpack URL: 'ruby'\"
    echo \"\$output\" | grep -q 'Unable to fetch custom buildpack from ruby'
  "
}
