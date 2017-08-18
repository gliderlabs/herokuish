
T_envfile-parse(){
    # shellcheck disable=SC1090
    source "$(dirname "${BASH_SOURCE[0]}")/../../include/buildpack.bash"
    local fixture_filename
    local foo_expected='Hello'$'\n'' '\''world'\'' '
    local bar_expected='te'\''st'

    fixture_filename="$(dirname "${BASH_SOURCE[0]}")/fixtures/complicated_envfile"
    eval "$(cat "$fixture_filename" | _envfile-parse)"

    # shellcheck disable=2154
    if [[ ! $foo_expected == "$foo" ]]; then
        echo "Expected foo = $foo_expected got: $foo"
        return 1
    fi

    # shellcheck disable=2154
    if [[ ! $bar_expected == "$bar" ]]; then
        echo "Expected bar = $bar_expected got: $bar"
        return 2
    fi
}

T_procfile-parse-valid() {
    # shellcheck disable=SC1090
    source "$(dirname "${BASH_SOURCE[0]}")/../../include/procfile.bash"
    local expected actual app_path
    app_path="$(dirname "${BASH_SOURCE[0]}")/fixtures"
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
        if [[ $actual != "$expected" ]]; then
            echo "$actual != $expected"
            return 1
        fi
    done
}

T_procfile-parse-invalid() {
    # shellcheck disable=SC1090
    source "$(dirname "${BASH_SOURCE[0]}")/../../include/procfile.bash"
    local expected actual app_path
    app_path="$(dirname "${BASH_SOURCE[0]}")/fixtures"

    expected="Proc entrypoint invalid-proc does not exist. Please check your Procfile"
    actual="$(procfile-start invalid-proc)"

    if [[ $actual != "$expected" ]]; then
        echo "procfile-start did not throw error for invalid procfile"
        return 1
    fi
}

T_procfile-types() {
    title() {
        :
    }
    # shellcheck disable=SC1090
    source "$(dirname "${BASH_SOURCE[0]}")/../../include/procfile.bash"
    local expected actual app_path
    app_path="$(dirname "${BASH_SOURCE[0]}")/fixtures"

    expected="Procfile declares types -> web, worker"
    actual="$(procfile-types invalid-proc | tail -1)"

    if [[ $actual != $expected ]]; then
        echo "$actual != $expected"
        return 1
    fi
}

T_procfile-load-env() {
    # shellcheck disable=SC1090
    source "$(dirname "${BASH_SOURCE[0]}")/../../include/procfile.bash"
    local expected actual app_path env_path
    env_path="$(dirname "${BASH_SOURCE[0]}")/fixtures/env"

    procfile-load-env
    actual="$TEST_BUILDPACK_URL"
    expected="$(cat "$env_path/TEST_BUILDPACK_URL")"

    if [[ $actual != $expected ]]; then
        echo "$actual != $expected"
        return 1
    fi
    unset TEST_BUILDPACK_URL
}

T_procfile-load-profile() {
    # shellcheck disable=SC1090
    source "$(dirname "${BASH_SOURCE[0]}")/../../include/procfile.bash"
    local expected actual app_path
    app_path="$(dirname "${BASH_SOURCE[0]}")/fixtures"

    procfile-load-profile
    actual="$TEST_APP_TYPE"
    expected="nodejs"

    if [[ $actual != $expected ]]; then
        echo "$actual != $expected"
        return 1
    fi
}
