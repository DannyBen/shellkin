run() {
  local command_string=$1
  local stdout_file
  local stderr_file

  stdout_file=$(mktemp)
  stderr_file=$(mktemp)

  set +e
  bash -lc "$command_string" >"$stdout_file" 2>"$stderr_file"
  LAST_EXIT_CODE=$?
  set -e

  LAST_STDOUT=$(<"$stdout_file")
  LAST_STDERR=$(<"$stderr_file")
  rm -f "$stdout_file" "$stderr_file"

  return 0
}
