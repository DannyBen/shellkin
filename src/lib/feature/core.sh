## Executes all scenarios in a feature file.
feature_run() {
  local feature_file=$1
  local scenario_index
  local step_index
  local start
  local count
  local feature_output_started=0
  local failed=0
  local -a background_steps=()
  local -a scenario_steps=()

  FEATURE_FILE=$feature_file
  feature_parse "$feature_file" || return 1

  for scenario_index in "${!FEATURE_PARSED_SCENARIO_NAMES[@]}"; do
    start=${FEATURE_PARSED_SCENARIO_STEP_STARTS[$scenario_index]}
    count=${FEATURE_PARSED_SCENARIO_STEP_COUNTS[$scenario_index]}
    scenario_steps=()
    for ((step_index = start; step_index < start + count; step_index++)); do
      scenario_steps+=("${FEATURE_PARSED_STEPS[$step_index]}")
    done

    FEATURE_SCENARIO_TAGS=${FEATURE_PARSED_SCENARIO_TAGS[$scenario_index]}
    if feature_scenario_run "${FEATURE_PARSED_SCENARIO_NAMES[$scenario_index]}" background_steps scenario_steps; then
      :
    else
      failed=1
      if ((TEST_FAIL_FAST != 0 || TEST_ABORT_RUN != 0)); then
        TEST_ABORT_RUN=1
        break
      fi
    fi
  done

  return "$failed"
}

