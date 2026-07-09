@Given I am in a temp directory
  old_pwd="$(pwd)"
  TEMP_DIR=$(mktemp -d)
  cd "$TEMP_DIR"
  defer cd "$old_pwd"

@When I run '{command}'
  PATH="$(pwd):$PATH" run "$command"

@Then the file '{path}' should exist
  [[ -f "$path" ]]

@Then the output should include '{text}'
  [[ "$(printf '%s' "$LAST_STDOUT" | strip_ansi)" == *"$text"* ]]

@Then the output should not include '{text}'
  [[ "$(printf '%s' "$LAST_STDOUT" | strip_ansi)" != *"$text"* ]]

@Then the error output should include '{text}'
  [[ "$(printf '%s' "$LAST_STDERR" | strip_ansi)" == *"$text"* ]]

@Then the output should match
  [[ "$(printf '%s' "$LAST_STDOUT" | strip_ansi)" == "$DOC_STRING" ]]

@Then the exit code should mean success
  [[ "$LAST_EXIT_CODE" -eq 0 ]]

@Then the exit code should mean failure
  [[ "$LAST_EXIT_CODE" -ne 0 ]]
