#!/usr/bin/env bats
# shellcheck shell=bash

load ../../../test_helper

@test "multi" {
  _run-cmd multi test
}
