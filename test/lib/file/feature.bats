#!/usr/bin/env bats

load ../../test_helper.bash

setup() {
  setup_test_environment
  eval "$(declare -f run | sed '1s/^run /bats_run /')"
  source_libs core/trim syntax/pattern syntax/stepdef syntax/feature file/stepdefs runtime/run runtime/step file/feature

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
  unset_functions trim _pattern_escape_literal pattern_regex pattern_tokens stepdef_type_valid stepdef_parse stepdef_register stepdefs_file_parse run step_run feature_line_parse feature_step_type_resolve feature_run feature_recorded_step_run feature_scenario_run
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
  stepdef_register 'mkdir -p "$TEST_ROOT/tmp"; cd "$TEST_ROOT/tmp"'
  stepdef_parse "@When I run '{command}'"
  stepdef_register 'run "$command"'
  stepdef_parse "@Then the file '{path}' should exist"
  stepdef_register '[[ -f "$path" ]]'

  background_steps=($'Given\tI am in a temp directory')
  scenario_steps=($'When\tI run '\''touch somefile'\''' $'Then\tthe file '\''somefile'\'' should exist')

  feature_scenario_run background_steps scenario_steps

  [ -f "$TEST_ROOT/tmp/somefile" ]
}

@test "feature_run executes a scenario using loaded step definitions" {
  write_file stepdefs.sh <<'EOF'
@Given I am in a temp directory
mkdir -p tmp
cd tmp

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
  feature_run "$TEST_ROOT/test.feature"

  [ "$FEATURE_NAME" = "Create a file" ]
  [ -f "$TEST_ROOT/tmp/somefile" ]
  [ "$LAST_EXIT_CODE" -eq 0 ]
}

@test "feature_run executes background steps before each scenario" {
  write_file stepdefs.sh <<'EOF'
@Given I am in a temp directory
mkdir -p "$TEST_ROOT/tmp"
cd "$TEST_ROOT/tmp"

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
  feature_run "$TEST_ROOT/test.feature"

  [ -f "$TEST_ROOT/tmp/first-file" ]
  [ -f "$TEST_ROOT/tmp/second-file" ]
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
