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

## Rules And Scoped Backgrounds

```gherkin
@admin
Rule: Administrators can manage users
  Background:
    Given the current role is 'admin'

  Scenario: Deactivate a user
    When I deactivate user 'Alice'
    Then user 'Alice' should be inactive
```

Feature background steps run before rule background steps. Tags on a rule are
inherited by its scenarios.

## Scenario Outline

```gherkin
Scenario Outline: Creating <name> as <role>
  When I register user '<name>' with role '<role>'
  Then user '<name>' should have role '<role>'

Examples:
  | name  | role   |
  | Alice | admin  |
  | Bob   | member |
```

Shellkin supports one `Examples` block per outline. Every placeholder must have
a matching, unique Examples column.

## Data Table

```gherkin
Given these users exist
  | name  | role   |
  | Alice | admin  |
  | Bob   | member |
```

```bash
@Given these users exist
  [[ ${TABLE_HEADER[*]} == "name role" ]] || fail "unexpected columns"
  for row in "${TABLE_ROWS[@]}"; do
    IFS=$'\t' read -r name role <<<"$row"
    create_user "$name" "$role"
  done
```

`TABLE_HEADER` is an array of header cells. `TABLE_ROWS` contains one
tab-separated string per data row.

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

- Unsupported Gherkin forms such as multiple `Examples` blocks, tags on
  `Examples`, localized keywords, or escaped data-table cells
- Outline placeholders without a matching, unique `Examples` column
- Data tables that do not immediately follow a step or have inconsistent row widths
- `And` or `*` used as the first step in a scenario or background
- Step text in features that does not exactly line up with step definition headers
- One-off step definitions that should be generalized with `{tokens}`
- Assertions that ignore `LAST_STDERR` or `LAST_EXIT_CODE` when those are the real behavior
- Missing cleanup after `cd`, temp directories, or created files
- Overuse of `Background` for setup that only some scenarios need
