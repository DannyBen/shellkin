@When I run '{command}'
PATH="$(pwd):$PATH" run "$command"

@Then the output should include '{text}'
[[ "$LAST_STDOUT" == *"$text"* ]]
