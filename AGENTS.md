# Shellkin Agents Guide

Shellkin is a Bashly-based Gherkin-style test framework for shell scripts.

## Orientation

- The project is organized by concept, not by command:
  - `src/lib/feature` contains feature parsing and execution
  - `src/lib/stepdef` contains step definition parsing and file loading
  - `src/lib/step` contains step matching and execution
  - `src/lib/support` contains support file loading
  - `src/lib/user_helpers` contains step-author-facing helpers
  - `src/lib/output` contains user-visible screen output
  - `src/lib/core` contains small shared primitives
- Bashly command behavior lives in `src/root_command.sh`.
- Repo-level `features/` are used both for dogfooding and as examples.

## Conventions

- Prefer small, focused functions.
- Do not use nested function definitions; private helpers should still live at file scope.
- Name private helpers with a `__` suffix on the namespace, such as `feature__helper`.
- Place private helpers after the public functions in each file.
- Use uppercase names for shared/framework state and lowercase for local variables.
- Do not access CLI input such as `args[...]` anywhere under `src/lib`; normalize CLI input in the command layer and pass explicit parameters into lib functions.
- Keep user-facing helper functions separate from framework internals.
- Keep output logic isolated from parsing and runtime logic.
- Prefer established Gherkin conventions and syntax over custom forms when practical.

## Tests

- Prefer readable Bats tests over clever ones.
- Use focused test files per function or per small public API surface.
- Do not test private `__` helpers directly.
- When file content is the subject of the test, prefer inline heredoc fixtures.
- `write_file` in tests writes under `TEST_ROOT`.

## Bashly Workflow

- This is a Bashly project.
- During normal iteration, regenerate with `bashly generate`.
- Avoid `bashly generate --force` unless overwriting user-managed files is explicitly intended.
