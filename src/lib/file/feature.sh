feature_run() {
  local feature_file=$1
  local line
  local section=
  local feature_seen=0
  local scenario_seen=0
  local in_description=0
  local in_doc_string=0
  local failed=0
  local doc_string_indent=
  local doc_string_content=
  local doc_string_line=
  local -a background_steps=()
  local -a scenario_steps=()

  FEATURE_NAME=

  set +e

  while IFS= read -r line || [[ -n $line ]]; do
    if ((in_doc_string != 0)); then
      if [[ $(trim "$line") == '"""' ]]; then
        feature_doc_string_apply "$doc_string_content" "$section" background_steps scenario_steps || failed=1
        in_doc_string=0
        doc_string_indent=
        doc_string_content=
        continue
      fi

      doc_string_line=$line
      if [[ -n $doc_string_indent && $doc_string_line == "$doc_string_indent"* ]]; then
        doc_string_line=${doc_string_line#"$doc_string_indent"}
      fi

      if [[ -n $doc_string_content ]]; then
        doc_string_content+=$'\n'
      fi
      doc_string_content+=$doc_string_line
      continue
    fi

    feature_line_parse "$line"

    case $FEATURE_LINE_KIND in
      blank | comment)
        continue
        ;;
      feature)
        feature_seen=1
        section=feature
        in_description=1
        FEATURE_NAME=$FEATURE_LINE_NAME
        output_feature_start "$FEATURE_NAME"
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
          feature_scenario_run "$FEATURE_SCENARIO_NAME" background_steps scenario_steps || failed=1
        fi
        scenario_seen=1
        ((TEST_SCENARIOS_TOTAL += 1))
        section=scenario
        in_description=0
        FEATURE_SCENARIO_NAME=$FEATURE_LINE_NAME
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
      doc_string_fence)
        doc_string_indent=${line%%\"\"\"*}
        in_doc_string=1
        doc_string_content=
        continue
        ;;
      other)
        if [[ $section == feature && $in_description == 1 ]]; then
          continue
        fi
        failed=1
        ;;
    esac
  done <"$feature_file"

  if ((failed == 0 && scenario_seen != 0)); then
    feature_scenario_run "$FEATURE_SCENARIO_NAME" background_steps scenario_steps || failed=1
  elif ((scenario_seen != 0)); then
    feature_scenario_run "$FEATURE_SCENARIO_NAME" background_steps scenario_steps || failed=1
  fi

  set -e
  return "$failed"
}

feature_recorded_step_run() {
  local recorded=$1
  local previous_type=$2
  local step_keyword=${recorded%%$'\t'*}
  local remainder=${recorded#*$'\t'}
  local step_text
  local doc_string=
  local resolved_type
  local status

  if [[ $remainder == *$'\t'* ]]; then
    step_text=${remainder%%$'\t'*}
    doc_string=${remainder#*$'\t'}
  else
    step_text=$remainder
  fi

  resolved_type=$(feature_step_type_resolve "$previous_type" "$step_keyword") || return 1
  FEATURE_PREVIOUS_STEP_TYPE=$resolved_type
  export DOC_STRING=
  if [[ -n $doc_string ]]; then
    export DOC_STRING=$doc_string
  fi

  step_run "$resolved_type" "$step_text"
  status=$?
  output_step_result "$status" "$step_keyword" "$step_text"
  return "$status"
}

feature_scenario_run() {
  local scenario_name=$1
  local -n background_steps_ref=$2
  local -n scenario_steps_ref=$3
  local step
  local scenario_failed=0

  FEATURE_PREVIOUS_STEP_TYPE=
  output_scenario_start "$scenario_name"

  set +e
  for step in "${background_steps_ref[@]}"; do
    feature_recorded_step_run "$step" "$FEATURE_PREVIOUS_STEP_TYPE" || scenario_failed=1
  done
  for step in "${scenario_steps_ref[@]}"; do
    feature_recorded_step_run "$step" "$FEATURE_PREVIOUS_STEP_TYPE" || scenario_failed=1
  done
  set -e

  if ((scenario_failed != 0)); then
    ((TEST_SCENARIOS_FAILED += 1))
  fi

  return "$scenario_failed"
}

feature_doc_string_apply() {
  local doc_string=$1
  local section=$2
  local -n background_steps_ref=$3
  local -n scenario_steps_ref=$4
  local last_index
  local recorded

  case $section in
    background)
      ((${#background_steps_ref[@]} > 0)) || return 1
      last_index=$((${#background_steps_ref[@]} - 1))
      recorded=${background_steps_ref[last_index]}
      background_steps_ref[last_index]="$recorded"$'\t'"$doc_string"
      ;;
    scenario)
      ((${#scenario_steps_ref[@]} > 0)) || return 1
      last_index=$((${#scenario_steps_ref[@]} - 1))
      recorded=${scenario_steps_ref[last_index]}
      scenario_steps_ref[last_index]="$recorded"$'\t'"$doc_string"
      ;;
    *)
      return 1
      ;;
  esac
}
