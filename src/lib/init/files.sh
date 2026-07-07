## Initializes a Shellkin features directory.
init_files_create() {
  local target_dir=$1
  local stepdefs_subdir=$2
  local stepdefs_dir="$target_dir/$stepdefs_subdir"
  local feature_file="$target_dir/example.feature"
  local support_file="$target_dir/support.sh"
  local stepdefs_file="$stepdefs_dir/core.sh"
  local readme_file="$target_dir/README.md"

  INIT_ERROR=

  init__target_validate "$target_dir" "$stepdefs_dir" || return 1
  init__file_available "$feature_file" || return 1
  init__file_available "$support_file" || return 1
  init__file_available "$stepdefs_file" || return 1
  init__file_available "$readme_file" || return 1

  mkdir -p "$stepdefs_dir"

  init__example_feature_write "$feature_file"
  init__support_file_write "$support_file"
  init__stepdefs_file_write "$stepdefs_file"
  init__readme_file_write "$readme_file" "$target_dir" "$stepdefs_subdir"

  printf 'initialized shellkin features directory: %s\n' "$target_dir"
}

init__target_validate() {
  local target_dir=$1
  local stepdefs_dir=$2

  if [[ -z $target_dir ]]; then
    INIT_ERROR="init target is required"
    return 1
  fi

  if [[ $target_dir == *:* ]]; then
    INIT_ERROR="init target must be a directory, not a scenario selector: $target_dir"
    return 1
  fi

  if [[ $target_dir == *.feature ]]; then
    INIT_ERROR="init target must be a directory, not a feature file: $target_dir"
    return 1
  fi

  if [[ -e $target_dir && ! -d $target_dir ]]; then
    INIT_ERROR="init target exists and is not a directory: $target_dir"
    return 1
  fi

  if [[ -e $stepdefs_dir && ! -d $stepdefs_dir ]]; then
    INIT_ERROR="step definitions path exists and is not a directory: $stepdefs_dir"
    return 1
  fi
}

init__file_available() {
  local path=$1

  if [[ -e $path ]]; then
    INIT_ERROR="refusing to overwrite existing file: $path"
    return 1
  fi
}

init__example_feature_write() {
  local path=$1

  cat >"$path" <<'EOF'
Feature: shellkin example
  A small generated example

Scenario: Run a command
  When I run 'printf hello'
  Then the output should include 'hello'
EOF
}

init__support_file_write() {
  local path=$1

  cat >"$path" <<'EOF'
# Helper functions for Shellkin step definitions.
EOF
}

init__stepdefs_file_write() {
  local path=$1

  cat >"$path" <<'EOF'
@When I run '{command}'
  run "$command"

@Then the output should include '{text}'
  [[ "$LAST_STDOUT" == *"$text"* ]] || fail "expected output to include '$text'"
EOF
}

init__readme_file_write() {
  local path=$1
  local target_dir=$2
  local stepdefs_subdir=$3
  local run_command=shellkin
  local target_arg
  local stepdefs_arg

  if [[ $target_dir != features || $stepdefs_subdir != step_definitions ]]; then
    printf -v target_arg '%q' "$target_dir"
    printf -v stepdefs_arg '%q' "$stepdefs_subdir"
    run_command="shellkin --default-target $target_arg --stepdefs $stepdefs_arg"
  fi

  cat >"$path" <<EOF
# Shellkin Features

- Feature files live in this directory.
- Step definitions live in \`$stepdefs_subdir/\`.
- \`support.sh\` is loaded automatically when present.
- Extra support files can be loaded with repeatable \`--load\` entries.

Run these tests with:

\`\`\`bash
$run_command
\`\`\`
EOF
}
