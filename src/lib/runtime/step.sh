step_run() {
  local type=$1
  local text=$2
  local i
  local j
  local step_type
  local body
  local -a tokens=()

  for i in "${!STEPDEF_TYPES[@]}"; do
    step_type=${STEPDEF_TYPES[$i]}
    [[ $step_type == "$type" || $step_type == "Step" ]] || continue

    if [[ $text =~ ${STEPDEF_REGEXES[$i]} ]]; then
      if [[ -n ${STEPDEF_TOKENS_LIST[$i]} ]]; then
        read -r -a tokens <<<"${STEPDEF_TOKENS_LIST[$i]}"
      else
        tokens=()
      fi

      if ((${#tokens[@]} != ${#BASH_REMATCH[@]} - 1)); then
        return 1
      fi

      for j in "${!tokens[@]}"; do
        printf -v "${tokens[$j]}" '%s' "${BASH_REMATCH[$((j + 1))]}"
        export "${tokens[$j]}"
      done

      body=${STEPDEF_BODIES[$i]}
      eval "$body"
      return $?
    fi
  done

  return 1
}
