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

## Install

### Installing using the setup script

This setup script will download the latest shellkin release executable to
`/usr/local/bin/`.

```shell
$ curl -Ls get.dannyb.co/shellkin/setup | bash
```

Feel free to inspect the [setup script](setup) before running.


### Installing manually

Download the `shellkin` bash script, place it in your path and make it
executable.

```console
# download the latest release and place it in /usr/local/bin
wget https://github.com/DannyBen/shellkin/releases/latest/download/shellkin
sudo install -m 0755 shellkin /usr/local/bin/
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

## Features Directory Layout

Shellkin expects this structure:

```text
features/
├── step_definitions/
│   └── core.sh
└── example.feature
```

- Feature files live in the target directory.
- Step definitions live in `step_definitions/` under that same directory.

## Uninstalling

If you used the setup script, you can run this uninstall script:

```shell
$ curl -Ls get.dannyb.co/shellkin/uninstall | bash
```

## Contributing / Support

If you experience any issue, have a question or a suggestion, or if you wish
to contribute, feel free to [open an issue][issues].

[issues]: https://github.com/DannyBen/shellkin/issues
