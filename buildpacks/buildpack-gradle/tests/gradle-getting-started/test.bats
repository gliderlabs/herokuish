#!/usr/bin/env bats
# shellcheck shell=bash

load ../../../test_helper

@test "gradle-getting-started" {
  _run-cmd gradle-getting-started test
}
