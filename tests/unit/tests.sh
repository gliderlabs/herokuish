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
