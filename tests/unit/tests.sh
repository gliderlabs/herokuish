T_envfile-parse(){
    source "$(dirname $BASH_SOURCE)/../../include/buildpack.bash"
    local fixture_filename="$(dirname $BASH_SOURCE)/fixtures/complicated_envfile"
    local foo_expected='Hello'$'\n'' '\''world'\'' '
    local bar_expected='te'\''st'
    eval "$(cat "$fixture_filename" | _envfile-parse)"

    if [[ ! $foo_expected == $foo ]]; then
        echo "Expected foo = $foo_expected got: $foo"
        return 1
    fi

    if [[ ! $bar_expected == $bar ]]; then
        echo "Expected bar = $bar_expected got: $bar"
        return 2
    fi
}
