@When I run '{command}'
  PATH="$(pwd):$PATH" run "$command"

@Then the output should include '{text}'
  [[ "$(printf '%s' "$LAST_STDOUT" | strip_ansi)" == *"$text"* ]]

@Then the output should match
  [[ "$(printf '%s' "$LAST_STDOUT" | strip_ansi)" == "$DOC_STRING" ]]
