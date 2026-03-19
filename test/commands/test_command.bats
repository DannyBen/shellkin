#!/usr/bin/env bats

load ../test_helper.bash

setup() {
  setup_test_environment
}

teardown() {
  teardown_test_environment
}

@test "shellkin test runs feature files from the provided directory" {
  write_file features/sample.feature <<'EOF'
Feature: Create a file

Scenario: Touch a file
  Given I am in a temp directory
  When I run 'touch somefile'
  Then the file 'somefile' should exist
EOF

  write_file features/step_definitions/core.sh <<'EOF'
@Given I am in a temp directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

@When I run '{command}'
PATH="$SHELLKIN_ROOT:$PATH" run "$command"

@Then the file '{path}' should exist
[[ -f "$path" ]]

@Then the output should include '{text}'
[[ "$LAST_STDOUT" == *"$text"* ]]
EOF

  run "$SHELLKIN_REPO_ROOT/shellkin" test "$TEST_ROOT/features"

  [ "$status" -eq 0 ]
  assert_output_contains "Feature: Create a file"
  assert_output_contains "Scenario: Touch a file"
  assert_output_contains "1 scenario, 0 failing"
}
