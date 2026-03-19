@When I run '{command}'
PATH="$SHELLKIN_ROOT:$PATH" run "$command"

@Then the output should include '{text}'
[[ "$LAST_STDOUT" == *"$text"* ]]

@Then the output should match
[[ "$LAST_STDOUT" == "$DOC_STRING" ]]