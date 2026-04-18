#!/usr/bin/env bats
# shellcheck shell=bash

load ../../../test_helper

@test "scala" {
  _run-cmd scala test
}
