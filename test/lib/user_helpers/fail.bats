#!/usr/bin/env bats

load ../../test_helper.bash

setup() {
  setup_test_environment
  source_libs user_helpers/fail

  FAIL_MESSAGE=
}

teardown() {
  teardown_test_environment
}

@test "fail stores the failure message and returns non-zero" {
  ! fail "invalid output detected"

  [ "$FAIL_MESSAGE" = "invalid output detected" ]
}
