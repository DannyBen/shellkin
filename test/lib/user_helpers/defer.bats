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
