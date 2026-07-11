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

Each definition continues until the next valid step or hook header or the end
of the file.

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

Quoted tokens accept either quote delimiter when the step runs. For example,
this definition:

```bash
@Then the text should include '{text}'
```

matches both of these steps, and captures the text without the outer quotes:

```gherkin
Then the text should include "Something's wrong"
Then the text should include 'Jim "Jimbo" Jackson'
```

The opening and closing quote in the feature step must match. Quoted token
patterns do not match unquoted values.

HOOKS
==================================================

Step definition files can also declare hooks.

```bash
@BeforeAll
  ./suite-setup

@Before
  mkdir -p tmp

@After
  rm -rf tmp

@Before @needs-server
  ./server start

@After @needs-server
  ./server stop

@AfterAll
  ./suite-teardown
```

Hooks without a tag run for every scenario. Tagged hooks run only for scenarios
with that tag, including tags inherited from the feature.

**@Before** hooks run before background and scenario steps. If a **@Before**
hook fails, the scenario fails and the remaining steps are skipped.

**@After** hooks run after scenario steps, even when a step or **@Before** hook
fails. If an **@After** hook fails, the scenario fails.

**@BeforeAll** runs once before the first selected scenario executes.
**@AfterAll** runs once after the last selected scenario executes. If no
scenario is selected, neither all-hook runs. All-hooks do not accept tags.
If **@BeforeAll** fails, the run aborts immediately and **@AfterAll** does not
run. If **@AfterAll** fails, the run fails.

Passing hooks are quiet. Failing hooks are shown in the error report.

Hooks can call helper functions from **support.sh**:

```bash
# features/support.sh
start_server() {
  ./server start
}

stop_server() {
  ./server stop
}
```

```bash
# features/step_definitions/hooks.sh
@Before @needs-server
  start_server

@After @needs-server
  stop_server
```

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
- **TABLE_HEADER** - header cells from the current step's data table array
- **TABLE_ROWS** - tab-separated data rows from the current step's data table

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

DATA TABLES
==================================================

Data tables are exposed through the **TABLE_HEADER** and **TABLE_ROWS** arrays.
Split each row on tabs to access its cells.

```bash
@Given these users exist
for row in "${TABLE_ROWS[@]}"; do
  IFS=$'\t' read -r name role <<<"$row"
  create_user "$name" "$role"
done
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
