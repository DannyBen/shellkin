@When I run '{command}'
PATH="$SHELLKIN_ROOT:$PATH" run "$command"

@Then the output should include '{text}'
[[ "$LAST_STDOUT" == *"$text"* ]]
