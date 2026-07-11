#!/usr/bin/env bats

setup() {
  load '../../test_helper'
  setup_test_environment
  source_libs core/trim feature/syntax feature/table feature/parse feature/core
}

teardown() {
  teardown_test_environment
}

@test "feature_parse emits flat runnable scenarios" {
  write_file test.feature <<'EOF'
@feature
Feature: Parsed feature

Background:
  Given shared setup

@first
Scenario: First
  When first action

Scenario: Second
  Then second result
EOF

  feature_parse "$TEST_ROOT/test.feature"

  [ "$FEATURE_NAME" = "Parsed feature" ]
  [ "${FEATURE_PARSED_SCENARIO_NAMES[*]}" = "First Second" ]
  [ "${FEATURE_PARSED_SCENARIO_TAGS[0]}" = "@feature @first" ]
  [ "${FEATURE_PARSED_SCENARIO_TAGS[1]}" = "@feature" ]
  [ "${FEATURE_PARSED_SCENARIO_STEP_STARTS[*]}" = "0 2" ]
  [ "${FEATURE_PARSED_SCENARIO_STEP_COUNTS[*]}" = "2 2" ]
  [ "${FEATURE_PARSED_STEPS[0]}" = $'Given\tshared setup' ]
  [ "${FEATURE_PARSED_STEPS[1]}" = $'When\tfirst action' ]
  [ "${FEATURE_PARSED_STEPS[2]}" = $'Given\tshared setup' ]
  [ "${FEATURE_PARSED_STEPS[3]}" = $'Then\tsecond result' ]
  [ "${FEATURE_PARSED_STEP_LINES[*]}" = "5 9 5 12" ]
}

@test "feature_parse preserves attached doc strings and data tables" {
  write_file test.feature <<'EOF'
Feature: Step arguments

Scenario: Arguments
  Given these users exist
    | name  | role  |
    | Alice | admin |
  Then the output should match
    """
    hello
    world
    """
EOF

  feature_parse "$TEST_ROOT/test.feature"

  [ "${FEATURE_PARSED_SCENARIO_STEP_COUNTS[0]}" -eq 2 ]
  [[ ${FEATURE_PARSED_STEPS[0]} == *$'\x1e| name  | role  |'* ]]
  [[ ${FEATURE_PARSED_STEPS[1]} == *$'\thello\nworld' ]]
}
