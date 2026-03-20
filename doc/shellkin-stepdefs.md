% shellkin-stepdefs(5) shellkin-stepdefs(5) | File Formats Manual
% Danny Ben Shitrit \<https://github.com/dannyben\>
% March 2026

NAME
==================================================

**shellkin-stepdefs** - step definitions file for shellkin

DESCRIPTION
==================================================

Shellkin step definitions are shell code files loaded from the configured step
definitions directory under the selected features root.

Each step definition starts with a header line beginning with one of:

- **@Given**
- **@When**
- **@Then**

The lines that follow are the body of the step definition and are executed when
the step matches.

FORMAT
==================================================

Step Header
--------------------------------------------------

A step definition header declares the Gherkin step type and the pattern to
match.

```bash
@When I run '{command}'
```

Step Body
--------------------------------------------------

The step body is plain shell code.

```bash
@When I run '{command}'
run "$command"
```

Each definition continues until the next valid step header or the end of the
file.

Tokens
--------------------------------------------------

Patterns may contain named tokens in braces.

```bash
@Then the file '{path}' should exist
[[ -f "$path" ]]
```

When the step matches, each token is exported as a shell variable for use in
the body.

Token names must start with a letter or underscore, and may contain letters,
numbers, and underscores.

HELPERS
==================================================

run
--------------------------------------------------

Run a shell command and capture its result for later assertions.

```bash
@When I run '{command}'
run "$command"
```

The **run** helper always returns success, even when the command fails.

fail
--------------------------------------------------

Fail the current step with an optional custom message.

```bash
@Then the output should include '{text}'
[[ "$LAST_STDOUT" == *"$text"* ]] || fail "invalid output detected"
```

ENVIRONMENT
==================================================

Shellkin exposes these variables to step definition bodies:

- **FAIL_MESSAGE** - message supplied by the most recent **fail** call
- **LAST_EXIT_CODE** - exit status captured by the most recent **run** call
- **LAST_STDOUT** - standard output captured by the most recent **run** call
- **LAST_STDERR** - standard error captured by the most recent **run** call
- **DOC_STRING** - doc string attached to the current step, if any

DOC STRINGS
==================================================

If a feature step is followed by a Gherkin doc string, its content is exposed
to the step body through **DOC_STRING**.

```gherkin
Then the output should match
  """
  hello
  world
  """
```

```bash
@Then the output should match
[[ "$LAST_STDOUT" == "$DOC_STRING" ]]
```

EXAMPLE
==================================================

```bash
@Given I am in a temp directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

@When I run '{command}'
run "$command"

@Then the file '{path}' should exist
[[ -f "$path" ]]
```

SEE ALSO
==================================================

**shellkin**(1), **shellkin-test**(1), **shellkin-feature**(5)


SOURCE CODE
==================================================

https://github.com/dannyben/shellkin


ISSUE TRACKER
==================================================

https://github.com/dannyben/shellkin/issues
