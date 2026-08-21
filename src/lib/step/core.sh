## Checks whether any registered step definition matches a step.
step_match() {
  local type=$1
  local text=$2
  local i
  local step_type

  for i in "${!STEPDEF_TYPES[@]}"; do
    step_type=${STEPDEF_TYPES[$i]}
    [[ $step_type == "$type" ]] || continue

    if [[ $text =~ ${STEPDEF_REGEXES[$i]} ]]; then
      return 0
    fi
  done

  return 1
}

## Executes the first registered step definition that matches a step.
step_run() {
  local type=$1
  local text=$2
  local i
  local j
  local step_type
  local body
  local capture_index
  local capture_value
  local -a tokens=()
  local -a capture_indexes=()

  FAIL_MESSAGE=
  export FAIL_MESSAGE

  for i in "${!STEPDEF_TYPES[@]}"; do
    step_type=${STEPDEF_TYPES[$i]}
    [[ $step_type == "$type" ]] || continue

    if [[ $text =~ ${STEPDEF_REGEXES[$i]} ]]; then
      if [[ -n ${STEPDEF_TOKENS_LIST[$i]} ]]; then
        read -r -a tokens <<<"${STEPDEF_TOKENS_LIST[$i]}"
        read -r -a capture_indexes <<<"${STEPDEF_CAPTURE_INDEXES_LIST[$i]}"
      else
        tokens=()
        capture_indexes=()
      fi

      if ((${#tokens[@]} != ${#capture_indexes[@]})); then
        return 1
      fi

      for j in "${!tokens[@]}"; do
        capture_index=${capture_indexes[$j]}
        if [[ $capture_index == q* ]]; then
          capture_index=${capture_index#q}
          capture_value=${BASH_REMATCH[$capture_index]}
          capture_value=${capture_value:1:-1}
        else
          capture_value=${BASH_REMATCH[$capture_index]}
        fi

        printf -v "${tokens[$j]}" '%s' "$capture_value"
        export "${tokens[$j]}"
      done

      body=${STEPDEF_BODIES[$i]}
      eval "$body"
      return $?
    fi
  done

  FAIL_MESSAGE=$'No matching step definition for:\n'"$type $text"
  export FAIL_MESSAGE
  return 1
}
