output_feature_start() {
  blue_bold "\nFeature: $1"
}

output_scenario_start() {
  bold "\nScenario: $1"
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
    return 0
  fi

  green "$line"
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
