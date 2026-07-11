## Parses a feature file into flat runnable scenarios.
feature_parse() {
  local feature_file=$1
  local line
  local line_number=0
  local section=
  local feature_seen=0
  local scenario_seen=0
  local in_description=0
  local in_doc_string=0
  local failed=0
  local doc_string_indent=
  local doc_string_content=
  local doc_string_line=
  local doc_string_start_line=0
  local pending_tags_line=0
  local pending_tags_context=
  local -a feature_tags=()
  local -a pending_tags=()
  local -a parsed_tags=()
  local -a scenario_tags=()
  local -a background_steps=()
  local -a background_step_lines=()
  local -a scenario_steps=()
  local -a scenario_step_lines=()

  FEATURE_NAME=
  FEATURE_VALIDATION_LINE=
  FEATURE_VALIDATION_MESSAGE=
  FEATURE_VALIDATION_CONTEXT=
  FEATURE_PARSED_SCENARIO_NAMES=()
  FEATURE_PARSED_SCENARIO_TAGS=()
  FEATURE_PARSED_SCENARIO_STEP_STARTS=()
  FEATURE_PARSED_SCENARIO_STEP_COUNTS=()
  FEATURE_PARSED_STEPS=()
  FEATURE_PARSED_STEP_LINES=()

  while IFS= read -r line || [[ -n $line ]]; do
    ((line_number += 1))

    if ((in_doc_string != 0)); then
      if [[ $(trim "$line") == '"""' ]]; then
        if feature_doc_string_apply "$doc_string_content" "$section" background_steps scenario_steps; then
          :
        else
          feature_validation_set_error "$doc_string_start_line" "doc string must follow a step" '"""'
          failed=1
          break
        fi

        in_doc_string=0
        doc_string_indent=
        doc_string_content=
        doc_string_start_line=0
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
        # shellcheck disable=SC2034  # consumed through nameref when scenarios are added
        feature_tags=("${pending_tags[@]}")
        pending_tags=()
        pending_tags_line=0
        pending_tags_context=
        continue
        ;;
      tag)
        parsed_tags=()
        if feature__tags_parse "$FEATURE_TAG_TEXT" parsed_tags; then
          :
        else
          feature_validation_set_error "$line_number" "invalid tag syntax" "$(trim "$line")"
          failed=1
          break
        fi
        if ((feature_seen == 0)); then
          pending_tags+=("${parsed_tags[@]}")
        else
          if ((scenario_seen != 0)); then
            feature__parsed_scenario_add "$FEATURE_SCENARIO_NAME" feature_tags scenario_tags background_steps background_step_lines scenario_steps scenario_step_lines
            scenario_seen=0
          fi
          pending_tags+=("${parsed_tags[@]}")
          section=tag
          in_description=0
        fi
        if ((pending_tags_line == 0)); then
          pending_tags_line=$line_number
          pending_tags_context=$(trim "$line")
        fi
        continue
        ;;
      background)
        if ((feature_seen == 0 || scenario_seen != 0)); then
          feature_validation_set_error "$line_number" "Background must appear after Feature and before the first Scenario" "$(trim "$line")"
          failed=1
          break
        fi
        if ((pending_tags_line != 0)); then
          feature_validation_set_error "$pending_tags_line" "tag must appear before Feature or Scenario" "$pending_tags_context"
          failed=1
          break
        fi
        section=background
        in_description=0
        continue
        ;;
      scenario)
        if ((feature_seen == 0)); then
          feature_validation_set_error "$line_number" "Scenario must appear after Feature" "$(trim "$line")"
          failed=1
          break
        fi
        if ((scenario_seen != 0)); then
          feature__parsed_scenario_add "$FEATURE_SCENARIO_NAME" feature_tags scenario_tags background_steps background_step_lines scenario_steps scenario_step_lines
        fi
        scenario_seen=1
        section=scenario
        in_description=0
        FEATURE_SCENARIO_NAME=$FEATURE_LINE_NAME
        scenario_tags=("${pending_tags[@]}")
        pending_tags=()
        pending_tags_line=0
        pending_tags_context=
        scenario_steps=()
        scenario_step_lines=()
        continue
        ;;
      step)
        in_description=0
        case $section in
          background)
            background_steps+=("$FEATURE_STEP_TYPE"$'\t'"$FEATURE_STEP_TEXT")
            background_step_lines+=("$line_number")
            ;;
          scenario)
            scenario_steps+=("$FEATURE_STEP_TYPE"$'\t'"$FEATURE_STEP_TEXT")
            scenario_step_lines+=("$line_number")
            ;;
          *)
            feature_validation_set_error "$line_number" "step must appear inside Background or Scenario" "$(trim "$line")"
            failed=1
            ;;
        esac
        continue
        ;;
      table_row)
        in_description=0
        if feature_table_row_apply "$FEATURE_TABLE_TEXT" "$section" background_steps scenario_steps; then
          :
        else
          feature_validation_set_error "$line_number" "data table must follow a step" "$(trim "$line")"
          failed=1
        fi
        continue
        ;;
      doc_string_fence)
        doc_string_indent=${line%%\"\"\"*}
        in_doc_string=1
        doc_string_content=
        doc_string_start_line=$line_number
        continue
        ;;
      other)
        if [[ $section == feature && $in_description == 1 ]]; then
          continue
        fi
        feature_validation_set_error "$line_number" "invalid feature syntax" "$FEATURE_LINE_NAME"
        failed=1
        ;;
    esac

    ((failed == 0)) || break
  done <"$feature_file"

  if ((failed == 0 && in_doc_string != 0)); then
    feature_validation_set_error "$doc_string_start_line" "unterminated doc string" '"""'
    failed=1
  fi

  if ((failed == 0 && pending_tags_line != 0)); then
    feature_validation_set_error "$pending_tags_line" "tag must appear before Feature or Scenario" "$pending_tags_context"
    failed=1
  fi

  if ((failed == 0 && scenario_seen != 0)); then
    feature__parsed_scenario_add "$FEATURE_SCENARIO_NAME" feature_tags scenario_tags background_steps background_step_lines scenario_steps scenario_step_lines
  fi

  return "$failed"
}

feature__parsed_scenario_add() {
  local scenario_name=$1
  local feature_tags_name=$2
  local scenario_tags_name=$3
  # shellcheck disable=SC2178  # nameref to an array supplied by name
  local -n background_steps_ref=$4
  local -n background_lines_ref=$5
  # shellcheck disable=SC2178  # nameref to an array supplied by name
  local -n scenario_steps_ref=$6
  local -n scenario_lines_ref=$7
  local start=${#FEATURE_PARSED_STEPS[@]}
  local count=$((${#background_steps_ref[@]} + ${#scenario_steps_ref[@]}))

  feature__scenario_tags_set "$feature_tags_name" "$scenario_tags_name"
  FEATURE_PARSED_SCENARIO_NAMES+=("$scenario_name")
  FEATURE_PARSED_SCENARIO_TAGS+=("$FEATURE_SCENARIO_TAGS")
  FEATURE_PARSED_SCENARIO_STEP_STARTS+=("$start")
  FEATURE_PARSED_SCENARIO_STEP_COUNTS+=("$count")
  FEATURE_PARSED_STEPS+=("${background_steps_ref[@]}" "${scenario_steps_ref[@]}")
  FEATURE_PARSED_STEP_LINES+=("${background_lines_ref[@]}" "${scenario_lines_ref[@]}")
}
