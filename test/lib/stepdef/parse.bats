#!/usr/bin/env bats

load ../../test_helper.bash

setup() {
  setup_test_environment
  source_libs stepdef/pattern stepdef/parse

  STEPDEF_TYPES=()
  STEPDEF_PATTERNS=()
  STEPDEF_REGEXES=()
  STEPDEF_TOKENS_LIST=()
  STEPDEF_CAPTURE_INDEXES_LIST=()
  STEPDEF_BODIES=()
}

teardown() {
  teardown_test_environment
}

@test "stepdef_type_valid accepts supported step keywords" {
  stepdef_type_valid Given
  stepdef_type_valid When
  stepdef_type_valid Then
}

@test "stepdef_type_valid rejects unsupported step keywords" {
  run stepdef_type_valid However

  [ "$status" -eq 1 ]
}

@test "stepdef_parse reads the step type and template" {
  stepdef_parse "@When I run '{command}'"

  [ "$STEPDEF_TYPE" = "When" ]
  [ "$STEPDEF_PATTERN" = "I run '{command}'" ]
}

@test "stepdef_parse derives the regex from the template" {
  stepdef_parse "@Then the file '{path}' should exist"

  [ "$STEPDEF_REGEX" = "the file (['\"])(.+)\\1 should exist" ]
  [ "$STEPDEF_CAPTURE_INDEXES" = "2" ]
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

@test "stepdef_parse reads a global Before hook" {
  stepdef_parse "@Before"

  [ "$STEPDEF_HEADER_KIND" = "hook" ]
  [ "$STEPDEF_HOOK_TYPE" = "Before" ]
  [ "$STEPDEF_HOOK_TAG" = "" ]
  [ "$STEPDEF_HOOK_HEADER" = "@Before" ]
}

@test "stepdef_parse reads a tagged After hook" {
  stepdef_parse "@After @needs-server"

  [ "$STEPDEF_HEADER_KIND" = "hook" ]
  [ "$STEPDEF_HOOK_TYPE" = "After" ]
  [ "$STEPDEF_HOOK_TAG" = "@needs-server" ]
  [ "$STEPDEF_HOOK_HEADER" = "@After @needs-server" ]
}

@test "stepdef_parse reads an untagged BeforeAll hook" {
  stepdef_parse "@BeforeAll"

  [ "$STEPDEF_HEADER_KIND" = "hook" ]
  [ "$STEPDEF_HOOK_TYPE" = "BeforeAll" ]
  [ "$STEPDEF_HOOK_TAG" = "" ]
  [ "$STEPDEF_HOOK_HEADER" = "@BeforeAll" ]
}

@test "stepdef_parse reads an untagged AfterAll hook" {
  stepdef_parse "@AfterAll"

  [ "$STEPDEF_HEADER_KIND" = "hook" ]
  [ "$STEPDEF_HOOK_TYPE" = "AfterAll" ]
  [ "$STEPDEF_HOOK_TAG" = "" ]
  [ "$STEPDEF_HOOK_HEADER" = "@AfterAll" ]
}

@test "stepdef_parse returns non-zero for a line that is not a step definition" {
  run stepdef_parse "echo hello"

  [ "$status" -eq 1 ]
}

@test "stepdef_parse returns non-zero for an unsupported step type" {
  run stepdef_parse "@However I run '{command}'"

  [ "$status" -eq 1 ]
}

@test "stepdef_parse returns non-zero for the non-standard Step keyword" {
  run stepdef_parse "@Step I run '{command}'"

  [ "$status" -eq 1 ]
}

@test "stepdef_parse returns non-zero for an invalid hook tag" {
  run stepdef_parse "@Before needs-server"

  [ "$status" -eq 1 ]
}

@test "stepdef_parse returns non-zero for a tagged BeforeAll hook" {
  run stepdef_parse "@BeforeAll @needs-server"

  [ "$status" -eq 1 ]
}

@test "stepdef_parse returns non-zero for a tagged AfterAll hook" {
  run stepdef_parse "@AfterAll @needs-server"

  [ "$status" -eq 1 ]
}

@test "stepdef_register stores the parsed definition and body" {
  stepdef_parse "@When I run '{command}'"

  stepdef_register 'run "$command"'

  [ "${STEPDEF_TYPES[0]}" = "When" ]
  [ "${STEPDEF_PATTERNS[0]}" = "I run '{command}'" ]
  [ "${STEPDEF_REGEXES[0]}" = "I run (['\"])(.+)\\1" ]
  [ "${STEPDEF_TOKENS_LIST[0]}" = "command" ]
  [ "${STEPDEF_CAPTURE_INDEXES_LIST[0]}" = "2" ]
  [ "${STEPDEF_BODIES[0]}" = 'run "$command"' ]
}

@test "stepdef_register appends multiple step definitions in order" {
  stepdef_parse "@Given I am in '{directory}'"
  stepdef_register 'chdir "$directory"'

  stepdef_parse "@Then the file '{path}' should exist"
  stepdef_register '[[ -f "$path" ]]'

  [ "${#STEPDEF_TYPES[@]}" -eq 2 ]
  [ "${STEPDEF_TYPES[0]}" = "Given" ]
  [ "${STEPDEF_TYPES[1]}" = "Then" ]
  [ "${STEPDEF_TOKENS_LIST[0]}" = "directory" ]
  [ "${STEPDEF_TOKENS_LIST[1]}" = "path" ]
  [ "${STEPDEF_CAPTURE_INDEXES_LIST[0]}" = "2" ]
  [ "${STEPDEF_CAPTURE_INDEXES_LIST[1]}" = "2" ]
}
