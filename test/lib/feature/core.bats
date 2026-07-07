#!/usr/bin/env bats

load ../../test_helper.bash

setup() {
  setup_test_environment
  eval "$(declare -f run | sed '1s/^run /bats_run /')"
  source_libs core/colors core/trim stepdef/pattern stepdef/parse feature/syntax stepdef/files user_helpers/run user_helpers/fail user_helpers/defer step/core output/test feature/core

  STEPDEF_TYPES=()
  STEPDEF_PATTERNS=()
  STEPDEF_REGEXES=()
  STEPDEF_TOKENS_LIST=()
  STEPDEF_CAPTURE_INDEXES_LIST=()
  STEPDEF_BODIES=()
  FAIL_MESSAGE=
  LAST_EXIT_CODE=
  LAST_STDOUT=
  LAST_STDERR=
  FEATURE_NAME=
  FEATURE_PREVIOUS_STEP_TYPE=
  FEATURE_RECORDED_STEP_KEYWORD=
  FEATURE_RECORDED_STEP_TEXT=
  FEATURE_RECORDED_STEP_DOC_STRING=
  SCENARIO_DEFERRED_COMMANDS=()
  TEST_SCENARIOS_TOTAL=0
  TEST_SCENARIOS_FAILED=0
  TEST_FAIL_FAST=0
  TEST_ABORT_RUN=0

  cd "$TEST_ROOT"
}

teardown() {
  teardown_test_environment
}

@test "feature_recorded_step_run executes a recorded step and updates the previous type" {
  stepdef_parse "@When I run '{command}'"
  stepdef_register 'run "$command"'

  feature_recorded_step_run $'When\tI run '\''printf hello'\''' ""

  [ "$FEATURE_PREVIOUS_STEP_TYPE" = "When" ]
  [ "$LAST_STDOUT" = "hello" ]
}

