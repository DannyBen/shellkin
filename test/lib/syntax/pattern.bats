#!/usr/bin/env bats

load ../../test_helper.bash

setup() {
  setup_test_environment
  source_libs syntax/pattern
}

teardown() {
  unset_functions _pattern_escape_literal pattern_regex pattern_tokens
  teardown_test_environment
}

@test "pattern_regex turns each named token into a capture group" {
  run pattern_regex "I run '{command}'"

  [ "$status" -eq 0 ]
  [ "$output" = "I run '(.+)'" ]
}

@test "pattern_regex turns multiple tokens into capture groups" {
  run pattern_regex "I see {value} in {location}"

  [ "$status" -eq 0 ]
  [ "$output" = "I see (.+) in (.+)" ]
}

@test "pattern_regex escapes regex characters in literal text" {
  run pattern_regex "the file (tmp).txt should match"

  [ "$status" -eq 0 ]
  [ "$output" = "the file \\(tmp\\)\\.txt should match" ]
}

@test "pattern_regex escapes regex metacharacters around tokens" {
  run pattern_regex "the file [tmp].txt contains {value}?"

  [ "$status" -eq 0 ]
  [ "$output" = "the file \\[tmp\\]\\.txt contains (.+)\\?" ]
}

@test "pattern_regex leaves plain text as a literal regex" {
  run pattern_regex "I am in a temp directory"

  [ "$status" -eq 0 ]
  [ "$output" = "I am in a temp directory" ]
}

@test "pattern_tokens returns a single token name" {
  run pattern_tokens "I run '{command}'"

  [ "$status" -eq 0 ]
  [ "$output" = "command" ]
}

@test "pattern_tokens returns token names in declaration order" {
  run pattern_tokens "I copy {source} to {destination}"

  [ "$status" -eq 0 ]
  [ "$output" = "source destination" ]
}

@test "pattern_tokens returns an empty string when there are no tokens" {
  run pattern_tokens "I am in a temp directory"

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
