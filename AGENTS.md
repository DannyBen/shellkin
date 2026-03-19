# Shellkin Agents Guide

Shellkin is a Bashly-based Gherkin-style test framework for shell scripts.

## Orientation

- The project is organized by concern, not by command:
  - `src/lib/syntax` parses and validates the language
  - `src/lib/file` reads project files and orchestrates them
  - `src/lib/runtime` contains framework execution internals
  - `src/lib/user_helpers` contains step-author-facing helpers
  - `src/lib/output` contains user-visible screen output
  - `src/lib/core` contains small shared primitives
- Bashly command behavior lives in `src/commands`.
- Repo-level `features/` are used both for dogfooding and as examples.

## Conventions

- Prefer small, focused functions.
- Do not use nested function definitions; private helpers should still live at file scope.
- Use uppercase names for shared/framework state and lowercase for local variables.
- Keep user-facing helper functions separate from framework internals.
- Keep output logic isolated from parsing and runtime logic.
- Prefer established Gherkin conventions and syntax over custom forms when practical.

## Tests

- Prefer readable Bats tests over clever ones.
- Use focused test files per function or per small public API surface.
- When file content is the subject of the test, prefer inline heredoc fixtures.
- `write_file` in tests writes under `TEST_ROOT`.

## Bashly Workflow

- This is a Bashly project.
- During normal iteration, regenerate with `bashly generate`.
- Avoid `bashly generate --force` unless overwriting user-managed files is explicitly intended.
