#!/usr/bin/env bats

load ../../test_helper.bash

setup() {
  setup_test_environment
  source_libs steps/pattern steps/stepdef
}

teardown() {
  unset_functions _pattern_escape_literal pattern_regex pattern_tokens stepdef_parse
  teardown_test_environment
}

@test "stepdef_parse reads the step type and template" {
  stepdef_parse "@When I run '{command}'"

  [ "$STEPDEF_TYPE" = "When" ]
  [ "$STEPDEF_PATTERN" = "I run '{command}'" ]
}

@test "stepdef_parse derives the regex from the template" {
  stepdef_parse "@Then the file '{path}' should exist"

  [ "$STEPDEF_REGEX" = "the file '(.+)' should exist" ]
}

@test "stepdef_parse returns token names in declaration order" {
  stepdef_parse "@When I copy {source} to {destination}"

  [ "$STEPDEF_TOKENS" = "source destination" ]
}

@test "stepdef_parse accepts extra spacing after the type" {
  stepdef_parse "@Given   I am in '{directory}'"

  [ "$STEPDEF_PATTERN" = "I am in '{directory}'" ]
  [ "$STEPDEF_TOKENS" = "directory" ]
}

@test "stepdef_parse returns non-zero for a line that is not a step definition" {
  run stepdef_parse "echo hello"

  [ "$status" -eq 1 ]
}
