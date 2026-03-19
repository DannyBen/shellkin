output_feature_start() {
  blue_bold "\nFeature: $1\n"
}

output_scenario_start() {
  bold "Scenario: $1"
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
