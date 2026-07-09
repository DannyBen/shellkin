## Prints the heading for a feature run.
output_feature_start() {
  blue_bold "\nFeature: $1"
}

## Prints the heading for a scenario run.
output_scenario_start() {
  printf "\n%s %s: %s\n" "$(bold Scenario)" "$(cyan_bold "$1")" "$2"
}

## Converts a feature file path to a display path relative to the target root.
output_feature_relpath() {
  local file=$1

  if [[ -n ${FEATURES_DIR:-} && $file == "$FEATURES_DIR/"* ]]; then
    printf '%s' "${file#"$FEATURES_DIR"/}"
  else
    basename "$file"
  fi
}

## Prints one named error report value.
output_error_report_field() {
  local label=$1
  local value=$2
  local line

  [[ -n $value ]] || return 0

  if [[ $value != *$'\n'* ]]; then
    printf '  │ %s: %s\n' "$(bold "$label")" "$value"
    return 0
  fi

  printf '  │ %s:\n' "$(bold "$label")"
  printf '  │\n'
  while IFS= read -r line || [[ -n $line ]]; do
    printf '  │   %s\n' "$line"
  done <<<"$value"
}

## Prints a framed error report for a failed step.
output_error_report() {
  local step=$1

  printf '\n'
  printf '  ┌─ Error Report ───────────────────────\n'
  output_error_report_field "File" "$(output_feature_relpath "$FEATURE_FILE")"
  output_error_report_field "Step" "$step"
  printf '  │\n'
  output_error_report_field "FAIL_MESSAGE" "${FAIL_MESSAGE:-}"
  output_error_report_field "LAST_EXIT_CODE" "${LAST_EXIT_CODE:-}"
  output_error_report_field "LAST_STDOUT" "${LAST_STDOUT:-}"
  output_error_report_field "LAST_STDERR" "${LAST_STDERR:-}"
  output_error_report_field "DOC_STRING" "${DOC_STRING:-}"
  printf '  └──────────────────────────────────────\n\n'
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
    output_error_report "$type $text"
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
  output_error_report "Deferred cleanup"
}

## Prints a hook failure section.
output_hook_failure() {
  local hook_header=$1

  red "  ✗ $hook_header"
  output_error_report "$hook_header"
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
