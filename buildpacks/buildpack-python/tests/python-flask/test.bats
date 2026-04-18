#!/usr/bin/env bats
# shellcheck shell=bash

load ../../../test_helper

@test "python-flask" {
  _run-cmd python-flask test
}