## Splits a recorded step into keyword, text, and optional doc string.
feature__recorded_step_parse() {
  local recorded=$1
  local remainder

  recorded=${recorded%%$'\x1e'*}

  FEATURE_RECORDED_STEP_KEYWORD=${recorded%%$'\t'*}
  remainder=${recorded#*$'\t'}
  FEATURE_RECORDED_STEP_DOC_STRING=

  if [[ $remainder == *$'\t'* ]]; then
    FEATURE_RECORDED_STEP_TEXT=${remainder%%$'\t'*}
    FEATURE_RECORDED_STEP_DOC_STRING=${remainder#*$'\t'}
  else
    FEATURE_RECORDED_STEP_TEXT=$remainder
  fi
}

## Validates that a recorded step can be resolved and matched.
feature_recorded_step_validate() {
  local recorded=$1
  local previous_type=$2
  local resolved_type

  feature_table_validate "$recorded" || return 1
  feature__recorded_step_parse "$recorded"

  resolved_type=$(feature_step_type_resolve "$previous_type" "$FEATURE_RECORDED_STEP_KEYWORD") || return 1
  FEATURE_PREVIOUS_STEP_TYPE=$resolved_type
  step_match "$resolved_type" "$FEATURE_RECORDED_STEP_TEXT"
}

## Executes a recorded step and reports its result.
feature_recorded_step_run() {
  local recorded=$1
  local previous_type=$2
  local resolved_type
  local status

  feature__recorded_step_parse "$recorded"

  resolved_type=$(feature_step_type_resolve "$previous_type" "$FEATURE_RECORDED_STEP_KEYWORD") || return 1
  FEATURE_PREVIOUS_STEP_TYPE=$resolved_type
  export DOC_STRING=
  if [[ -n $FEATURE_RECORDED_STEP_DOC_STRING ]]; then
    export DOC_STRING=$FEATURE_RECORDED_STEP_DOC_STRING
  fi
  feature_table_export "$recorded" || return 1

  step_run "$resolved_type" "$FEATURE_RECORDED_STEP_TEXT"
  status=$?
  output_step_result "$status" "$FEATURE_RECORDED_STEP_KEYWORD" "$FEATURE_RECORDED_STEP_TEXT"
  return "$status"
}

## Stores the current feature validation error details.
feature_validation_set_error() {
  local line_number=$1
  local message=$2
  local context_line=${3:-}

  FEATURE_VALIDATION_LINE=$line_number
  FEATURE_VALIDATION_MESSAGE=$message
  FEATURE_VALIDATION_CONTEXT=$context_line
}

## Validates that all recorded steps in a scenario have matching step definitions.
feature_scenario_validate() {
  local -n background_steps_ref=$1
  local -n background_lines_ref=$2
  local -n scenario_steps_ref=$3
  local -n scenario_lines_ref=$4
  local step
  local index

  ((VALIDATION_SCENARIOS_INDEX += 1))
  if [[ -n ${TARGET_SCENARIO_NUMBER:-} && $VALIDATION_SCENARIOS_INDEX -ne $TARGET_SCENARIO_NUMBER ]]; then
    return 0
  fi

  TARGET_SCENARIO_MATCHED=1
  FEATURE_PREVIOUS_STEP_TYPE=

  for index in "${!background_steps_ref[@]}"; do
    step=${background_steps_ref[$index]}
    if ! feature_table_validate "$step"; then
      feature__recorded_step_parse "$step"
      feature_validation_set_error "${background_lines_ref[$index]}" "data table rows must have the same number of cells for" "$FEATURE_RECORDED_STEP_KEYWORD $FEATURE_RECORDED_STEP_TEXT"
      return 1
    fi
    if feature_recorded_step_validate "$step" "$FEATURE_PREVIOUS_STEP_TYPE"; then
      :
    else
      feature__recorded_step_parse "$step"
      feature_validation_set_error "${background_lines_ref[$index]}" "no matching step definition for" "$FEATURE_RECORDED_STEP_KEYWORD $FEATURE_RECORDED_STEP_TEXT"
      return 1
    fi
  done

  for index in "${!scenario_steps_ref[@]}"; do
    step=${scenario_steps_ref[$index]}
    if ! feature_table_validate "$step"; then
      feature__recorded_step_parse "$step"
      feature_validation_set_error "${scenario_lines_ref[$index]}" "data table rows must have the same number of cells for" "$FEATURE_RECORDED_STEP_KEYWORD $FEATURE_RECORDED_STEP_TEXT"
      return 1
    fi
    if feature_recorded_step_validate "$step" "$FEATURE_PREVIOUS_STEP_TYPE"; then
      :
    else
      feature__recorded_step_parse "$step"
      feature_validation_set_error "${scenario_lines_ref[$index]}" "no matching step definition for" "$FEATURE_RECORDED_STEP_KEYWORD $FEATURE_RECORDED_STEP_TEXT"
      return 1
    fi
  done
}

## Validates the structure and step coverage of a feature file.
feature_validate() {
  local feature_file=$1
  local scenario_index
  local step_index
  local start
  local count
  local -a background_steps=()
  local -a background_step_lines=()
  local -a scenario_steps=()
  local -a scenario_step_lines=()

  feature_parse "$feature_file" || return 1

  for scenario_index in "${!FEATURE_PARSED_SCENARIO_NAMES[@]}"; do
    start=${FEATURE_PARSED_SCENARIO_STEP_STARTS[$scenario_index]}
    count=${FEATURE_PARSED_SCENARIO_STEP_COUNTS[$scenario_index]}
    scenario_steps=()
    scenario_step_lines=()
    for ((step_index = start; step_index < start + count; step_index++)); do
      scenario_steps+=("${FEATURE_PARSED_STEPS[$step_index]}")
      scenario_step_lines+=("${FEATURE_PARSED_STEP_LINES[$step_index]}")
    done

    feature_scenario_validate background_steps background_step_lines scenario_steps scenario_step_lines || return 1
  done
}

## Runs one scenario together with its background steps.
feature_scenario_run() {
  local scenario_name=$1
  local -n background_steps_ref=$2
  local -n scenario_steps_ref=$3
  local scenario_number
  local step
  local scenario_failed=0
  local skip_remaining=0

  ((TEST_SCENARIOS_INDEX += 1))
  scenario_number=$TEST_SCENARIOS_INDEX
  if [[ -n ${TARGET_SCENARIO_NUMBER:-} && $scenario_number -ne $TARGET_SCENARIO_NUMBER ]]; then
    return 0
  fi

  TARGET_SCENARIO_MATCHED=1
  feature__scenario_tag_match || return 0

  ((TEST_SCENARIOS_TOTAL += 1))
  FEATURE_PREVIOUS_STEP_TYPE=
  SCENARIO_DEFERRED_COMMANDS=()
  if [[ -n ${FEATURE_NAME:-} && ${feature_output_started:-1} -eq 0 ]]; then
    output_feature_start "$FEATURE_NAME"
    feature_output_started=1
  fi
  output_scenario_start "$scenario_number" "$scenario_name"

  set +e
  if ((${ALL_HOOKS_ACTIVE:-0} == 0)); then
    if hooks__run_before_all; then
      ALL_HOOKS_ACTIVE=1
    else
      scenario_failed=1
      TEST_ABORT_RUN=1
      output_hook_failure "$HOOK_FAILED_HEADER"
      set -e
      ((TEST_SCENARIOS_FAILED += 1))
      return 1
    fi
  fi

  if hooks__run_before_scenario; then
    :
  else
    scenario_failed=1
    skip_remaining=1
    output_hook_failure "$HOOK_FAILED_HEADER"
  fi

  for step in "${background_steps_ref[@]}"; do
    if ((skip_remaining != 0)); then
      feature__recorded_step_parse "$step"
      output_step_skipped "$FEATURE_RECORDED_STEP_KEYWORD" "$FEATURE_RECORDED_STEP_TEXT"
      continue
    fi

    if feature_recorded_step_run "$step" "$FEATURE_PREVIOUS_STEP_TYPE"; then
      :
    else
      scenario_failed=1
      skip_remaining=1
    fi
  done
  for step in "${scenario_steps_ref[@]}"; do
    if ((skip_remaining != 0)); then
      feature__recorded_step_parse "$step"
      output_step_skipped "$FEATURE_RECORDED_STEP_KEYWORD" "$FEATURE_RECORDED_STEP_TEXT"
      continue
    fi

    if feature_recorded_step_run "$step" "$FEATURE_PREVIOUS_STEP_TYPE"; then
      :
    else
      scenario_failed=1
      skip_remaining=1
    fi
  done

  if hooks__run_after_scenario; then
    :
  else
    scenario_failed=1
    output_hook_failure "$HOOK_FAILED_HEADER"
  fi

  if defer__run_all; then
    :
  else
    scenario_failed=1
    output_deferred_failure
  fi
  set -e

  if ((scenario_failed != 0)); then
    ((TEST_SCENARIOS_FAILED += 1))
  fi

  return "$scenario_failed"
}

## Attaches a parsed doc string to the previous recorded step.
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

feature_tags_validate() {
  local tag

  FEATURE_TAG_ERROR=
  for tag in "$@"; do
    if feature__tag_valid "$tag"; then
      :
    else
      FEATURE_TAG_ERROR="invalid tag: $tag"
      return 1
    fi
  done
}

feature__tags_parse() {
  local text=$1
  local -n tags_ref=$2
  local tag

  tags_ref=()
  for tag in $text; do
    feature__tag_valid "$tag" || return 1
    tags_ref+=("$tag")
  done

  ((${#tags_ref[@]} > 0))
}

feature__scenario_tags_set() {
  local -n feature_tags_ref=$1
  local -n scenario_tags_ref=$2
  local tag
  local -a tags=()

  FEATURE_SCENARIO_TAGS=

  for tag in "${feature_tags_ref[@]}" "${scenario_tags_ref[@]}"; do
    feature__tags_include tags "$tag" && continue
    tags+=("$tag")
  done

  ((${#tags[@]} == 0)) && return 0
  printf -v FEATURE_SCENARIO_TAGS '%s ' "${tags[@]}"
  FEATURE_SCENARIO_TAGS=${FEATURE_SCENARIO_TAGS% }
}

feature__tags_include() {
  # shellcheck disable=SC2178  # nameref to an array variable by name
  local -n tags_ref=$1
  local expected=$2
  local tag

  for tag in "${tags_ref[@]}"; do
    [[ $tag == "$expected" ]] && return 0
  done

  return 1
}

feature__tag_valid() {
  [[ $1 =~ ^@[[:alnum:]_][[:alnum:]_.:-]*$ ]]
}

feature__scenario_tag_match() {
  local tag
  local include_matched=0
  local -a include_tags=()
  local -a exclude_tags=()
  local -a scenario_tags=()

  if declare -p TEST_INCLUDE_TAGS >/dev/null 2>&1; then
    include_tags=("${TEST_INCLUDE_TAGS[@]}")
  fi
  if declare -p TEST_EXCLUDE_TAGS >/dev/null 2>&1; then
    exclude_tags=("${TEST_EXCLUDE_TAGS[@]}")
  fi

  # shellcheck disable=SC2034  # consumed through nameref by feature__tags_include
  read -r -a scenario_tags <<<"$FEATURE_SCENARIO_TAGS"

  for tag in "${exclude_tags[@]}"; do
    feature__tags_include scenario_tags "$tag" && return 1
  done

  ((${#include_tags[@]} == 0)) && return 0

  for tag in "${include_tags[@]}"; do
    if feature__tags_include scenario_tags "$tag"; then
      include_matched=1
      break
    fi
  done

  ((include_matched != 0))
}
