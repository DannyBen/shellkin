@When I print configured output
  run 'printf configured'

@When I print loaded support values
  run "printf '%s' \"$SUPPORT_VALUE\""

@Then the output should include '{text}'
  [[ "$(printf '%s' "$LAST_STDOUT" | strip_ansi)" == *"$text"* ]]
