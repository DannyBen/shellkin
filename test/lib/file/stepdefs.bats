#!/usr/bin/env bats

load ../../test_helper.bash

setup() {
  setup_test_environment
  source_libs core/trim syntax/pattern syntax/stepdef file/stepdefs

  STEPDEF_TYPES=()
  STEPDEF_PATTERNS=()
  STEPDEF_REGEXES=()
  STEPDEF_TOKENS_LIST=()
  STEPDEF_BODIES=()
}

teardown() {
  teardown_test_environment
}

@test "stepdefs_file_parse registers multiple step definitions from one file" {
  write_file stepdefs.sh <<'EOF'
@When I run '{command}'
run "$command"

@Then the file '{path}' should exist
[[ -f "$path" ]]
EOF

  stepdefs_file_parse "$TEST_ROOT/stepdefs.sh"

  [ "${#STEPDEF_TYPES[@]}" -eq 2 ]
  [ "${STEPDEF_TYPES[0]}" = "When" ]
  [ "${STEPDEF_TYPES[1]}" = "Then" ]
  [ "${STEPDEF_REGEXES[0]}" = "I run '(.+)'" ]
}

@test "stepdefs_file_parse preserves multi-line step bodies" {
  write_file stepdefs.sh <<'EOF'
@Given I am in '{directory}'
mkdir -p "$directory"
cd "$directory"
EOF

  stepdefs_file_parse "$TEST_ROOT/stepdefs.sh"

  [ "${STEPDEF_BODIES[0]}" = $'mkdir -p "$directory"\ncd "$directory"' ]
}

@test "stepdefs_file_parse ignores blank lines before a definition" {
  write_file stepdefs.sh <<'EOF'


@When I run '{command}'
run "$command"
EOF

  stepdefs_file_parse "$TEST_ROOT/stepdefs.sh"

  [ "${#STEPDEF_TYPES[@]}" -eq 1 ]
  [ "${STEPDEF_BODIES[0]}" = 'run "$command"' ]
}

@test "stepdefs_file_parse keeps blank lines inside a step body" {
  write_file stepdefs.sh <<'EOF'
@When I run '{command}'

run "$command"

printf 'done'
EOF

  stepdefs_file_parse "$TEST_ROOT/stepdefs.sh"

  [ "${#STEPDEF_TYPES[@]}" -eq 1 ]
  [[ "${STEPDEF_BODIES[0]}" == *$'\n\n'* ]]
  [[ "${STEPDEF_BODIES[0]}" == *'run "$command"'* ]]
  [[ "${STEPDEF_BODIES[0]}" == *"printf 'done'"* ]]
}

@test "stepdefs_file_parse ends a definition at the next valid header" {
  write_file stepdefs.sh <<'EOF'
@When I run '{command}'
run "$command"

@Then the file '{path}' should exist
[[ -f "$path" ]]
EOF

  stepdefs_file_parse "$TEST_ROOT/stepdefs.sh"

  [ "${#STEPDEF_TYPES[@]}" -eq 2 ]
  [ "${STEPDEF_TYPES[0]}" = "When" ]
  [ "${STEPDEF_TYPES[1]}" = "Then" ]
  [[ "${STEPDEF_BODIES[0]}" == *'run "$command"'* ]]
  [[ "${STEPDEF_BODIES[1]}" == *'[[ -f "$path" ]]'* ]]
}

@test "stepdefs_file_parse returns non-zero for an invalid step definition header" {
  write_file stepdefs.sh <<'EOF'
@When
run "$command"
EOF

  run stepdefs_file_parse "$TEST_ROOT/stepdefs.sh"

  [ "$status" -eq 1 ]
}

@test "stepdefs_file_parse returns non-zero for an unsupported step type" {
  write_file stepdefs.sh <<'EOF'
@However I run '{command}'
run "$command"
EOF

  run stepdefs_file_parse "$TEST_ROOT/stepdefs.sh"

  [ "$status" -eq 1 ]
}
