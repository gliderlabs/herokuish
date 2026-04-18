#!/usr/bin/env bats
# shellcheck shell=bash

load ../../../test_helper

@test "null" {
  _run-cmd null test
}
