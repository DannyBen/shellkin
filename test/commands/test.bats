#!/usr/bin/env bats

load ../test_helper.bash

setup() {
  setup_test_environment
}

teardown() {
  teardown_test_environment
}

@test "shellkin runs feature files from the provided directory" {
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

  run "$SHELLKIN_REPO_ROOT/shellkin" "$TEST_ROOT/features"

  [ "$status" -eq 0 ]
  assert_output_contains "Feature: Create a file"
  assert_output_contains "Scenario: Touch a file"
  assert_output_contains "1 scenario, 0 failing"
}

@test "shellkin uses --stepdefs relative to the features root" {
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

  run "$SHELLKIN_REPO_ROOT/shellkin" --stepdefs steps "$TEST_ROOT/custom_features"

  [ "$status" -eq 0 ]
  assert_output_contains "Feature: Create a file"
  assert_output_contains "1 scenario, 0 failing"
}

@test "shellkin loads the configured support file before running steps" {
  write_file custom_features/sample.feature <<'EOF'
Feature: Create a file

Scenario: Touch a file
  Given I am in a prepared temp directory
  When I run 'touch somefile'
  Then the file 'somefile' should exist
EOF

  write_file custom_features/helpers.sh <<'EOF'
prepare_temp_dir() {
  TEMP_DIR=$(mktemp -d)
  cd "$TEMP_DIR"
}
EOF

  write_file custom_features/step_definitions/core.sh <<'EOF'
@Given I am in a prepared temp directory
prepare_temp_dir

@When I run '{command}'
run "$command"

@Then the file '{path}' should exist
[[ -f "$path" ]]
EOF

  run "$SHELLKIN_REPO_ROOT/shellkin" --load helpers.sh "$TEST_ROOT/custom_features"

  [ "$status" -eq 0 ]
  assert_output_contains "Feature: Create a file"
  assert_output_contains "1 scenario, 0 failing"
}

@test "shellkin --fail-fast stops after the first failing scenario" {
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

  run "$SHELLKIN_REPO_ROOT/shellkin" --fail-fast "$TEST_ROOT/features"

  [ "$status" -eq 1 ]
  [ ! -e "$TEST_ROOT/chaos" ]
  [ ! -e "$TEST_ROOT/second-scenario" ]
  assert_output_contains "Scenario: First"
  [[ "$output" != *"Scenario: Second"* ]]
  assert_output_contains "1 scenario, 0 passing, 1 failing"
}

@test "shellkin --fail-fast stops before later feature files when the first file ends with a failing scenario" {
  write_file features/01-first.feature <<'EOF'
Feature: First

Scenario: Only
  When I fail
EOF

  write_file features/02-second.feature <<'EOF'
Feature: Second

Scenario: Should not run
  Then I should not run
EOF

  write_file features/step_definitions/core.sh <<'EOF'
@When I fail
return 1

@Then I should not run
touch "$TEST_ROOT/second-feature-ran"
EOF

  run "$SHELLKIN_REPO_ROOT/shellkin" --fail-fast "$TEST_ROOT/features"

  [ "$status" -eq 1 ]
  [ ! -e "$TEST_ROOT/second-feature-ran" ]
  [[ "$output" != *"Feature: Second"* ]]
  assert_output_contains "1 scenario, 0 passing, 1 failing"
}

@test "shellkin runs deferred cleanup after a failing scenario" {
  write_file features/sample.feature <<'EOF'
Feature: Deferred cleanup

Scenario: Cleanup after failure
  Given I create a tracked temp directory
  When I fail
EOF

  write_file features/step_definitions/core.sh <<'EOF'
@Given I create a tracked temp directory
TEMP_DIR=$(mktemp -d)
printf '%s' "$TEMP_DIR" > "$TEST_ROOT/tempdir-path"
defer rm -rf "$TEMP_DIR"

@When I fail
return 1
EOF

  run "$SHELLKIN_REPO_ROOT/shellkin" "$TEST_ROOT/features"

  path=$(cat "$TEST_ROOT/tempdir-path")
  [ "$status" -eq 1 ]
  [ ! -e "$path" ]
  assert_output_contains "1 scenario, 0 passing, 1 failing"
}

@test "shellkin reports a deferred cleanup failure during execution" {
  write_file features/sample.feature <<'EOF'
Feature: Deferred cleanup failure

Scenario: Show deferred failure
  Given I register a failing deferred action
EOF

  write_file features/step_definitions/core.sh <<'EOF'
@Given I register a failing deferred action
defer 'return 1'
EOF

  run "$SHELLKIN_REPO_ROOT/shellkin" "$TEST_ROOT/features"

  [ "$status" -eq 1 ]
  assert_output_contains "Deferred cleanup"
  assert_output_contains "FAIL_MESSAGE:"
  assert_output_contains "deferred action failed: return 1"
}

@test "shellkin reports a missing step definition during execution" {
  write_file features/sample.feature <<'EOF'
Feature: Missing step definition

Scenario: Show unmatched step
  Then I do not exist
EOF

  write_file features/step_definitions/core.sh <<'EOF'
@When I run '{command}'
run "$command"
EOF

  run "$SHELLKIN_REPO_ROOT/shellkin" "$TEST_ROOT/features"

  [ "$status" -eq 1 ]
  assert_output_contains "FAIL_MESSAGE:"
  assert_output_contains "no matching step definition for: Then I do not exist"
}

@test "shellkin does not load support files unless --load is provided" {
  write_file custom_features/sample.feature <<'EOF'
Feature: Explicit load only

Scenario: Missing helper
  Given I am in a prepared temp directory
EOF

  write_file custom_features/support.sh <<'EOF'
prepare_temp_dir() {
  TEMP_DIR=$(mktemp -d)
  cd "$TEMP_DIR"
}
EOF

  write_file custom_features/step_definitions/core.sh <<'EOF'
@Given I am in a prepared temp directory
prepare_temp_dir
EOF

  run "$SHELLKIN_REPO_ROOT/shellkin" "$TEST_ROOT/custom_features"

  [ "$status" -eq 1 ]
  assert_output_contains "prepare_temp_dir: command not found"
}

@test "shellkin --load fails when the file does not exist" {
  write_file features/sample.feature <<'EOF'
Feature: Missing load file

Scenario: Example
  Given anything
EOF

  write_file features/step_definitions/core.sh <<'EOF'
@Given anything
true
EOF

  run "$SHELLKIN_REPO_ROOT/shellkin" --load missing.sh "$TEST_ROOT/features"

  [ "$status" -eq 1 ]
  assert_output_contains "load file not found:"
  assert_output_contains "$TEST_ROOT/features/missing.sh"
}
