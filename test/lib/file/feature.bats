#!/usr/bin/env bats

load ../../test_helper.bash

setup() {
  setup_test_environment
  eval "$(declare -f run | sed '1s/^run /bats_run /')"
  source_libs core/colors core/trim syntax/pattern syntax/stepdef syntax/feature file/stepdefs user_helpers/run runtime/step output/test file/feature

  STEPDEF_TYPES=()
  STEPDEF_PATTERNS=()
  STEPDEF_REGEXES=()
  STEPDEF_TOKENS_LIST=()
  STEPDEF_BODIES=()
  LAST_EXIT_CODE=
  LAST_STDOUT=
  LAST_STDERR=
  FEATURE_NAME=
  FEATURE_PREVIOUS_STEP_TYPE=

  cd "$TEST_ROOT"
}

teardown() {
  unset_functions enable_auto_colors print_in_color red green yellow blue magenta cyan black white bold underlined bold_underlined red_bold green_bold yellow_bold blue_bold magenta_bold cyan_bold black_bold white_bold red_underlined green_underlined yellow_underlined blue_underlined magenta_underlined cyan_underlined black_underlined white_underlined trim _pattern_escape_literal pattern_regex pattern_tokens stepdef_type_valid stepdef_parse stepdef_register stepdefs_file_parse run step_run output_feature_start output_scenario_start output_step_result feature_line_parse feature_step_type_resolve feature_run feature_recorded_step_run feature_scenario_run
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
