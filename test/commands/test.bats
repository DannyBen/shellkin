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

@test "shellkin accepts feature and scenario tags" {
  write_file features/sample.feature <<'EOF'
@filesystem
Feature: Create a file

@smoke @needs-server
Scenario: Touch a file
  Then I write 'tagged'
EOF

  write_file features/step_definitions/core.sh <<'EOF'
@Then I write '{text}'
printf '%s' "$text" > "$TEST_ROOT/result.txt"
EOF

  run "$SHELLKIN_REPO_ROOT/shellkin" "$TEST_ROOT/features"

  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_ROOT/result.txt")" = "tagged" ]
  assert_output_contains "Feature: Create a file"
  assert_output_contains "Scenario 1: Touch a file"
  assert_output_contains "1 scenario, 0 failing"
}

@test "shellkin filters scenarios by included and excluded tags" {
  write_file features/sample.feature <<'EOF'
Feature: Tagged scenarios

@slow
Scenario: Slow
  Then I write 'slow'

@smoke
Scenario: Smoke
  Then I write 'smoke'

@unit
Scenario: Unit
  Then I write 'unit'
EOF

  write_file features/step_definitions/core.sh <<'EOF'
@Then I write '{text}'
printf '%s\n' "$text" >> "$TEST_ROOT/result.txt"
EOF

  run "$SHELLKIN_REPO_ROOT/shellkin" -t @smoke -t @unit -x @slow "$TEST_ROOT/features"

  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_ROOT/result.txt")" = $'smoke\nunit' ]
  [[ "$output" != *"Scenario 1: Slow"* ]]
  assert_output_contains "Scenario 2: Smoke"
  assert_output_contains "Scenario 3: Unit"
  assert_output_contains "2 scenarios, 0 failing"
}

@test "shellkin tag filters include inherited feature tags" {
  write_file features/sample.feature <<'EOF'
@filesystem
Feature: Tagged feature

@slow
Scenario: Slow
  Then I write 'slow'

Scenario: Normal
  Then I write 'normal'
EOF

  write_file features/step_definitions/core.sh <<'EOF'
@Then I write '{text}'
printf '%s\n' "$text" >> "$TEST_ROOT/result.txt"
EOF

  run "$SHELLKIN_REPO_ROOT/shellkin" --tag @filesystem --exclude-tag @slow "$TEST_ROOT/features"

  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_ROOT/result.txt")" = "normal" ]
  [[ "$output" != *"Scenario 1: Slow"* ]]
  assert_output_contains "Scenario 2: Normal"
  assert_output_contains "1 scenario, 0 failing"
}

@test "shellkin runs all hooks around tag-filtered scenarios" {
  write_file features/sample.feature <<'EOF'
Feature: Tagged all hooks

@selected
Scenario: First
  Then I write 'first'

Scenario: Skipped
  Then I write 'skipped'

@selected
Scenario: Second
  Then I write 'second'
EOF

  write_file features/step_definitions/core.sh <<'EOF'
@BeforeAll
printf 'before-all\n' >> "$TEST_ROOT/result.txt"

@Before
printf 'before\n' >> "$TEST_ROOT/result.txt"

@After
printf 'after\n' >> "$TEST_ROOT/result.txt"

@AfterAll
printf 'after-all\n' >> "$TEST_ROOT/result.txt"

@Then I write '{text}'
printf 'step:%s\n' "$text" >> "$TEST_ROOT/result.txt"
EOF

  run "$SHELLKIN_REPO_ROOT/shellkin" -t @selected "$TEST_ROOT/features"

  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_ROOT/result.txt")" = $'before-all\nbefore\nstep:first\nafter\nbefore\nstep:second\nafter\nafter-all' ]
  assert_output_contains "Scenario 1: First"
  [[ "$output" != *"Scenario 2: Skipped"* ]]
  assert_output_contains "Scenario 3: Second"
  assert_output_contains "2 scenarios, 0 failing"
}

