#!/usr/bin/env bats
# shellcheck shell=bash

load ../../../test_helper

@test "php" {
  _run-cmd php test
}
