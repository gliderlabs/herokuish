#!/usr/bin/env bats
# shellcheck shell=bash

load ../../../test_helper

@test "ruby-sinatra" {
  _run-cmd ruby-sinatra test
}

@test "test_ruby-sinatra" {
  _run-cmd ruby-sinatra 'buildpack test'
}
