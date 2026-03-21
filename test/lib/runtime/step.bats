#!/usr/bin/env bats

load ../../test_helper.bash

setup() {
  setup_test_environment

  eval "$(declare -f run | sed '1s/^run /bats_run /')"
  source_libs syntax/pattern syntax/stepdef user_helpers/run user_helpers/fail runtime/step

  STEPDEF_TYPES=()
  STEPDEF_PATTERNS=()
  STEPDEF_REGEXES=()
  STEPDEF_TOKENS_LIST=()
  STEPDEF_BODIES=()

  LAST_EXIT_CODE=
  LAST_STDOUT=
  LAST_STDERR=
  FAIL_MESSAGE=
  STEP_RESULT=
}

teardown() {
  teardown_test_environment
}

@test "step_run matches a step definition and runs its body" {
  stepdef_parse "@When I run '{command}'"
  stepdef_register 'run "$command"'

  step_run When "I run 'printf hello'"

  [ "$LAST_EXIT_CODE" -eq 0 ]
  [ "$LAST_STDOUT" = "hello" ]
  [ -z "$LAST_STDERR" ]
}

@test "step_run binds multiple tokens in declaration order" {
  stepdef_parse "@When I copy {source} to {destination}"
  stepdef_register 'STEP_RESULT="$source:$destination"'

  step_run When "I copy left.txt to right.txt"

  [ "$STEP_RESULT" = "left.txt:right.txt" ]
}

@test "step_run returns non-zero when no step definition matches" {
  stepdef_parse "@When I run '{command}'"
  stepdef_register 'run "$command"'

  ! step_run Then "the file 'somefile' should exist"
  [ "$FAIL_MESSAGE" = "no matching step definition for: Then the file 'somefile' should exist" ]
}

@test "step_run returns the body status when the body fails" {
  stepdef_parse "@Then the command should fail"
  stepdef_register 'return 7'

  bats_run step_run Then "the command should fail"

  [ "$status" -eq 7 ]
}

@test "step_run exposes a custom failure message from fail" {
  stepdef_parse "@Then the output should include '{text}'"
  stepdef_register 'fail "invalid output detected"'

  ! step_run Then "the output should include 'hello'"

  [ "$FAIL_MESSAGE" = "invalid output detected" ]
}
