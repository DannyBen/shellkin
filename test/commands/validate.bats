#!/usr/bin/env bats

load ../test_helper.bash

setup() {
  setup_test_environment
}

teardown() {
  teardown_test_environment
}

@test "shellkin --validate succeeds for valid features without executing steps" {
  write_file features/sample.feature <<'EOF'
Feature: Validate only

Scenario: Validate a file
  When I would create a file
EOF

  write_file features/step_definitions/core.sh <<'EOF'
@When I would create a file
touch "$TEST_ROOT/should-not-exist"
EOF

  run "$SHELLKIN_REPO_ROOT/shellkin" --validate "$TEST_ROOT/features"

  [ "$status" -eq 0 ]
  [ ! -e "$TEST_ROOT/should-not-exist" ]
  assert_output_contains "file: sample.feature"
  assert_output_contains "✓ feature"
  assert_output_contains "validation passed: 2 files checked"
}

@test "shellkin --validate fails for an unmatched step" {
  write_file features/sample.feature <<'EOF'
Feature: Validate mismatch

Scenario: Missing definition
  Then I do not exist
EOF

  write_file features/step_definitions/core.sh <<'EOF'
@When I run '{command}'
run "$command"
EOF

  run "$SHELLKIN_REPO_ROOT/shellkin" --validate "$TEST_ROOT/features"

  [ "$status" -eq 1 ]
  assert_output_contains "file: sample.feature"
  assert_output_contains "✗ feature"
  assert_output_contains "line 4: no matching step definition"
  assert_output_contains "Then I do not exist"
}

@test "shellkin --validate fails for invalid feature structure" {
  write_file features/sample.feature <<'EOF'
Feature: Invalid feature

Background:
  Given setup

Scenario: Example
  Background:
EOF

  write_file features/step_definitions/core.sh <<'EOF'
@Given setup
true
EOF

  run "$SHELLKIN_REPO_ROOT/shellkin" --validate "$TEST_ROOT/features"

  [ "$status" -eq 1 ]
  assert_output_contains "line 7: Background must appear after Feature and before the first Scenario"
}

@test "shellkin --validate fails for invalid tag syntax" {
  write_file features/sample.feature <<'EOF'
Feature: Invalid tag

@valid not-a-tag
Scenario: Example
  Given setup
EOF

  write_file features/step_definitions/core.sh <<'EOF'
@Given setup
true
EOF

  run "$SHELLKIN_REPO_ROOT/shellkin" --validate "$TEST_ROOT/features"

  [ "$status" -eq 1 ]
  assert_output_contains "line 3: invalid tag syntax"
  assert_output_contains "@valid not-a-tag"
}

@test "shellkin --validate fails for a tag before Background" {
  write_file features/sample.feature <<'EOF'
Feature: Invalid tag placement

@setup
Background:
  Given setup

Scenario: Example
  Given setup
EOF

  write_file features/step_definitions/core.sh <<'EOF'
@Given setup
true
EOF

  run "$SHELLKIN_REPO_ROOT/shellkin" --validate "$TEST_ROOT/features"

  [ "$status" -eq 1 ]
  assert_output_contains "line 3: tag must appear before Feature or Scenario"
  assert_output_contains "@setup"
}
