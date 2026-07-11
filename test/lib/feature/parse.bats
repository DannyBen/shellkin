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

@test "feature_parse expands an outline into runnable scenarios" {
  write_file test.feature <<'EOF'
@users
Feature: Outlines

Background:
  Given shared setup

@roles
Scenario Outline: Creating <name>
  Given user '<name>' exists
  Then the user record should match
    """
    <name>:<role>
    """
  And these permissions exist
    | user   | permission |
    | <name> | <role>     |

Examples:
  | name  | role   |
  | Alice | admin  |
  | Bob   | member |
EOF

  feature_parse "$TEST_ROOT/test.feature"

  [ "${FEATURE_PARSED_SCENARIO_NAMES[*]}" = "Creating Alice Creating Bob" ]
  [ "${FEATURE_PARSED_SCENARIO_TAGS[0]}" = "@users @roles" ]
  [ "${FEATURE_PARSED_SCENARIO_TAGS[1]}" = "@users @roles" ]
  [ "${FEATURE_PARSED_SCENARIO_STEP_COUNTS[*]}" = "4 4" ]
  [ "${FEATURE_PARSED_STEPS[0]}" = $'Given\tshared setup' ]
  [ "${FEATURE_PARSED_STEPS[1]}" = $'Given\tuser \'Alice\' exists' ]
  [[ ${FEATURE_PARSED_STEPS[2]} == *$'\tAlice:admin' ]]
  [[ ${FEATURE_PARSED_STEPS[3]} == *'| Alice | admin     |'* ]]
  [ "${FEATURE_PARSED_STEPS[4]}" = $'Given\tshared setup' ]
  [ "${FEATURE_PARSED_STEPS[5]}" = $'Given\tuser \'Bob\' exists' ]
}

@test "feature_parse rejects an outline without Examples" {
  write_file test.feature <<'EOF'
Feature: Outlines

Scenario Outline: Creating <name>
  Given user '<name>' exists
EOF

  if feature_parse "$TEST_ROOT/test.feature"; then
    status=0
  else
    status=$?
  fi

  [ "$status" -eq 1 ]
  [ "$FEATURE_VALIDATION_MESSAGE" = "Scenario Outline must have one Examples block" ]
}

@test "feature_parse rejects missing placeholder columns" {
  write_file test.feature <<'EOF'
Feature: Outlines

Scenario Outline: Creating <name>
  Given user '<name>' has role '<role>'

Examples:
  | name  |
  | Alice |
EOF

  if feature_parse "$TEST_ROOT/test.feature"; then
    status=0
  else
    status=$?
  fi

  [ "$status" -eq 1 ]
  [ "$FEATURE_VALIDATION_MESSAGE" = "no Examples column for placeholder" ]
  [ "$FEATURE_VALIDATION_CONTEXT" = "<role>" ]
}

@test "feature_parse rejects duplicate Examples headings" {
  write_file test.feature <<'EOF'
Feature: Outlines

Scenario Outline: Creating <name>
  Given user '<name>' exists

Examples:
  | name  | name |
  | Alice | admin |
EOF

  if feature_parse "$TEST_ROOT/test.feature"; then
    status=0
  else
    status=$?
  fi

  [ "$status" -eq 1 ]
  [ "$FEATURE_VALIDATION_MESSAGE" = "Examples headings must be unique" ]
}

@test "feature_parse rejects uneven Examples rows" {
  write_file test.feature <<'EOF'
Feature: Outlines

Scenario Outline: Creating <name>
  Given user '<name>' exists

Examples:
  | name  | role |
  | Alice |
EOF

  if feature_parse "$TEST_ROOT/test.feature"; then
    status=0
  else
    status=$?
  fi

  [ "$status" -eq 1 ]
  [ "$FEATURE_VALIDATION_MESSAGE" = "Examples rows must have the same number of cells as the header" ]
}

@test "feature_parse rejects a second Examples block" {
  write_file test.feature <<'EOF'
Feature: Outlines

Scenario Outline: Creating <name>
  Given user '<name>' exists

Examples:
  | name  |
  | Alice |

Examples:
  | name |
  | Bob  |
EOF

  if feature_parse "$TEST_ROOT/test.feature"; then
    status=0
  else
    status=$?
  fi

  [ "$status" -eq 1 ]
  [ "$FEATURE_VALIDATION_MESSAGE" = "Examples must appear once after a Scenario Outline" ]
}
