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
run "$command"

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

@test "shellkin test uses SHELLKIN_STEPDEFS_ROOT relative to the features root" {
  write_file custom_features/sample.feature <<'EOF'
Feature: Create a file

Scenario: Touch a file
  Given I am in a temp directory
  When I run 'touch somefile'
  Then the file 'somefile' should exist
EOF

  write_file custom_features/steps/core.sh <<'EOF'
@Given I am in a temp directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

@When I run '{command}'
run "$command"

@Then the file '{path}' should exist
[[ -f "$path" ]]
EOF

  run env SHELLKIN_STEPDEFS_ROOT=steps "$SHELLKIN_REPO_ROOT/shellkin" test "$TEST_ROOT/custom_features"

  [ "$status" -eq 0 ]
  assert_output_contains "Feature: Create a file"
  assert_output_contains "1 scenario, 0 failing"
}

@test "shellkin test --fail-fast stops after the first failing scenario" {
  write_file features/sample.feature <<'EOF'
Feature: Fail fast

Scenario: First
  When I fail
  Then I would create chaos

Scenario: Second
  Then I should not run
EOF

  write_file features/step_definitions/core.sh <<'EOF'
@When I fail
return 1

@Then I would create chaos
touch "$TEST_ROOT/chaos"

@Then I should not run
touch "$TEST_ROOT/second-scenario"
EOF

  run "$SHELLKIN_REPO_ROOT/shellkin" test --fail-fast "$TEST_ROOT/features"

  [ "$status" -eq 1 ]
  [ ! -e "$TEST_ROOT/chaos" ]
  [ ! -e "$TEST_ROOT/second-scenario" ]
  assert_output_contains "Scenario: First"
  [[ "$output" != *"Scenario: Second"* ]]
  assert_output_contains "1 scenario, 0 passing, 1 failing"
}
