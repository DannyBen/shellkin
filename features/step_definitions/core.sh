@Given I am in a temp directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

@When I run '{command}'
PATH="$(pwd):$PATH" run "$command"

@Then the file '{path}' should exist
[[ -f "$path" ]]

@Then the output should include '{text}'
[[ "$LAST_STDOUT" == *"$text"* ]]

@Then the output should match
[[ "$LAST_STDOUT" == "$DOC_STRING" ]]

@Then the exit code should mean success
[[ "$LAST_EXIT_CODE" -eq 0 ]]

@Then the exit code should mean failure
[[ "$LAST_EXIT_CODE" -ne 0 ]]
