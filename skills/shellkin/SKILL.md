---
name: shellkin
description: Create and maintain Shellkin feature tests for a user's Bash project. Use this skill when the task is to add, update, debug, or review `.feature` files and `step_definitions/*.sh` files that test a shell CLI or shell scripts with Shellkin. This skill is for end-user projects that use Shellkin, not for developing Shellkin itself.
---

# Shellkin Feature Tests

Use this skill when working in a project that uses Shellkin to test shell behavior with Gherkin-style feature files.

This skill is for authoring tests in the user's project. Do not switch into Shellkin-maintainer mode unless the request is explicitly about Shellkin internals.

## Source Of Truth

When Shellkin is installed in the target environment, prefer the local man pages as the primary reference for current behavior and supported syntax.

Check these first when you need Shellkin-specific facts:

- `man shellkin`
- `man 5 shellkin-feature`
- `man 5 shellkin-stepdefs`

Use the man pages to confirm command usage, environment variables, supported feature-file syntax, step definition rules, and helper behavior before making assumptions.

If external reference is useful, Shellkin source code and documentation are available at `https://github.com/DannyBen/shellkin`, but prefer installed man pages for user-facing behavior.

## Workflow

1. Inspect the target project before writing tests.
   Check for `features/`, existing `.feature` files, and `step_definitions/`.
   If the repo uses custom roots, respect its `.shellkin` argfile and any
   explicit `--default-target`, `--stepdefs`, or `--load` usage.
   Consult the relevant Shellkin man pages before relying on memory.
2. Model tests around observable behavior.
   Prefer CLI behavior, file effects, stdout, stderr, and exit status over implementation details.
3. Reuse and extend existing step definitions before adding new ones.
   Keep new steps generic enough to be reused across scenarios.
4. Write feature files in Shellkin's supported Gherkin subset only.
   Use `Feature`, optional description text, `Background`, `Scenario`, and steps with `Given`/`When`/`Then` plus `And`/`But`/`*`.
5. Validate before concluding.
   Run `shellkin --validate` first when changing step matching or feature structure.
   Run `shellkin` on the narrowed target for execution checks when the environment allows it.

## Directory Model

Shellkin expects feature files under the selected features root, with step definitions in a sibling `step_definitions/` directory under that same root.

Typical layout:

```text
features/
├── support.sh
├── support/
│   ├── output.sh
│   └── filesystem.sh
├── step_definitions/
│   └── core.sh
└── example.feature
```

When a task targets a single feature area, prefer placing the feature in the existing features tree rather than inventing a parallel layout.
Place helper functions for a feature root in `support.sh`.
If that file grows too large, keep `support.sh` as the entrypoint, add a sibling `support/` directory organized by concern, and have `support.sh` source those files.

## Feature Authoring Rules

- Start each file with `Feature:`.
- Free text under `Feature:` is allowed before the first section.
- Use `Background:` only for setup shared by every scenario in that file.
- Use `Scenario:` for each executable example.
- Keep scenarios small and concrete.
- `And`, `But`, and `*` inherit the semantic type of the previous step, so they cannot be the first step in a scenario or background.
- Use doc strings with `"""` for multiline expectations or input.

Do not use unsupported constructs:

- `Rule`
- `Scenario Outline`
- `Examples`
- data tables
- tags such as `@slow`

## Step Definition Rules

Step definitions live in shell files under `step_definitions/` and use headers like:

```bash
@When I run '{command}'
  run "$command"
```

Follow these rules:

- Headers must begin with `@Given`, `@When`, or `@Then`.
- The body continues until the next header or end of file.
- Indent step bodies by two spaces for readability.
- Use named `{tokens}` for variable parts.
- Token names must start with a letter or underscore, then use letters, numbers, or underscores.
- When a step matches, token values are exposed as shell variables in the body.
- Prefer a small set of reusable steps over many one-off phrases.

## Built-in Helpers And State

Prefer Shellkin's built-ins instead of hand-rolled wrappers:

- `run "$command"` captures command results and still returns success.
- `fail "message"` fails the current step with a clearer assertion message.
- `defer ...` registers scenario-scoped cleanup in reverse order.

Useful environment variables in step bodies:

- `LAST_EXIT_CODE`
- `LAST_STDOUT`
- `LAST_STDERR`
- `DOC_STRING`
- `FAIL_MESSAGE`

## Authoring Heuristics

- If the project already has a "run command" step, reuse it.
- Prefer steps phrased in user language, not internal function names.
- Keep shell bodies straightforward and readable.
- Put reusable helper functions in `support.sh`, not in step definition files.
- If helper code outgrows `support.sh`, split it into a sibling `support/` directory by concern and source those files from `support.sh`.
- Put setup in `Given`, actions in `When`, and assertions in `Then`.
- Use doc strings for exact multiline matches instead of brittle escaped strings.
- If a command is expected to fail, remember that `run` still succeeds; assert on `LAST_EXIT_CODE` or captured output.
- When creating temp directories or changing directories, clean up with `defer`.

## Validation Pattern

After edits:

1. Run `shellkin --validate` on the feature root or changed feature file.
2. Run `shellkin` on the narrowed target when practical.
3. If a step does not match, check the step text, header text, token names, the
   active target, and the configured step definitions directory.

## References

- Prefer local man pages for live Shellkin reference.
- For concrete feature and stepdef patterns, read [references/patterns.md](references/patterns.md).
