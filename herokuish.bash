#!/usr/bin/env bash
set -eo pipefail

asset-cat() {
        if [[ ! -f $1 ]]; then
                exit 2
        else
                cat $1
        fi
}

yaml-get() {
    python -c "
import sys
import yaml

m = yaml.load(sys.stdin)
for arg in sys.argv[1:]:
    m = m[arg]

if isinstance(m, dict):
    for k, v in m.items():
        print('{0}={1}'.format(k, v))
elif isinstance(m, list):
    for v in m:
        print(v)
else:
    print(m)
" $@
}

yaml-keys() {
    python -c "
import sys
import yaml

m = yaml.load(sys.stdin)
for arg in sys.argv[1:]:
    m = m[arg]

if isinstance(m, dict):
    for k in m:
        print(k)
" $@
}

source "include/herokuish.bash"
source "include/fn.bash"
source "include/cmd.bash"
source "include/buildpack.bash"
source "include/procfile.bash"
source "include/slug.bash"

main "${@:1}"
