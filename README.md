# Shellkin

![repocard](https://repocard.dannyben.com/svg/shellkin.svg)

Shellkin is a Gherkin-style test framework for Bash scripts.

It lets you write feature files such as:

```gherkin
Feature: --help
  Show help message

Scenario: Run --help
  When I run 'shellkin --help'
  Then the output should include 'shellkin COMMAND'
```

and back them with shell step definitions:

```bash
@When I run '{command}'
run "$command"

@Then the output should include '{text}'
[[ "$LAST_STDOUT" == *"$text"* ]]
```

## Status

Shellkin is currently usable for local feature testing and dogfoods itself
through the repository `features/` directory.

Implemented pieces include:

- feature discovery from a directory or a single `.feature` file
- step definition loading from `step_definitions/*.sh` and `*.bash`
- step matching with `{token}` placeholders
- `Background`, `Scenario`, `Given` / `When` / `Then`, and `And` / `But`
- doc strings via Gherkin-style `"""` blocks exposed as `DOC_STRING`
- basic terminal output and scenario summary

## Usage

Run all repo features:

```bash
shellkin test
```

Run a specific directory:

```bash
shellkin test path/to/features
```

Run a single feature file:

```bash
shellkin test path/to/features/example.feature
```

## Project Layout

Shellkin expects this structure:

```text
features/
├── step_definitions/
│   └── core.sh
└── example.feature
```

- Feature files live in the target directory.
- Step definitions live in `step_definitions/` under that same directory.

## Development

This is a Bashly project.

Regenerate the CLI with:

```bash
bashly generate
```

The repository includes Bats tests for the library layers and command-level
behavior.

See [op.conf](op.conf) for additional development commands.
