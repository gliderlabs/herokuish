#!/usr/bin/env bats
# shellcheck shell=bash

load ../../../test_helper

@test "clojure-ring" {
  _run-cmd clojure-ring test
}

@test "test_clojure-ring" {
  _run-cmd clojure-ring 'buildpack test'
}
