#!/usr/bin/env bats

load ../../test_helper.bash

setup() {
  setup_test_environment
  source_libs core/trim
}

teardown() {
  teardown_test_environment
}

@test "trim removes leading and trailing spaces" {
  run trim "  hello world  "

  [ "$status" -eq 0 ]
  [ "$output" = "hello world" ]
}

@test "trim preserves internal spacing" {
  run trim "  hello   world  "

  [ "$status" -eq 0 ]
  [ "$output" = "hello   world" ]
}

@test "trim returns an empty string when given only whitespace" {
  run trim "   "

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "trim leaves an already trimmed value unchanged" {
  run trim "hello world"

  [ "$status" -eq 0 ]
  [ "$output" = "hello world" ]
}
