% shellkin-feature(5) shellkin-feature(5) | File Formats Manual
% Danny Ben Shitrit \<https://github.com/dannyben\>
% March 2026

NAME
==================================================

**shellkin-feature** - feature file for shellkin

DESCRIPTION
==================================================

Shellkin feature files use a small Gherkin-compatible subset for describing
test scenarios.

Feature files are loaded from the selected features directory and must use the
**.feature** extension.

SUPPORTED KEYWORDS
==================================================

Shellkin currently supports these Gherkin keywords:

- **Feature**
- **Background**
- **Scenario**
- **Given**, **When**, **Then**
- **And**, **But**, **\***

FORMAT
==================================================

Feature Header
--------------------------------------------------

Each feature file starts with a **Feature:** header.

```gherkin
Feature: --help
```

Description Text
--------------------------------------------------

Free text may appear below the feature header before the first section.

```gherkin
Feature: --help
  Show help message
```

Scenario
--------------------------------------------------

Each executable example is declared with **Scenario:**.

```gherkin
Scenario: Run --help
  When I run 'shellkin --help'
  Then the output should include 'shellkin COMMAND'
```

Background
--------------------------------------------------

Use **Background:** for steps that should run before each scenario in the
feature.

```gherkin
Background:
  Given I am in a temp directory
```

Steps
--------------------------------------------------

Supported step keywords are **Given**, **When**, **Then**, **And**, **But**,
and **\***.

```gherkin
Scenario: Touch a file
  Given I am in a temp directory
  When I run 'touch somefile'
  Then the file 'somefile' should exist
```

**And**, **But**, and **\*** reuse the semantic type of the previous step.

```gherkin
Scenario: Run command
  When I run 'shellkin --help'
  And the exit code should mean success
```

```gherkin
Scenario: Prepare files
  Given I am in a temp directory
  When I run 'touch one'
  * I run 'touch two'
  Then the file 'one' should exist
  And the file 'two' should exist
```

Like **And** and **But**, the **\*** keyword cannot be the first step in a
scenario or background.

COMMENTS AND BLANK LINES
==================================================

Blank lines are ignored.

Lines starting with **#** are treated as comments.

```gherkin
# This is a comment
Feature: Example
```

TAGS
==================================================

Tags can be placed before a **Feature:** or **Scenario:**.

```gherkin
@filesystem
Feature: Files

@smoke
Scenario: Create a file
  When I run 'touch one'
  Then the file 'one' should exist
```

Feature tags are inherited by the scenarios in that feature. Use
**shellkin --tag @tag** to run scenarios with a tag, and
**shellkin --exclude-tag @tag** to skip scenarios with a tag.

DOC STRINGS
==================================================

Shellkin supports Gherkin-style doc strings using **"""** fences.

```gherkin
Scenario: Match multiline output
  When I run 'printf "hello\nworld"'
  Then the output should match
    """
    hello
    world
    """
```

The doc string content is exposed to the matching step definition through the
**DOC_STRING** environment variable.

UNSUPPORTED CONSTRUCTS
==================================================

The following common Gherkin constructs are not currently supported:

- **Rule**
- **Scenario Outline**
- **Examples**
- data tables
- hooks

EXAMPLE
==================================================

```gherkin
Feature: file creation
  Basic file operations

Background:
  Given I am in a temp directory

Scenario: Create a file
  When I run 'touch somefile'
  Then the file 'somefile' should exist
```

SEE ALSO
==================================================

**shellkin**(1), **shellkin-stepdefs**(5)


SOURCE CODE
==================================================

https://github.com/dannyben/shellkin


ISSUE TRACKER
==================================================

https://github.com/dannyben/shellkin/issues
