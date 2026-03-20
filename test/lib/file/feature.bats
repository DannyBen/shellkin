#!/usr/bin/env bats

load ../../test_helper.bash

setup() {
  setup_test_environment
  eval "$(declare -f run | sed '1s/^run /bats_run /')"
  source_libs core/colors core/trim syntax/pattern syntax/stepdef syntax/feature file/stepdefs user_helpers/run user_helpers/fail runtime/step output/test file/feature

  STEPDEF_TYPES=()
  STEPDEF_PATTERNS=()
  STEPDEF_REGEXES=()
  STEPDEF_TOKENS_LIST=()
  STEPDEF_BODIES=()
  FAIL_MESSAGE=
  LAST_EXIT_CODE=
  LAST_STDOUT=
  LAST_STDERR=
  FEATURE_NAME=
  FEATURE_PREVIOUS_STEP_TYPE=
  TEST_SCENARIOS_TOTAL=0
  TEST_SCENARIOS_FAILED=0

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
  assert_output_contains "Scenario: Touch a file"
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
  assert_output_contains "FAIL_MESSAGE:"
  assert_output_contains "invalid output detected"
  assert_output_contains "LAST_EXIT_CODE:"
  assert_output_contains "7"
  assert_output_contains "LAST_STDOUT:"
  assert_output_contains "hello"
  assert_output_contains "LAST_STDERR:"
  assert_output_contains "boom"
}
