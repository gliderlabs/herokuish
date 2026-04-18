#!/usr/bin/env bats
# shellcheck shell=bash

load ../../../test_helper

@test "java-getting-started" {
  _run-cmd java-getting-started test
}
