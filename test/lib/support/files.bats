#!/usr/bin/env bats

load ../../test_helper.bash

setup() {
  setup_test_environment
  source_libs support/files

  SUPPORT_FILE=
  SUPPORT_ERROR=
  FIRST_VALUE=
  SECOND_VALUE=
}

teardown() {
  teardown_test_environment
}

@test "support_files_source_all succeeds when no support files are provided" {
  run support_files_source_all "$TEST_ROOT/features"

  [ "$status" -eq 0 ]
  [ -z "$SUPPORT_ERROR" ]
}

@test "support_files_source_all sources multiple files in order" {
  write_file features/first.sh <<'EOF'
FIRST_VALUE=hello
EOF

  write_file features/second.sh <<'EOF'
SECOND_VALUE="${FIRST_VALUE} world"
EOF

  support_files_source_all "$TEST_ROOT/features" first.sh second.sh

  [ "$FIRST_VALUE" = "hello" ]
  [ "$SECOND_VALUE" = "hello world" ]
}

@test "support_files_source_all fails when a support path is absolute" {
  if support_files_source_all "$TEST_ROOT/features" /tmp/support.sh; then
    status=0
  else
    status=$?
  fi

  [ "$status" -eq 1 ]
  [ "$SUPPORT_ERROR" = "load path must be relative to the features directory: /tmp/support.sh" ]
}

@test "support_files_source_all fails when a support file does not exist" {
  if support_files_source_all "$TEST_ROOT/features" missing.sh; then
    status=0
  else
    status=$?
  fi

  [ "$status" -eq 1 ]
  [ "$SUPPORT_ERROR" = "load file not found: $TEST_ROOT/features/missing.sh" ]
}
