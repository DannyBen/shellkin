#!/usr/bin/env bats

load ../../test_helper.bash

setup() {
  setup_test_environment
  source_libs user_helpers/defer

  SCENARIO_DEFERRED_COMMANDS=()
  FAIL_MESSAGE=
}

teardown() {
  teardown_test_environment
}

@test "defer stores a raw shell snippet" {
  defer 'printf "%s" "hello" > "$TEST_ROOT/output.txt"'
  defer__run_all

  [ "$(cat "$TEST_ROOT/output.txt")" = "hello" ]
}

@test "defer builds a shell-safe command from multiple arguments" {
  local path_with_spaces="$TEST_ROOT/a dir"

  defer mkdir -p "$path_with_spaces"
  defer__run_all

  [ -d "$path_with_spaces" ]
}

@test "defer__run_all executes deferred actions in LIFO order" {
  defer 'printf "%s\n" "first" >> "$TEST_ROOT/output.txt"'
  defer 'printf "%s\n" "second" >> "$TEST_ROOT/output.txt"'

  defer__run_all

  [ "$(cat "$TEST_ROOT/output.txt")" = $'second\nfirst' ]
}

@test "defer__run_all stops at the first deferred failure and stores a failure message" {
  defer 'printf "%s\n" "first" >> "$TEST_ROOT/output.txt"'
  defer 'return 1'
  defer 'printf "%s\n" "third" >> "$TEST_ROOT/output.txt"'

  if defer__run_all; then
    status=0
  else
    status=$?
  fi

  [ "$status" -eq 1 ]
  [ "$FAIL_MESSAGE" = "deferred action failed: return 1" ]
  [ "$(cat "$TEST_ROOT/output.txt")" = "third" ]
}
