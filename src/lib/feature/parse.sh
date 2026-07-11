## Parses a feature file into flat runnable scenarios.
feature_parse() {
  local feature_file=$1
  local line
  local line_number=0
  local section=
  local feature_seen=0
  local feature_background_seen=0
  local feature_scenario_seen=0
  local rule_seen=0
  local rule_background_seen=0
  local rule_scenario_seen=0
  local rule_line=0
  local rule_name=
  local scenario_seen=0
  local scenario_outline=0
  local scenario_line=0
  local examples_seen=0
  local examples_line=0
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
  local -a rule_tags=()
  local -a pending_tags=()
  local -a parsed_tags=()
  local -a scenario_tags=()
  local -a background_steps=()
  local -a background_step_lines=()
  local -a feature_background_steps=()
  local -a feature_background_step_lines=()
  local -a scenario_steps=()
  local -a scenario_step_lines=()
  local -a example_rows=()
  local -a example_row_lines=()

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
            feature__parsed_scenario_finish "$scenario_outline" "$scenario_line" "$examples_line" feature_tags scenario_tags background_steps background_step_lines scenario_steps scenario_step_lines example_rows example_row_lines || {
              failed=1
              break
            }
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
      rule)
        if ((feature_seen == 0)); then
          feature_validation_set_error "$line_number" "Rule must appear after Feature" "$(trim "$line")"
          failed=1
          break
        fi
        if ((scenario_seen != 0)); then
          feature__parsed_scenario_finish "$scenario_outline" "$scenario_line" "$examples_line" feature_tags scenario_tags background_steps background_step_lines scenario_steps scenario_step_lines example_rows example_row_lines || {
            failed=1
            break
          }
          scenario_seen=0
        fi
        if ((rule_seen != 0 && rule_scenario_seen == 0)); then
          feature_validation_set_error "$rule_line" "Rule must contain at least one Scenario" "Rule: $rule_name"
          failed=1
          break
        fi
        if ((rule_seen == 0)); then
          feature_background_steps=("${background_steps[@]}")
          feature_background_step_lines=("${background_step_lines[@]}")
        fi
        background_steps=("${feature_background_steps[@]}")
        background_step_lines=("${feature_background_step_lines[@]}")
        rule_seen=1
        rule_background_seen=0
        rule_scenario_seen=0
        rule_line=$line_number
        rule_name=$FEATURE_LINE_NAME
        rule_tags=("${pending_tags[@]}")
        pending_tags=()
        pending_tags_line=0
        pending_tags_context=
        section=rule
        in_description=1
        continue
        ;;
      background)
        if ((feature_seen == 0)); then
          feature_validation_set_error "$line_number" "Background must appear after Feature and before the first Scenario" "$(trim "$line")"
          failed=1
          break
        fi
        if ((pending_tags_line != 0)); then
          feature_validation_set_error "$pending_tags_line" "tag must appear before Feature or Scenario" "$pending_tags_context"
          failed=1
          break
        fi
        if ((rule_seen != 0)); then
          if ((scenario_seen != 0 || rule_scenario_seen != 0 || rule_background_seen != 0)); then
            feature_validation_set_error "$line_number" "Rule Background must appear before the first Scenario and only once" "$(trim "$line")"
            failed=1
            break
          fi
          rule_background_seen=1
        else
          if ((scenario_seen != 0 || feature_scenario_seen != 0 || feature_background_seen != 0)); then
            feature_validation_set_error "$line_number" "Background must appear after Feature and before the first Scenario" "$(trim "$line")"
            failed=1
            break
          fi
          feature_background_seen=1
        fi
        section=background
        in_description=0
        continue
        ;;
      scenario | scenario_outline)
        if ((feature_seen == 0)); then
          feature_validation_set_error "$line_number" "Scenario must appear after Feature" "$(trim "$line")"
          failed=1
          break
        fi
        if ((scenario_seen != 0)); then
          feature__parsed_scenario_finish "$scenario_outline" "$scenario_line" "$examples_line" feature_tags scenario_tags background_steps background_step_lines scenario_steps scenario_step_lines example_rows example_row_lines || {
            failed=1
            break
          }
        fi
        scenario_seen=1
        if [[ $FEATURE_LINE_KIND == scenario_outline ]]; then
          scenario_outline=1
        else
          scenario_outline=0
        fi
        scenario_line=$line_number
        examples_seen=0
        examples_line=0
        if ((rule_seen != 0)); then
          rule_scenario_seen=1
        else
          feature_scenario_seen=1
        fi
        section=scenario
        in_description=0
        FEATURE_SCENARIO_NAME=$FEATURE_LINE_NAME
        scenario_tags=("${rule_tags[@]}" "${pending_tags[@]}")
        pending_tags=()
        pending_tags_line=0
        pending_tags_context=
        scenario_steps=()
        scenario_step_lines=()
        example_rows=()
        example_row_lines=()
        continue
        ;;
      examples)
        if ((scenario_seen == 0 || scenario_outline == 0 || examples_seen != 0)); then
          feature_validation_set_error "$line_number" "Examples must appear once after a Scenario Outline" "$(trim "$line")"
          failed=1
          break
        fi
        examples_seen=1
        examples_line=$line_number
        section=examples
        in_description=0
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
        if [[ $section == examples ]]; then
          example_rows+=("$FEATURE_TABLE_TEXT")
          example_row_lines+=("$line_number")
        elif feature_table_row_apply "$FEATURE_TABLE_TEXT" "$section" background_steps scenario_steps; then
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
        if [[ $section == feature || $section == rule ]] && ((in_description == 1)); then
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
    feature__parsed_scenario_finish "$scenario_outline" "$scenario_line" "$examples_line" feature_tags scenario_tags background_steps background_step_lines scenario_steps scenario_step_lines example_rows example_row_lines || failed=1
  fi

  if ((failed == 0 && rule_seen != 0 && rule_scenario_seen == 0)); then
    feature_validation_set_error "$rule_line" "Rule must contain at least one Scenario" "Rule: $rule_name"
    failed=1
  fi

  return "$failed"
}

