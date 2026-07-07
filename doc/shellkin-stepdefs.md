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

If present, **support.sh** in the features directory is sourced before step
definitions are loaded. Additional support scripts can be loaded with repeatable
**--load** entries or through the **.shellkin** argfile. Support script paths are
relative to the selected features root.

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

Indenting the body is recommended for readability, but optional.

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

defer
--------------------------------------------------

Register cleanup code to run when the current scenario finishes.

```bash
@Given I am in a temp directory
  old_pwd=$PWD
  temp_dir=$(mktemp -d)
  cd "$temp_dir"
  defer cd "$old_pwd"
  defer rm -rf "$temp_dir"
```

Deferred actions are scoped to the current scenario. They run after both
passing and failing scenarios, and execute in reverse order of registration.

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
# features/support.sh
temp_workspace() {
  temp_dir=$(mktemp -d)
  cd "$temp_dir"
}
```

```bash
@Given I am in a temp directory
  old_pwd=$PWD
  temp_workspace
  defer cd "$old_pwd"
  defer rm -rf "$temp_dir"

@When I run '{command}'
  run "$command"

@Then the file '{path}' should exist
  [[ -f "$path" ]]
```

SEE ALSO
==================================================

**shellkin**(1), **shellkin-feature**(5)


SOURCE CODE
==================================================

https://github.com/dannyben/shellkin


ISSUE TRACKER
==================================================

https://github.com/dannyben/shellkin/issues
