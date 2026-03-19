#!/usr/bin/env bats

load ../../test_helper.bash

setup() {
  setup_test_environment
  source_libs user_helpers/run

  LAST_EXIT_CODE=
  LAST_STDOUT=
  LAST_STDERR=
}

teardown() {
  unset_functions run
  teardown_test_environment
}

@test "run captures stdout from a successful command" {
  run "printf 'hello world'"

  [ "$LAST_EXIT_CODE" -eq 0 ]
  [ "$LAST_STDOUT" = "hello world" ]
  [ -z "$LAST_STDERR" ]
}

@test "run captures stderr and exit code from a failing command" {
  run "printf 'boom' >&2; exit 7"

  [ "$LAST_EXIT_CODE" -eq 7 ]
  [ -z "$LAST_STDOUT" ]
  [ "$LAST_STDERR" = "boom" ]
}

@test "run always returns success so callers can inspect state" {
  run "exit 12"
  status=$?

  [ "$status" -eq 0 ]
  [ "$LAST_EXIT_CODE" -eq 12 ]
}
