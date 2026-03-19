#!/usr/bin/env bats

load ../../test_helper.bash

setup() {
  setup_test_environment
  source_libs core/trim syntax/feature
}

teardown() {
  unset_functions trim feature_line_parse feature_step_type_resolve
  teardown_test_environment
}

@test "feature_line_parse recognizes a feature header" {
  feature_line_parse "Feature: Hello World"

  [ "$FEATURE_LINE_KIND" = "feature" ]
  [ "$FEATURE_LINE_NAME" = "Hello World" ]
}

@test "feature_line_parse recognizes a scenario header" {
  feature_line_parse "Scenario: Create a file"

  [ "$FEATURE_LINE_KIND" = "scenario" ]
  [ "$FEATURE_LINE_NAME" = "Create a file" ]
}

@test "feature_line_parse recognizes a step line" {
  feature_line_parse "When I run 'touch somefile'"

  [ "$FEATURE_LINE_KIND" = "step" ]
  [ "$FEATURE_STEP_TYPE" = "When" ]
  [ "$FEATURE_STEP_TEXT" = "I run 'touch somefile'" ]
}

@test "feature_line_parse classifies blank lines" {
  feature_line_parse ""

  [ "$FEATURE_LINE_KIND" = "blank" ]

@test "feature_line_parse classifies comment lines" {
  feature_line_parse "# comment"

  [ "$FEATURE_LINE_KIND" = "comment" ]
}

@test "feature_line_parse leaves unsupported text as other" {
  feature_line_parse "plain descriptive text"

  [ "$FEATURE_LINE_KIND" = "other" ]
  [ "$FEATURE_LINE_NAME" = "plain descriptive text" ]
}

@test "feature_step_type_resolve keeps concrete step types" {
  run feature_step_type_resolve When Then

  [ "$status" -eq 0 ]
  [ "$output" = "Then" ]
}

@test "feature_step_type_resolve reuses the previous type for And and But" {
  run feature_step_type_resolve Then And
  [ "$status" -eq 0 ]
  [ "$output" = "Then" ]

  run feature_step_type_resolve When But
  [ "$status" -eq 0 ]
  [ "$output" = "When" ]
}

@test "feature_step_type_resolve rejects And and But as the first step" {
  run feature_step_type_resolve "" And

  [ "$status" -eq 1 ]
}
