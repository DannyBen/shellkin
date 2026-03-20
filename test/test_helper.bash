setup_test_environment() {
  local helper_dir

  helper_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  export SHELLKIN_REPO_ROOT
  SHELLKIN_REPO_ROOT="$(cd "$helper_dir/.." && pwd)"

  export TEST_ROOT
  TEST_ROOT="$(mktemp -d)"

  export HOME="$TEST_ROOT/home"
  mkdir -p "$HOME" "$TEST_ROOT/bin"

  export PATH="$TEST_ROOT/bin:$PATH"

  cat >"$TEST_ROOT/bin/alf" <<'EOF'
#!/usr/bin/env bash
echo stub-alf
EOF
  chmod +x "$TEST_ROOT/bin/alf"
}

teardown_test_environment() {
  rm -rf "$TEST_ROOT"
}

assert_output_contains() {
  local expected="$1"
  [[ "${output-}" == *"$expected"* ]]
}

strip_ansi() {
  sed -E $'s/\x1B\\[[0-9;]*m//g'
}

fixture_path() {
  printf '%s/test/fixtures/%s\n' "$SHELLKIN_REPO_ROOT" "$1"
}

write_file() {
  local path="$1"
  mkdir -p "$(dirname "$TEST_ROOT/$path")"
  cat >"$TEST_ROOT/$path"
}

unset_functions() {
  local fn

  for fn in "$@"; do
    unset -f "$fn" 2>/dev/null || true
  done
}

source_libs() {
  local lib

  for lib in "$@"; do
    # shellcheck disable=SC1090
    source "$SHELLKIN_REPO_ROOT/src/lib/${lib}.sh"
  done
}

source_command() {
  # shellcheck disable=SC1090
  source "$SHELLKIN_REPO_ROOT/src/commands/${1}.sh"
}
