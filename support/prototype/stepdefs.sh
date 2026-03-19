@Step "I am in a temp directory"
mkdir -p ./tmp
chdir tmp

@Step "I run '*'" command
must_run "$command"

@Step "I try '*'" command
run "$command"

@Step "the file '*' should exist" file
[[ -f "$file" ]]

@Step "the exit code should be *" code
[[ "$LAST_EXIT_CODE" -eq "$code" ]]