@test "feature_scenario_run executes background and scenario steps in order" {
  stepdef_parse "@Given I am in a temp directory"
  stepdef_register 'TEMP_DIR=$(mktemp -d); cd "$TEMP_DIR"'
  stepdef_parse "@When I run '{command}'"
  stepdef_register 'run "$command"'
  stepdef_parse "@Then the file '{path}' should exist"
  stepdef_register '[[ -f "$path" ]]'

  background_steps=($'Given\tI am in a temp directory')
  scenario_steps=($'When\tI run '\''touch somefile'\''' $'Then\tthe file '\''somefile'\'' should exist')

  feature_scenario_run "Example" background_steps scenario_steps

  [ -f "$TEMP_DIR/somefile" ]
}

@test "feature_scenario_run skips the remaining steps after a failure" {
  stepdef_parse "@Given I fail setup"
  stepdef_register 'return 1'
  stepdef_parse "@When I run '{command}'"
  stepdef_register 'run "$command"'
  stepdef_parse "@Then the file '{path}' should exist"
  stepdef_register '[[ -f "$path" ]]'

  background_steps=($'Given\tI fail setup')
  scenario_steps=($'When\tI run '\''touch somefile'\''' $'Then\tthe file '\''somefile'\'' should exist')

  if feature_scenario_run "Example" background_steps scenario_steps >"$TEST_ROOT/output.txt"; then
    status=0
  else
    status=$?
  fi

  [ "$status" -eq 1 ]
  [ ! -f "$TEST_ROOT/somefile" ]
  output=$(strip_ansi <"$TEST_ROOT/output.txt")
  assert_output_contains "- When I run 'touch somefile' (skipped)"
  assert_output_contains "- Then the file 'somefile' should exist (skipped)"
}

@test "feature_scenario_run runs deferred cleanup after a passing scenario" {
  stepdef_parse "@Given I am in a temp directory"
  stepdef_register $'TEMP_DIR=$(mktemp -d)\ndefer "rm -rf \\"$TEMP_DIR\\""\ncd "$TEMP_DIR"'
  stepdef_parse "@Then the file '{path}' should exist"
  stepdef_register 'touch "$path"; [[ -f "$path" ]]'

  background_steps=()
  scenario_steps=($'Given\tI am in a temp directory' $'Then\tthe file '\''somefile'\'' should exist')

  feature_scenario_run "Example" background_steps scenario_steps

  [ ! -e "$TEMP_DIR" ]
}

@test "feature_scenario_run runs deferred cleanup after a failing scenario" {
  stepdef_parse "@Given I am in a temp directory"
  stepdef_register $'TEMP_DIR=$(mktemp -d)\ndefer "rm -rf \\"$TEMP_DIR\\""\ncd "$TEMP_DIR"'
  stepdef_parse "@When I fail"
  stepdef_register 'return 1'

  background_steps=()
  scenario_steps=($'Given\tI am in a temp directory' $'When\tI fail')

  if feature_scenario_run "Example" background_steps scenario_steps; then
    status=0
  else
    status=$?
  fi

  [ "$status" -eq 1 ]
  [ ! -e "$TEMP_DIR" ]
}

@test "feature_run executes a scenario using loaded step definitions" {
  write_file stepdefs.sh <<'EOF'
@Given I am in a temp directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

@When I run '{command}'
run "$command"

@Then the file '{path}' should exist
[[ -f "$path" ]]
EOF

  write_file test.feature <<'EOF'
Feature: Create a file
  A simple feature

Scenario: Touch a file
  Given I am in a temp directory
  When I run 'touch somefile'
  Then the file 'somefile' should exist
EOF

  stepdefs_file_parse "$TEST_ROOT/stepdefs.sh"
  feature_run "$TEST_ROOT/test.feature" >"$TEST_ROOT/output.txt"

  [ "$FEATURE_NAME" = "Create a file" ]
  [ -f "$TEMP_DIR/somefile" ]
  [ "$LAST_EXIT_CODE" -eq 0 ]
  output=$(<"$TEST_ROOT/output.txt")
  assert_output_contains "Feature: Create a file"
  assert_output_contains "Scenario 1: Touch a file"
}

@test "feature_run executes background steps before each scenario" {
  write_file stepdefs.sh <<'EOF'
@Given I am in a temp directory
if [[ -z "${TEMP_DIR:-}" ]]; then
  TEMP_DIR=$(mktemp -d)
fi
cd "$TEMP_DIR"

@When I run '{command}'
run "$command"

@Then the file '{path}' should exist
[[ -f "$path" ]]
EOF

  write_file test.feature <<'EOF'
Feature: Background support

Background:
  Given I am in a temp directory

Scenario: First
  When I run 'touch first-file'
  Then the file 'first-file' should exist

Scenario: Second
  When I run 'touch second-file'
  Then the file 'second-file' should exist
EOF

  stepdefs_file_parse "$TEST_ROOT/stepdefs.sh"
  feature_run "$TEST_ROOT/test.feature" >"$TEST_ROOT/output.txt"

  [ -f "$TEMP_DIR/first-file" ]
  [ -f "$TEMP_DIR/second-file" ]
}

@test "feature_run returns non-zero when And is the first step" {
  write_file test.feature <<'EOF'
Feature: Invalid chaining

Scenario: Bad first step
  And I run 'touch somefile'
EOF

  bats_run feature_run "$TEST_ROOT/test.feature"

  [ "$status" -eq 1 ]
}

@test "feature_doc_string_apply attaches a doc string to the previous scenario step" {
  background_steps=()
  scenario_steps=($'Then\tthe output should match')

  feature_doc_string_apply $'first line\nsecond line' scenario background_steps scenario_steps

  [ "${scenario_steps[0]}" = $'Then\tthe output should match\tfirst line\nsecond line' ]
}

@test "feature_recorded_step_run exposes an attached doc string through DOC_STRING" {
  stepdef_parse "@Then the output should match"
  stepdef_register 'printf "%s" "$DOC_STRING" > "$TEST_ROOT/doc_string.txt"'

  feature_recorded_step_run $'Then\tthe output should match\tfirst line\nsecond line' ""

  [ "$(cat "$TEST_ROOT/doc_string.txt")" = $'first line\nsecond line' ]
}

@test "output_error_report_field indents multiline values inside the report frame" {
  output_error_report_field "LAST_STDOUT" $'first line\nsecond line' >"$TEST_ROOT/output.txt"

  output=$(strip_ansi <"$TEST_ROOT/output.txt")
  [ "$output" = $'  │ LAST_STDOUT:\n  │\n  │   first line\n  │   second line' ]
}

@test "feature_run prints failure context for failed steps" {
  write_file stepdefs.sh <<'EOF'
@When I run '{command}'
run "$command"

@Then the command should fail with a message
fail "invalid output detected"
EOF

  write_file test.feature <<'EOF'
Feature: Failure output

Scenario: Show context
  When I run 'printf hello; printf boom >&2; exit 7'
  Then the command should fail with a message
EOF

  stepdefs_file_parse "$TEST_ROOT/stepdefs.sh"
  if feature_run "$TEST_ROOT/test.feature" >"$TEST_ROOT/output.txt"; then
    status=0
  else
    status=$?
  fi

  [ "$status" -eq 1 ]
  output=$(strip_ansi <"$TEST_ROOT/output.txt")
  assert_output_contains "Error Report"
  assert_output_contains "File: test.feature"
  assert_output_contains "Step: Then the command should fail with a message"
  assert_output_contains "FAIL_MESSAGE: invalid output detected"
  assert_output_contains "invalid output detected"
  assert_output_contains "LAST_EXIT_CODE: 7"
  assert_output_contains "7"
  assert_output_contains "LAST_STDOUT:"
  assert_output_contains "hello"
  assert_output_contains "LAST_STDERR: boom"
  assert_output_contains "boom"
}

@test "feature_run prints a missing step definition message for an unmatched step" {
  write_file stepdefs.sh <<'EOF'
@When I run '{command}'
run "$command"
EOF

  write_file test.feature <<'EOF'
Feature: Missing step definition

Scenario: Show unmatched step
  When I run 'printf hello'
  Then I do not exist
EOF

  stepdefs_file_parse "$TEST_ROOT/stepdefs.sh"
  if feature_run "$TEST_ROOT/test.feature" >"$TEST_ROOT/output.txt"; then
    status=0
  else
    status=$?
  fi

  [ "$status" -eq 1 ]
  output=$(strip_ansi <"$TEST_ROOT/output.txt")
  assert_output_contains "Error Report"
  assert_output_contains "File: test.feature"
  assert_output_contains "Step: Then I do not exist"
  assert_output_contains "FAIL_MESSAGE:"
  assert_output_contains "No matching step definition for:"
  assert_output_contains "Then I do not exist"
}

@test "feature_run prints a deferred failure message when cleanup fails" {
  write_file stepdefs.sh <<'EOF'
@Given I register a failing deferred action
defer 'return 1'
EOF

  write_file test.feature <<'EOF'
Feature: Deferred cleanup failure

Scenario: Show deferred failure
  Given I register a failing deferred action
EOF

  stepdefs_file_parse "$TEST_ROOT/stepdefs.sh"
  if feature_run "$TEST_ROOT/test.feature" >"$TEST_ROOT/output.txt"; then
    status=0
  else
    status=$?
  fi

  [ "$status" -eq 1 ]
  output=$(strip_ansi <"$TEST_ROOT/output.txt")
  assert_output_contains "✗ Deferred cleanup"
  assert_output_contains "Error Report"
  assert_output_contains "File: test.feature"
  assert_output_contains "Step: Deferred cleanup"
  assert_output_contains "FAIL_MESSAGE:"
  assert_output_contains "deferred action failed: return 1"
}

@test "feature_run sets abort state when fail-fast is enabled and a scenario fails" {
  write_file stepdefs.sh <<'EOF'
@When I fail
return 1

@Then I would create a file
touch "$TEST_ROOT/should-not-exist"
EOF

  write_file test.feature <<'EOF'
Feature: Fail fast

Scenario: First
  When I fail
  Then I would create a file

Scenario: Second
  When I fail
EOF

  stepdefs_file_parse "$TEST_ROOT/stepdefs.sh"
  TEST_FAIL_FAST=1

  if feature_run "$TEST_ROOT/test.feature" >"$TEST_ROOT/output.txt"; then
    status=0
  else
    status=$?
  fi

  [ "$status" -eq 1 ]
  [ "$TEST_ABORT_RUN" -eq 1 ]
  [ "$TEST_SCENARIOS_TOTAL" -eq 1 ]
  [ ! -e "$TEST_ROOT/should-not-exist" ]
}

@test "feature_run sets abort state when fail-fast is enabled and the final scenario fails at end of file" {
  write_file stepdefs.sh <<'EOF'
@When I fail
return 1
EOF

  write_file test.feature <<'EOF'
Feature: Fail fast at end of file

Scenario: Only
  When I fail
EOF

  stepdefs_file_parse "$TEST_ROOT/stepdefs.sh"
  TEST_FAIL_FAST=1

  if feature_run "$TEST_ROOT/test.feature" >"$TEST_ROOT/output.txt"; then
    status=0
  else
    status=$?
  fi

  [ "$status" -eq 1 ]
  [ "$TEST_ABORT_RUN" -eq 1 ]
  [ "$TEST_SCENARIOS_TOTAL" -eq 1 ]
}
