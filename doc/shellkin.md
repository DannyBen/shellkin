% shellkin(1) Version 0.2.0 | Gherkin-style BDD Test Framework for Bash Scripts
% Danny Ben Shitrit \<https://github.com/dannyben\>
% July 2026

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

Target to test. Can be in one of these forms:

- DIR = Features directory
- FILE = *.feature file
- NUMBER = Scenario number in the default target
- DIR:NUMBER = Scenario number in DIR
- FILE:NUMBER = Scenario number in FILE

Default: value of --default-target



OPTIONS
==================================================

--fail-fast, -f
--------------------------------------------------

Abort after the first failing scenario

- Conflicts With: **--init**

--validate, -v
--------------------------------------------------

Validate feature and step definition files

- Conflicts With: **--init, --tag, --exclude-tag**

--init
--------------------------------------------------

Initialize a Shellkin features directory

- Conflicts With: **--validate, --fail-fast, --load, --tag, --exclude-tag**

--default-target DIR
--------------------------------------------------

Path to features directory

Relative to working directory

Normally only used in a .shellkin argfile


- Default Value: **features**

--tag, -t TAG
--------------------------------------------------

Run scenarios with this tag

- *Repeatable*
- Conflicts With: **--init, --validate**

--exclude-tag, -x TAG
--------------------------------------------------

Skip scenarios with this tag

- *Repeatable*
- Conflicts With: **--init, --validate**

--stepdefs, -s DIR
--------------------------------------------------

Path to step definitions directory

Relative to features root


- Default Value: **step_definitions**

--load, -l SUPPORT_SCRIPT
--------------------------------------------------

Path to support script for step definitions

Relative to features root

support.sh is loaded automatically


- *Repeatable*
- Conflicts With: **--init**

SEE ALSO
==================================================

**shellkin-stepdefs**(5), **shellkin-feature**(5)

# SOURCE CODE

https://github.com/dannyben/shellkin

# ISSUE TRACKER

https://github.com/dannyben/shellkin/issues
