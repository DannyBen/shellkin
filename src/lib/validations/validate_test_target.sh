## Parses a target into a path plus optional scenario number.
parse_test_target() {
  local target_input=$1
  local default_target=$2

  VALIDATION_ERROR=
  TEST_TARGET_PATH=
  TEST_TARGET_SCENARIO=

  if [[ -z $target_input ]]; then
    TEST_TARGET_PATH=$default_target
    return 0
  fi

  if [[ $target_input =~ ^[0-9]+$ ]]; then
    TEST_TARGET_PATH=$default_target
    TEST_TARGET_SCENARIO=$target_input
    validate_test_target__scenario_number_validate "$TEST_TARGET_SCENARIO" || return 1
    return 0
  fi

  if [[ $target_input == *:* ]]; then
    TEST_TARGET_PATH=${target_input%:*}
    TEST_TARGET_SCENARIO=${target_input##*:}

    if [[ -n $TEST_TARGET_PATH && $TEST_TARGET_SCENARIO != "$target_input" ]]; then
      validate_test_target__scenario_number_validate "$TEST_TARGET_SCENARIO" || return 1
      return 0
    fi
  fi

  TEST_TARGET_PATH=$target_input
  TEST_TARGET_SCENARIO=
}

## Validates that a target path and step definitions directory are usable.
validate_test_target() {
  local target=$1
  local scenario_number=$2
  local stepdefs_dir=$3
  local features_dir
  local -a errors=()

  VALIDATION_ERROR=

  if [[ -n $scenario_number ]]; then
    validate_test_target__scenario_number_validate "$scenario_number" || return 1
  fi

  if [[ -f "$target" ]]; then
    features_dir=$(dirname "$target")
    [[ $target == *.feature ]] || errors+=("$target must be a .feature file or a directory")
    [[ -d "$features_dir/$stepdefs_dir" ]] || errors+=("$features_dir/$stepdefs_dir must be a directory")
  else
    [[ -d "$target" ]] || errors+=("$target must be a directory")
    [[ -d "$target/$stepdefs_dir" ]] || errors+=("$target/$stepdefs_dir must be a directory")
  fi

  if ((${#errors[@]} != 0)); then
    VALIDATION_ERROR=$(printf '%s\n' "${errors[@]}")
    return 1
  fi
}

validate_test_target__scenario_number_validate() {
  local scenario_number=$1

  if [[ ! $scenario_number =~ ^[1-9][0-9]*$ ]]; then
    VALIDATION_ERROR="scenario number must be a positive integer: $scenario_number"
    return 1
  fi
}
