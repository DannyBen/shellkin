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
  assert_output_contains "Scenario 1: Touch a file"
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
  assert_output_contains "Scenario 1: First"
  [[ "$output" != *"Scenario 2: Second"* ]]
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
  assert_output_contains "No matching step definition for:"
  assert_output_contains "Then I do not exist"
}

@test "shellkin loads support.sh automatically when present" {
  write_file custom_features/sample.feature <<'EOF'
Feature: Auto-loaded support file

Scenario: Prepared temp directory
  Given I am in a prepared temp directory
  When I run 'touch somefile'
  Then the file 'somefile' should exist
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

@When I run '{command}'
run "$command"

@Then the file '{path}' should exist
[[ -f "$path" ]]
EOF

  run "$SHELLKIN_REPO_ROOT/shellkin" "$TEST_ROOT/custom_features"

  [ "$status" -eq 0 ]
  assert_output_contains "Feature: Auto-loaded support file"
  assert_output_contains "1 scenario, 0 failing"
}

@test "shellkin --init creates a runnable default features directory" {
  cd "$TEST_ROOT"

  run "$SHELLKIN_REPO_ROOT/shellkin" --init

  [ "$status" -eq 0 ]
  assert_output_contains "initialized shellkin features directory: features"
  [ -f "$TEST_ROOT/features/example.feature" ]
  [ -f "$TEST_ROOT/features/support.sh" ]
  [ -f "$TEST_ROOT/features/step_definitions/core.sh" ]
  [ -f "$TEST_ROOT/features/README.md" ]

  run "$SHELLKIN_REPO_ROOT/shellkin"

  [ "$status" -eq 0 ]
  assert_output_contains "Feature: shellkin example"
  assert_output_contains "1 scenario, 0 failing"
}

@test "shellkin --init respects target and --stepdefs" {
  cd "$TEST_ROOT"

  run "$SHELLKIN_REPO_ROOT/shellkin" --init --stepdefs steps specs

  [ "$status" -eq 0 ]
  assert_output_contains "initialized shellkin features directory: specs"
  [ -f "$TEST_ROOT/specs/example.feature" ]
  [ -f "$TEST_ROOT/specs/steps/core.sh" ]

  run "$SHELLKIN_REPO_ROOT/shellkin" --stepdefs steps specs

  [ "$status" -eq 0 ]
  assert_output_contains "1 scenario, 0 failing"
}

@test "shellkin --init uses --default-target when target is omitted" {
  cd "$TEST_ROOT"

  run "$SHELLKIN_REPO_ROOT/shellkin" --init --default-target specs

  [ "$status" -eq 0 ]
  assert_output_contains "initialized shellkin features directory: specs"
  [ -f "$TEST_ROOT/specs/example.feature" ]
  [ -f "$TEST_ROOT/specs/step_definitions/core.sh" ]

  run "$SHELLKIN_REPO_ROOT/shellkin" --default-target specs

  [ "$status" -eq 0 ]
  assert_output_contains "1 scenario, 0 failing"
}

@test "shellkin --init refuses to overwrite existing files" {
  write_file features/example.feature <<'EOF'
Feature: existing
EOF

  cd "$TEST_ROOT"

  run "$SHELLKIN_REPO_ROOT/shellkin" --init

  [ "$status" -eq 1 ]
  assert_output_contains "init error:"
  assert_output_contains "refusing to overwrite existing file: features/example.feature"
}

@test "shellkin --init conflicts with runtime flags" {
  cd "$TEST_ROOT"

  run "$SHELLKIN_REPO_ROOT/shellkin" --init --validate

  [ "$status" -eq 1 ]
  assert_output_contains "conflicting options: --validate cannot be used with --init"
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
  assert_output_contains "load file not found: missing.sh"
}

@test "shellkin runs only the selected scenario number from the default target" {
  write_file features/sample.feature <<'EOF'
Feature: Select by scenario number

Scenario: First
  Then I write 'first'

Scenario: Second
  Then I write 'second'
EOF

  write_file features/step_definitions/core.sh <<'EOF'
@Then I write '{text}'
printf '%s' "$text" > "$TEST_ROOT/result.txt"
EOF

  run "$SHELLKIN_REPO_ROOT/shellkin" --default-target "$TEST_ROOT/features" 2

  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_ROOT/result.txt")" = "second" ]
  assert_output_contains "Scenario 2: Second"
  [[ "$output" != *"Scenario 1: First"* ]]
  assert_output_contains "1 scenario, 0 failing"
}

@test "shellkin omits headings for feature files with no selected scenarios" {
  write_file features/first.feature <<'EOF'
Feature: First feature

Scenario: First
  Then I write 'first'
EOF

  write_file features/second.feature <<'EOF'
Feature: Second feature

Scenario: Second
  Then I write 'second'
EOF

  write_file features/step_definitions/core.sh <<'EOF'
@Then I write '{text}'
printf '%s' "$text" > "$TEST_ROOT/result.txt"
EOF

  run "$SHELLKIN_REPO_ROOT/shellkin" --default-target "$TEST_ROOT/features" 2

  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_ROOT/result.txt")" = "second" ]
  [[ "$output" != *"Feature: First feature"* ]]
  assert_output_contains "Feature: Second feature"
  assert_output_contains "Scenario 2: Second"
  assert_output_contains "1 scenario, 0 failing"
}

@test "shellkin runs only the selected scenario number from an explicit feature target" {
  write_file features/sample.feature <<'EOF'
Feature: Select from file target

Scenario: First
  Then I write 'first'

Scenario: Second
  Then I write 'second'
EOF

  write_file features/step_definitions/core.sh <<'EOF'
@Then I write '{text}'
printf '%s' "$text" > "$TEST_ROOT/result.txt"
EOF

  run "$SHELLKIN_REPO_ROOT/shellkin" "$TEST_ROOT/features/sample.feature:2"

  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_ROOT/result.txt")" = "second" ]
  assert_output_contains "Scenario 2: Second"
  [[ "$output" != *"Scenario 1: First"* ]]
  assert_output_contains "1 scenario, 0 failing"
}

@test "shellkin fails when the selected scenario number is out of range" {
  write_file features/sample.feature <<'EOF'
Feature: Missing scenario number

Scenario: Only
  Then I pass
EOF

  write_file features/step_definitions/core.sh <<'EOF'
@Then I pass
true
EOF

  run "$SHELLKIN_REPO_ROOT/shellkin" --default-target "$TEST_ROOT/features" 9

  [ "$status" -eq 1 ]
  assert_output_contains "validation error in TARGET:"
  assert_output_contains "scenario number out of range: 9"
}
