#!/usr/bin/env bash

source "include/herokuish.bash"
source "include/fn.bash"
source "include/cmd.bash"
source "include/buildpack.bash"
source "include/procfile.bash"
source "include/slug.bash"
main "${@:1}"
