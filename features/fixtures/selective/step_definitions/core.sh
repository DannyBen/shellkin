@Given I am in a temp directory
  TEMP_DIR=$(mktemp -d)
  cd "$TEMP_DIR"

@When I fail deliberately
  false

@Given setup fails
  false

@When I run '{command}'
  PATH="$(pwd):$PATH" run "$command"

@Then the output should include '{text}'
  [[ "$(printf '%s' "$LAST_STDOUT" | strip_ansi)" == *"$text"* ]]

@Then the output should match
  [[ "$(printf '%s' "$LAST_STDOUT" | strip_ansi)" == "$DOC_STRING" ]]

@Then the file '{path}' should exist
  [[ -f "$path" ]]

@Then I announce '{text}'
  printf '%s' "$text"
