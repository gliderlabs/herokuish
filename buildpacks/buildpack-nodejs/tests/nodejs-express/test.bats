#!/usr/bin/env bats
# shellcheck shell=bash

load ../../../test_helper

@test "nodejs-express" {
  _run-cmd nodejs-express test
}
