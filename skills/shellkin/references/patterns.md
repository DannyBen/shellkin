# Shellkin Patterns

Use these patterns when authoring or revising tests in a user's project.

## Minimal Feature

```gherkin
Feature: --help
  Show the command help

Scenario: Run --help
  When I run 'mycli --help'
  Then the output should include 'Usage:'
```

## Shared Setup With Background

```gherkin
Feature: init
  Create a starter project

Background:
  Given I am in a temp directory

Scenario: Initialize a new project
  When I run 'mycli init demo'
  Then the file 'demo/config.yml' should exist
```

Use `Background` only when every scenario needs the same setup.

## Doc String Assertion

```gherkin
Scenario: Show multiline output
  When I run 'printf "one\ntwo"'
  Then the output should match
    """
    one
    two
    """
```

```bash
@Then the output should match
  [[ "$LAST_STDOUT" == "$DOC_STRING" ]]
```

## Reusable Command And Exit Steps

```bash
@When I run '{command}'
  run "$command"

@Then the exit code should be '{code}'
  [[ "$LAST_EXIT_CODE" -eq "$code" ]]

@Then the output should include '{text}'
  [[ "$LAST_STDOUT" == *"$text"* ]]

@Then the error output should include '{text}'
  [[ "$LAST_STDERR" == *"$text"* ]]
```

## Temp Directory Setup

```bash
@Given I am in a temp directory
  old_pwd=$PWD
  temp_dir=$(mktemp -d)
  cd "$temp_dir"
  defer cd "$old_pwd"
  defer rm -rf "$temp_dir"
```

Prefer `defer` over open-coded cleanup at the end of a step body.

## Matching Filesystem Effects

```bash
@Then the file '{path}' should exist
  [[ -f "$path" ]]

@Then the directory '{path}' should exist
  [[ -d "$path" ]]
```

Use generic path-oriented steps when possible so they can be reused in many features.

## Practical Review Checklist

When reviewing Shellkin tests, check for:

- Unsupported Gherkin forms such as `Scenario Outline`, `Examples`, hooks, or tables
- `And` or `*` used as the first step in a scenario or background
- Step text in features that does not exactly line up with step definition headers
- One-off step definitions that should be generalized with `{tokens}`
- Assertions that ignore `LAST_STDERR` or `LAST_EXIT_CODE` when those are the real behavior
- Missing cleanup after `cd`, temp directories, or created files
- Overuse of `Background` for setup that only some scenarios need
