#!/usr/bin/env bats
# shellcheck shell=bash

load ../../../test_helper

@test "python-django" {
  _run-cmd python-django test
}
