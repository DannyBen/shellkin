@Given I am in a temp directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

@When I run '{command}'
PATH="$SHELLKIN_ROOT:$PATH" run "$command"

@Then the file '{path}' should exist
[[ -f "$path" ]]

@Then the output should include '{text}'
[[ "$LAST_STDOUT" == *"$text"* ]]
