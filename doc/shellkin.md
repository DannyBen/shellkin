% shellkin(1) Version 0.1.2 | Gherkin-style BDD Test Framework for Bash Scripts
% Danny Ben Shitrit \<https://github.com/dannyben\>
% March 2026

NAME
==================================================

**shellkin** - Gherkin-style BDD Test Framework for Bash Scripts

SYNOPSIS
==================================================

**shellkin** [TARGET] [OPTIONS]

DESCRIPTION
==================================================

Gherkin-style BDD Test Framework for Bash Scripts
Supports configuration from a .shellkin argfile in the working directory



ARGUMENTS
==================================================

TARGET
--------------------------------------------------

Path to features directory or a single feature file
Default: value of --default-target



OPTIONS
==================================================

--fail-fast, -f
--------------------------------------------------

Abort after the first failing scenario


--validate, -v
--------------------------------------------------

Validate feature and step definition files


--default-target, -t DIR
--------------------------------------------------

Path to features directory (relative to working directory)
This flag is normally only used in a .shellkin argfile


- Default Value: **features**

--stepdefs, -s DIR
--------------------------------------------------

Path to step definitions directory (relative to features root)

- Default Value: **step_definitions**

--load, -l SUPPORT_SCRIPT
--------------------------------------------------

Path to support script for step definitions (relative to features root)

- *Repeatable*

SEE ALSO
==================================================

**shellkin-stepdefs**(5), **shellkin-feature**(5)

# SOURCE CODE

https://github.com/dannyben/shellkin

# ISSUE TRACKER

https://github.com/dannyben/shellkin/issues
