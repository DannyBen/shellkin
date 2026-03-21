% shellkin(1) Version 0.1.2 | Gherkin-style BDD Test Framework for Bash Scripts
% Danny Ben Shitrit \<https://github.com/dannyben\>
% March 2026

NAME
==================================================

**shellkin** - Gherkin-style BDD Test Framework for Bash Scripts

SYNOPSIS
==================================================

**shellkin** [COMMAND]

DESCRIPTION
==================================================

Gherkin-style BDD Test Framework for Bash Scripts


COMMANDS
==================================================

shellkin test
--------------------------------------------------

Run feature tests

shellkin validate
--------------------------------------------------

Validate feature files and step definition files


ENVIRONMENT VARIABLES
==================================================

SHELLKIN_FEATURES_ROOT
--------------------------------------------------

Path to features directory (relative to working directory)

- Default Value: **features**

SHELLKIN_STEPDEFS_ROOT
--------------------------------------------------

Path to step definitions directory (relative to features root)

- Default Value: **step_definitions**

SHELLKIN_SUPPORT_FILE
--------------------------------------------------

Path to support script for step definitions (relative to features root)

- Default Value: **support.sh**

SEE ALSO
==================================================

**shellkin-test**(1), **shellkin-validate**(1), **shellkin-stepdefs**(5), **shellkin-feature**(5)

# SOURCE CODE

https://github.com/dannyben/shellkin

# ISSUE TRACKER

https://github.com/dannyben/shellkin/issues
