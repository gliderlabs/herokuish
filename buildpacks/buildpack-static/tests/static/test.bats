#!/usr/bin/env bats
# shellcheck shell=bash

load ../../../test_helper

@test "static" {
  _run-cmd static test
}
