feature_run() {
  local feature_file=$1
  local line
  local section=
  local feature_seen=0
  local scenario_seen=0
  local in_description=0
  local failed=0
  local -a background_steps=()
  local -a scenario_steps=()

  FEATURE_NAME=

  set +e

  while IFS= read -r line || [[ -n $line ]]; do
    feature_line_parse "$line"

    case $FEATURE_LINE_KIND in
      blank|comment)
        continue
        ;;
      feature)
        feature_seen=1
        section=feature
        in_description=1
        FEATURE_NAME=$FEATURE_LINE_NAME
        continue
        ;;
      background)
        if ((feature_seen == 0 || scenario_seen != 0)); then
          failed=1
          break
        fi
        section=background
        in_description=0
        continue
        ;;
      scenario)
        if ((feature_seen == 0)); then
          failed=1
          break
        fi
        if ((scenario_seen != 0)); then
          feature_scenario_run background_steps scenario_steps || failed=1
        fi
        scenario_seen=1
        section=scenario
        in_description=0
        scenario_steps=()
        continue
        ;;
      step)
        in_description=0
        case $section in
          background)
            background_steps+=("$FEATURE_STEP_TYPE"$'\t'"$FEATURE_STEP_TEXT")
            ;;
          scenario)
            scenario_steps+=("$FEATURE_STEP_TYPE"$'\t'"$FEATURE_STEP_TEXT")
            ;;
          *)
            failed=1
            ;;
        esac
        continue
        ;;
      other)
        if [[ $section == feature && $in_description == 1 ]]; then
          continue
        fi
        failed=1
        ;;
    esac
  done < "$feature_file"

  if ((failed == 0 && scenario_seen != 0)); then
    feature_scenario_run background_steps scenario_steps || failed=1
  elif ((scenario_seen != 0)); then
    feature_scenario_run background_steps scenario_steps || failed=1
  fi

  set -e
  return "$failed"
}

feature_recorded_step_run() {
  local recorded=$1
  local previous_type=$2
  local step_keyword=${recorded%%$'\t'*}
  local step_text=${recorded#*$'\t'}
  local resolved_type

  resolved_type=$(feature_step_type_resolve "$previous_type" "$step_keyword") || return 1
  FEATURE_PREVIOUS_STEP_TYPE=$resolved_type

  step_run "$resolved_type" "$step_text"
}

feature_scenario_run() {
  local -n background_steps_ref=$1
  local -n scenario_steps_ref=$2
  local step
  local scenario_failed=0

  FEATURE_PREVIOUS_STEP_TYPE=

  set +e
  for step in "${background_steps_ref[@]}"; do
    feature_recorded_step_run "$step" "$FEATURE_PREVIOUS_STEP_TYPE" || scenario_failed=1
  done
  for step in "${scenario_steps_ref[@]}"; do
    feature_recorded_step_run "$step" "$FEATURE_PREVIOUS_STEP_TYPE" || scenario_failed=1
  done
  set -e

  return "$scenario_failed"
}
