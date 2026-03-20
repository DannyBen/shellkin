@When I fail deliberately
false

@Given setup fails
false

@When I run '{command}'
PATH="$(pwd):$PATH" run "$command"

@Then the output should include '{text}'
[[ "$LAST_STDOUT" == *"$text"* ]]

@Then the output should match
[[ "$LAST_STDOUT" == "$DOC_STRING" ]]

@Then I announce '{text}'
printf '%s' "$text"