feature__parsed_scenario_finish() {
  local is_outline=$1
  local scenario_line=$2
  local examples_line=$3
  local feature_tags_name=$4
  local scenario_tags_name=$5
  local background_steps_name=$6
  local background_lines_name=$7
  local scenario_steps_name=$8
  local scenario_lines_name=$9
  local example_rows_name=${10}
  local example_lines_name=${11}

  if ((is_outline == 0)); then
    feature__parsed_scenario_add "$FEATURE_SCENARIO_NAME" "$feature_tags_name" "$scenario_tags_name" "$background_steps_name" "$background_lines_name" "$scenario_steps_name" "$scenario_lines_name"
    return
  fi

  feature__parsed_outline_add "$scenario_line" "$examples_line" "$feature_tags_name" "$scenario_tags_name" "$background_steps_name" "$background_lines_name" "$scenario_steps_name" "$scenario_lines_name" "$example_rows_name" "$example_lines_name"
}

feature__parsed_outline_add() {
  local scenario_line=$1
  local examples_line=$2
  local feature_tags_name=$3
  local scenario_tags_name=$4
  local background_steps_name=$5
  local background_lines_name=$6
  # shellcheck disable=SC2178  # nameref to an array supplied by name
  local -n scenario_steps_ref=$7
  local scenario_lines_name=$8
  local -n scenario_lines_ref=$8
  local -n example_rows_ref=$9
  local -n example_lines_ref=${10}
  local row_index
  local step_index
  local heading
  local previous_heading
  local expanded_name
  local -a headings=()
  local -a cells=()
  local -a expanded_steps=()
  local -a seen_headings=()

  if ((examples_line == 0)); then
    feature_validation_set_error "$scenario_line" "Scenario Outline must have one Examples block" "Scenario Outline: $FEATURE_SCENARIO_NAME"
    return 1
  fi
  if ((${#example_rows_ref[@]} < 2)); then
    feature_validation_set_error "$examples_line" "Examples must have a header and at least one data row" "Examples:"
    return 1
  fi

  feature_table_row_parse "${example_rows_ref[0]}" headings
  for heading in "${headings[@]}"; do
    if [[ -z $heading ]]; then
      feature_validation_set_error "${example_lines_ref[0]}" "Examples headings must not be empty" "${example_rows_ref[0]}"
      return 1
    fi
    for previous_heading in "${seen_headings[@]}"; do
      if [[ $heading == "$previous_heading" ]]; then
        feature_validation_set_error "${example_lines_ref[0]}" "Examples headings must be unique" "${example_rows_ref[0]}"
        return 1
      fi
    done
    seen_headings+=("$heading")
  done

  for ((row_index = 1; row_index < ${#example_rows_ref[@]}; row_index++)); do
    feature_table_row_parse "${example_rows_ref[$row_index]}" cells
    if ((${#cells[@]} != ${#headings[@]})); then
      feature_validation_set_error "${example_lines_ref[$row_index]}" "Examples rows must have the same number of cells as the header" "${example_rows_ref[$row_index]}"
      return 1
    fi

    feature__outline_substitute "$FEATURE_SCENARIO_NAME" headings cells || {
      feature_validation_set_error "$scenario_line" "no Examples column for placeholder" "$FEATURE_OUTLINE_MISSING_PLACEHOLDER"
      return 1
    }
    expanded_name=$FEATURE_OUTLINE_SUBSTITUTED
    expanded_steps=()
    for step_index in "${!scenario_steps_ref[@]}"; do
      feature__outline_substitute "${scenario_steps_ref[$step_index]}" headings cells || {
        feature_validation_set_error "${scenario_lines_ref[$step_index]}" "no Examples column for placeholder" "$FEATURE_OUTLINE_MISSING_PLACEHOLDER"
        return 1
      }
      expanded_steps+=("$FEATURE_OUTLINE_SUBSTITUTED")
    done

    feature__parsed_scenario_add "$expanded_name" "$feature_tags_name" "$scenario_tags_name" "$background_steps_name" "$background_lines_name" expanded_steps "$scenario_lines_name"
  done
}

feature__outline_substitute() {
  local value=$1
  local -n headings_ref=$2
  local -n cells_ref=$3
  local placeholder_regex='<[^>]+>'
  local pattern
  local index

  for index in "${!headings_ref[@]}"; do
    pattern="<${headings_ref[$index]}>"
    value=${value//"$pattern"/"${cells_ref[$index]}"}
  done

  FEATURE_OUTLINE_SUBSTITUTED=$value
  FEATURE_OUTLINE_MISSING_PLACEHOLDER=
  if [[ $value =~ $placeholder_regex ]]; then
    FEATURE_OUTLINE_MISSING_PLACEHOLDER=${BASH_REMATCH[0]}
    return 1
  fi
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
