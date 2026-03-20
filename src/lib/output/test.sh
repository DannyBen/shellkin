output_feature_start() {
  blue_bold "\nFeature: $1"
}

output_scenario_start() {
  bold "\nScenario: $1"
}

output_failure_label() {
  local label=$1

  if [[ "${NO_COLOR:-}" == "" ]]; then
    printf '    \e[1m%s\e[0m' "$label"
  else
    printf '    %s' "$label"
  fi
}

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

output_step_skipped() {
  local type=$1
  local text=$2

  cyan "  - $type $text (skipped)"
}

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
