## Prints the heading for a feature run.
output_feature_start() {
  blue_bold "\nFeature: $1"
}

## Prints the heading for a scenario run.
output_scenario_start() {
  printf "\n%s %s: %s\n" "$(bold Scenario)" "$(cyan_bold "$1")" "$2"
}

## Prints a formatted label inside a failure block.
output_failure_label() {
  printf '    %s' "$(bold "$1")"
}

## Prints one named failure detail value.
output_failure_block() {
  local label=$1
  local value=$2
  local line

  [[ -n $value ]] || return 0

  if [[ $value != *$'\n'* ]]; then
    output_failure_label "$label"
    printf ': %s\n' "$value"
    return 0
  fi

  output_failure_label "$label"
  printf ':\n\n'
  while IFS= read -r line || [[ -n $line ]]; do
    printf '      %s\n' "$line"
  done <<<"$value"
  printf '\n'
}

## Prints the result line for a step execution.
output_step_result() {
  local status=$1
  local type=$2
  local text=$3
  local symbol='✓'
  local line="  $symbol $type $text"

  if ((status != 0)); then
    symbol='✗'
    line="  $symbol $type $text"
    red "$line"
    output_failure_block "FAIL_MESSAGE" "${FAIL_MESSAGE:-}"
    output_failure_block "LAST_EXIT_CODE" "${LAST_EXIT_CODE:-}"
    output_failure_block "LAST_STDOUT" "${LAST_STDOUT:-}"
    output_failure_block "LAST_STDERR" "${LAST_STDERR:-}"
    output_failure_block "DOC_STRING" "${DOC_STRING:-}"
    return 0
  fi

  green "$line"
}

## Prints a skipped step line after a previous failure.
output_step_skipped() {
  local type=$1
  local text=$2

  cyan "  - $type $text (skipped)"
}

## Prints the deferred cleanup failure section.
output_deferred_failure() {
  red "  ✗ Deferred cleanup"
  output_failure_block "FAIL_MESSAGE" "${FAIL_MESSAGE:-}"
}

## Prints the final summary for a test run.
output_summary() {
  local total_scenarios=$1
  local failed_scenarios=$2
  local passed_scenarios=$((total_scenarios - failed_scenarios))
  local label=scenarios
  local line

  if ((total_scenarios == 1)); then
    label=scenario
  fi

  if ((failed_scenarios == 0)); then
    green_bold "\n$total_scenarios $label, $failed_scenarios failing"
    return 0
  fi

  red_bold "\n$total_scenarios $label, $passed_scenarios passing, $failed_scenarios failing"
}
