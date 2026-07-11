![](support/header.jpg)

# Shellkin

![repocard](https://repocard.dannyben.com/svg/shellkin.svg)

Shellkin is a Gherkin-style BDD test framework for command-line tools and shell
scripts. It is built with [Bashly](https://bashly.dev/) and distributed as a
single Bash script with no runtime dependencies.

It lets you write feature files such as:

```gherkin
Feature: --help
  Show help message

Scenario: Run --help
  When I run 'shellkin --help'
  Then the output should include 'shellkin [TARGET] [OPTIONS]'
```

and back them with shell step definitions:

```bash
@When I run '{command}'
  run "$command"

@Then the output should include '{text}'
  [[ "$LAST_STDOUT" == *"$text"* ]]
```

Indenting the step body is recommended for readability, but optional.

## Install

### Installing using the setup script

This setup script will download the latest shellkin release executable as well
as the man pages.

```bash
curl -Ls get.dannyb.co/shellkin/setup | bash
```

Feel free to inspect the [setup script](setup) before running.


### Installing manually

Download the `shellkin` bash script from the
[latest release](https://github.com/DannyBen/shellkin/releases/latest), place
it in your path and make it executable.

```shell
# download the latest release and place it in /usr/local/bin
wget https://get.dannyb.co/shellkin
sudo install -m 0755 shellkin /usr/local/bin/
```

## Status

Shellkin is currently usable for local feature testing and dogfoods itself
through the repository `features/` directory.

Implemented pieces include:

- feature discovery, validation, filtering, and scenario selection
- English Gherkin features, rules, backgrounds, scenarios, and outlines
- steps, tags, comments, doc strings, and data tables
- step definitions with named placeholders and lifecycle hooks
- optional support script loading
- fail-fast execution, deferred cleanup, and scenario summaries

### Gherkin Feature Support

| Feature                       | Status      |
|:------------------------------|:------------|
| `Feature`                     | Supported   |
| Feature description text      | Supported   |
| `Rule`                        | Supported   |
| `Background`                  | Supported   |
| `Scenario`                    | Supported   |
| `Scenario Outline`            | Supported   |
| `Examples`                    | Supported   |
| `Given`, `When`, `Then`       | Supported   |
| `And` , `But`                 | Supported   |
| `*` step keyword              | Supported   |
| Doc strings (`"""`)           | Supported   |
| Comments (`#`)                | Supported   |
| Tags (`@tag`)                 | Supported   |
| `Before`, `After` hooks       | Supported   |
| `BeforeAll`, `AfterAll` hooks | Supported   |
| Data tables                   | Supported   |

Shellkin intentionally implements a compact English Gherkin dialect. Keyword
aliases and localization, multiple Examples blocks, tags on Examples blocks,
and escaped data-table cells are not currently supported.

Tags can be selected with `--tag` / `-t` and skipped with `--exclude-tag` / `-x`.
`@Before` and `@After` hooks are declared in step definition files and may be
limited to a tag. `@BeforeAll` and `@AfterAll` hooks are untagged and wrap the
selected scenario run.

## Usage

```bash
# Create a starter features directory:
shellkin --init

# Run all repo features:
shellkin

# Validate feature and step definition files without executing steps:
shellkin --validate

# Stop after the first failing scenario:
shellkin --fail-fast

# Run scenarios tagged @smoke:
shellkin -t @smoke

# Skip scenarios tagged @slow:
shellkin -x @slow

# Run a specific directory:
shellkin path/to/features

# Run a single feature file:
shellkin path/to/features/example.feature
```

When a step fails, the remaining steps in that scenario are marked as skipped
and are not executed.

Use `shellkin --validate` to check feature structure and step-definition matching
without running any step bodies.

Use `shellkin --init` to create a starter features directory with an example
feature, step definitions, `support.sh`, and a local README. Pass a target
directory or configure `--default-target` to initialize a directory other than
`features`; use `--stepdefs` to choose the step definition directory name.

## Configuration with `.shellkin`

Shellkin supports configuration from a `.shellkin` argfile in the current
working directory.

This is useful for project-level defaults such as the default target,
step-definitions directory, and support files:

```text
--default-target tests
--stepdefs steps
--load first_support.sh
--load second_support.sh
```

The argfile format is intentionally simple:

- Only lines that start with `-` or `--` are considered
- Non-flag lines are ignored
- Unknown flags are ignored
- A flag value must appear on the same line as the flag
- Matching outer quotes are stripped

## AI Agent Skill

This repository also provides a Codex skill for AI agents that need to write
Shellkin tests in user projects.

### Install in Codex

Use the built-in installer skill.

In Codex chat, use this prompt:

```text
install the skill from https://github.com/DannyBen/shellkin/tree/main/skills/shellkin
(master branch)
```

### Install in Claude Code

Claude Code supports project and user skill locations:

- Project skill: `.claude/skills/shellkin/SKILL.md`
- User skill: `~/.claude/skills/shellkin/SKILL.md`

Copy `skills/shellkin` from this repo into one of those locations.

## Features Directory Layout

Shellkin expects this structure:

```text
features/
├── step_definitions/
│   └── core.sh
├── support.sh
└── example.feature
```

- Feature files live in the target directory.
- Step definitions live in `step_definitions/` under that same directory.
- `support.sh` is loaded automatically when present.
- Additional support files are loaded when passed with `--load`.
- `--stepdefs` and `--load` paths are relative to the features directory.

You can create this structure with:

```bash
shellkin --init
```

## Step Definitions

Step definitions are shell snippets declared in files under
`step_definitions/`.

```bash
@When I run '{command}'
  run "$command"

@Then the output should include '{text}'
  [[ "$LAST_STDOUT" == *"$text"* ]]
```

Each step definition starts with a header line:

```text
@Given ...
@When ...
@Then ...
```

The lines that follow are the step body and are executed when the step
matches.
Indenting the body is recommended for readability, but optional.

Definition headers can use named tokens in braces. When a step matches, each
token becomes an exported shell variable available to the body:

```bash
@Then the file '{path}' should exist
  [[ -f "$path" ]]
```

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

Each definition continues until the next step or hook header or the end of the
file.

## Step Definition Hooks

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
with that tag, including tags inherited from the feature. `@Before` hooks run
before background and scenario steps. `@After` hooks run after the scenario
steps, even when a step or `@Before` hook fails.

`@BeforeAll` runs once before the first selected scenario executes. `@AfterAll`
runs once after the last selected scenario executes. If no scenario is selected,
neither all-hook runs. All-hooks do not accept tags. If `@BeforeAll` fails, the
run aborts immediately and `@AfterAll` does not run. If `@AfterAll` fails, the
run fails.

Hooks can call helper functions from `support.sh`:

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

## Step Helpers

Shellkin currently provides these built-in helpers for step definitions:

### `run`

Use `run` to execute a shell command while capturing its result for later
assertions.

```bash
@When I run '{command}'
  run "$command"
```

`run` always returns success, even if the command fails. Inspect the captured
result through the environment variables described below.

### `fail`

Use `fail` to fail the current step with an optional custom message.

```bash
@Then the output should include '{text}'
  [[ "$LAST_STDOUT" == *"$text"* ]] || fail "invalid output detected"
```

### `defer`

Use `defer` to register cleanup code that should run when the current scenario
finishes.

```bash
@Given I am in a temp directory
  old_pwd=$PWD
  temp_dir=$(mktemp -d)
  cd "$temp_dir"
  defer cd "$old_pwd"
  defer rm -rf "$temp_dir"
```

Deferred actions are scenario-scoped, run after both passing and failing
scenarios, and execute in reverse order of registration.

## Step Environment

Shellkin exposes these variables to step definition bodies:

| Variable         | Meaning                                                |
|:-----------------|:-------------------------------------------------------|
| `LAST_EXIT_CODE` | Exit status captured by the most recent `run` call     |
| `LAST_STDOUT`    | Standard output captured by the most recent `run` call |
| `LAST_STDERR`    | Standard error captured by the most recent `run` call  |
| `DOC_STRING`     | Doc string attached to the current step, if any        |
| `TABLE_HEADER`   | Header cells from the current step's data table array   |
| `TABLE_ROWS`     | Tab-separated data rows from the current step's table   |

Example:

```bash
@Then the output should match
  [[ "$LAST_STDOUT" == "$DOC_STRING" ]]
```

## Examples

For real-world examples, see this repository's [features](features) directory
and the [rush features](https://github.com/DannyBen/rush/tree/master/features).

## Uninstalling

If you used the setup script, you can run this uninstall script:

```shell
curl -Ls get.dannyb.co/shellkin/uninstall | bash
```

## Contributing / Support

If you experience any issue, have a question or a suggestion, or if you wish
to contribute, feel free to [open an issue][issues].

[issues]: https://github.com/DannyBen/shellkin/issues
