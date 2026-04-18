#!/usr/bin/env bats
# shellcheck shell=bash

load ../../../test_helper

@test "go" {
  _run-cmd go test
}
