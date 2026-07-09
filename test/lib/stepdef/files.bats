#!/usr/bin/env bats

load ../../test_helper.bash

setup() {
  setup_test_environment
  source_libs core/trim stepdef/pattern stepdef/parse stepdef/hooks stepdef/files

  STEPDEF_TYPES=()
  STEPDEF_PATTERNS=()
  STEPDEF_REGEXES=()
  STEPDEF_TOKENS_LIST=()
  STEPDEF_CAPTURE_INDEXES_LIST=()
  STEPDEF_BODIES=()
  SHELLKIN_BEFORE_HOOK_TAGS=()
  SHELLKIN_BEFORE_HOOK_HEADERS=()
  SHELLKIN_BEFORE_HOOK_BODIES=()
  SHELLKIN_AFTER_HOOK_TAGS=()
  SHELLKIN_AFTER_HOOK_HEADERS=()
  SHELLKIN_AFTER_HOOK_BODIES=()
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
  [ "${STEPDEF_REGEXES[0]}" = "I run (['\"])(.+)\\1" ]
  [ "${STEPDEF_CAPTURE_INDEXES_LIST[0]}" = "2" ]
  [ "${STEPDEF_CAPTURE_INDEXES_LIST[1]}" = "2" ]
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

@test "stepdefs_file_parse registers hook bodies from step definition files" {
  write_file stepdefs.sh <<'EOF'
@Before
setup_each

@Before @needs-server
start_server

@After @needs-server
stop_server

@Then the hook log should include '{text}'
[[ "$HOOK_LOG" == *"$text"* ]]
EOF

  stepdefs_file_parse "$TEST_ROOT/stepdefs.sh"

  [ "${#SHELLKIN_BEFORE_HOOK_BODIES[@]}" -eq 2 ]
  [ "${SHELLKIN_BEFORE_HOOK_HEADERS[0]}" = "@Before" ]
  [ "${SHELLKIN_BEFORE_HOOK_BODIES[0]}" = $'setup_each\n' ]
  [ "${SHELLKIN_BEFORE_HOOK_TAGS[1]}" = "@needs-server" ]
  [ "${SHELLKIN_BEFORE_HOOK_HEADERS[1]}" = "@Before @needs-server" ]
  [ "${SHELLKIN_BEFORE_HOOK_BODIES[1]}" = $'start_server\n' ]
  [ "${SHELLKIN_AFTER_HOOK_HEADERS[0]}" = "@After @needs-server" ]
  [ "${SHELLKIN_AFTER_HOOK_BODIES[0]}" = $'stop_server\n' ]
  [ "${STEPDEF_TYPES[0]}" = "Then" ]
}

@test "stepdefs_file_parse returns non-zero for an invalid step definition header" {
  write_file stepdefs.sh <<'EOF'
@When
run "$command"
EOF

  run stepdefs_file_parse "$TEST_ROOT/stepdefs.sh"

  [ "$status" -eq 1 ]
}

@test "stepdefs_file_parse returns non-zero for an invalid hook header" {
  write_file stepdefs.sh <<'EOF'
@Before needs-server
start_server
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
