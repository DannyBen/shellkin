output_feature_start() {
  printf 'Feature: %s\n' "$1"
}

output_scenario_start() {
  printf '  Scenario: %s\n' "$1"
}

output_step_result() {
  local status=$1
  local type=$2
  local text=$3
  local symbol='✓'

  if ((status != 0)); then
    symbol='✗'
  fi

  printf '    %s %s %s\n' "$symbol" "$type" "$text"
}