@test "shellkin does not run all hooks when tag filters select no scenarios" {
  write_file features/sample.feature <<'EOF'
Feature: Unmatched all hooks

@selected
Scenario: Example
  Then I write 'selected'
EOF

  write_file features/step_definitions/core.sh <<'EOF'
@BeforeAll
printf 'before-all\n' >> "$TEST_ROOT/result.txt"

@AfterAll
printf 'after-all\n' >> "$TEST_ROOT/result.txt"

@Then I write '{text}'
printf 'step:%s\n' "$text" >> "$TEST_ROOT/result.txt"
EOF

  run "$SHELLKIN_REPO_ROOT/shellkin" -t @missing "$TEST_ROOT/features"

  [ "$status" -eq 0 ]
  [ ! -e "$TEST_ROOT/result.txt" ]
  assert_output_contains "0 scenarios, 0 failing"
}

@test "shellkin rejects invalid CLI tag filters" {
  write_file features/sample.feature <<'EOF'
Feature: Tagged feature

Scenario: Example
  Then I pass
EOF

  write_file features/step_definitions/core.sh <<'EOF'
@Then I pass
true
EOF

  run "$SHELLKIN_REPO_ROOT/shellkin" -t smoke "$TEST_ROOT/features"

  [ "$status" -eq 1 ]
  assert_output_contains "validation error in TAGS:"
  assert_output_contains "invalid tag: smoke"
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

@test "shellkin runs all hooks around the selected scenario number" {
  write_file features/sample.feature <<'EOF'
Feature: All hooks with scenario number

Scenario: First
  Then I write 'first'

Scenario: Second
  Then I write 'second'
EOF

  write_file features/step_definitions/core.sh <<'EOF'
@BeforeAll
printf 'before-all\n' >> "$TEST_ROOT/result.txt"

@Before
printf 'before\n' >> "$TEST_ROOT/result.txt"

@After
printf 'after\n' >> "$TEST_ROOT/result.txt"

@AfterAll
printf 'after-all\n' >> "$TEST_ROOT/result.txt"

@Then I write '{text}'
printf 'step:%s\n' "$text" >> "$TEST_ROOT/result.txt"
EOF

  run "$SHELLKIN_REPO_ROOT/shellkin" "$TEST_ROOT/features/sample.feature:2"

  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_ROOT/result.txt")" = $'before-all\nbefore\nstep:second\nafter\nafter-all' ]
  [[ "$output" != *"Scenario 1: First"* ]]
  assert_output_contains "Scenario 2: Second"
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

@test "shellkin aborts when BeforeAll fails and skips AfterAll" {
  write_file features/sample.feature <<'EOF'
Feature: Failing BeforeAll

Scenario: First
  Then I pass

Scenario: Second
  Then I pass
EOF

  write_file features/step_definitions/core.sh <<'EOF'
@BeforeAll
fail "suite setup failed"

@AfterAll
printf 'after-all\n' >> "$TEST_ROOT/result.txt"

@Then I pass
true
EOF

  run "$SHELLKIN_REPO_ROOT/shellkin" "$TEST_ROOT/features"

  [ "$status" -eq 1 ]
  [ ! -e "$TEST_ROOT/result.txt" ]
  assert_output_contains "Scenario 1: First"
  [[ "$output" != *"Scenario 2: Second"* ]]
  assert_output_contains "✗ @BeforeAll"
  assert_output_contains "FAIL_MESSAGE: suite setup failed"
  assert_output_contains "1 scenario, 0 passing, 1 failing"
}

@test "shellkin fails when AfterAll fails" {
  write_file features/sample.feature <<'EOF'
Feature: Failing AfterAll

Scenario: First
  Then I pass
EOF

  write_file features/step_definitions/core.sh <<'EOF'
@AfterAll
fail "suite teardown failed"

@Then I pass
true
EOF

  run "$SHELLKIN_REPO_ROOT/shellkin" "$TEST_ROOT/features"

  [ "$status" -eq 1 ]
  assert_output_contains "Scenario 1: First"
  assert_output_contains "✓ Then I pass"
  assert_output_contains "✗ @AfterAll"
  assert_output_contains "FAIL_MESSAGE: suite teardown failed"
  assert_output_contains "1 scenario, 0 passing, 1 failing"
}
