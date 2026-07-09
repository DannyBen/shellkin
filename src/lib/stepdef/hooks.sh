## Registers a parsed scenario hook body.
stepdef_hook_register() {
  local body=$1

  case $STEPDEF_HOOK_TYPE in
    BeforeAll)
      SHELLKIN_BEFORE_ALL_HOOK_HEADERS+=("$STEPDEF_HOOK_HEADER")
      SHELLKIN_BEFORE_ALL_HOOK_BODIES+=("$body")
      ;;
    Before)
      SHELLKIN_BEFORE_HOOK_TAGS+=("$STEPDEF_HOOK_TAG")
      SHELLKIN_BEFORE_HOOK_HEADERS+=("$STEPDEF_HOOK_HEADER")
      SHELLKIN_BEFORE_HOOK_BODIES+=("$body")
      ;;
    After)
      SHELLKIN_AFTER_HOOK_TAGS+=("$STEPDEF_HOOK_TAG")
      SHELLKIN_AFTER_HOOK_HEADERS+=("$STEPDEF_HOOK_HEADER")
      SHELLKIN_AFTER_HOOK_BODIES+=("$body")
      ;;
    AfterAll)
      SHELLKIN_AFTER_ALL_HOOK_HEADERS+=("$STEPDEF_HOOK_HEADER")
      SHELLKIN_AFTER_ALL_HOOK_BODIES+=("$body")
      ;;
  esac
}

hooks__run_before_all() {
  local index
  local hook_header
  local body

  HOOK_FAILED_HEADER=

  for index in "${!SHELLKIN_BEFORE_ALL_HOOK_BODIES[@]}"; do
    hook_header=${SHELLKIN_BEFORE_ALL_HOOK_HEADERS[$index]}
    body=${SHELLKIN_BEFORE_ALL_HOOK_BODIES[$index]}
    hooks__run_one "$hook_header" "$body" || return 1
  done
}

hooks__run_after_all() {
  local index
  local hook_header
  local body
  local failed=0

  HOOK_FAILED_HEADER=

  for index in "${!SHELLKIN_AFTER_ALL_HOOK_BODIES[@]}"; do
    hook_header=${SHELLKIN_AFTER_ALL_HOOK_HEADERS[$index]}
    body=${SHELLKIN_AFTER_ALL_HOOK_BODIES[$index]}
    if hooks__run_one "$hook_header" "$body"; then
      :
    else
      failed=1
    fi
  done

  return "$failed"
}

hooks__run_before_scenario() {
  local index
  local tag
  local hook_header
  local body

  HOOK_FAILED_HEADER=

  for index in "${!SHELLKIN_BEFORE_HOOK_BODIES[@]}"; do
    tag=${SHELLKIN_BEFORE_HOOK_TAGS[$index]}
    hooks__matches_scenario "$tag" || continue

    hook_header=${SHELLKIN_BEFORE_HOOK_HEADERS[$index]}
    body=${SHELLKIN_BEFORE_HOOK_BODIES[$index]}
    hooks__run_one "$hook_header" "$body" || return 1
  done
}

hooks__run_after_scenario() {
  local index
  local tag
  local hook_header
  local body
  local failed=0

  HOOK_FAILED_HEADER=

  for index in "${!SHELLKIN_AFTER_HOOK_BODIES[@]}"; do
    tag=${SHELLKIN_AFTER_HOOK_TAGS[$index]}
    hooks__matches_scenario "$tag" || continue

    hook_header=${SHELLKIN_AFTER_HOOK_HEADERS[$index]}
    body=${SHELLKIN_AFTER_HOOK_BODIES[$index]}
    if hooks__run_one "$hook_header" "$body"; then
      :
    else
      failed=1
    fi
  done

  return "$failed"
}

hooks__run_one() {
  local hook_header=$1
  local body=$2

  FAIL_MESSAGE=
  DOC_STRING=
  export FAIL_MESSAGE DOC_STRING

  eval "$body" || {
    HOOK_FAILED_HEADER=$hook_header
    if [[ -z ${FAIL_MESSAGE:-} ]]; then
      FAIL_MESSAGE="hook failed: $hook_header"
      export FAIL_MESSAGE
    fi
    return 1
  }
}

hooks__matches_scenario() {
  local tag=$1
  local -a scenario_tags=()

  [[ -n $tag ]] || return 0

  # shellcheck disable=SC2034  # consumed through nameref by hooks__tags_include
  read -r -a scenario_tags <<<"${FEATURE_SCENARIO_TAGS:-}"
  hooks__tags_include scenario_tags "$tag"
}

hooks__tags_include() {
  # shellcheck disable=SC2178  # nameref to an array variable by name
  local -n tags_ref=$1
  local expected=$2
  local tag

  for tag in "${tags_ref[@]}"; do
    [[ $tag == "$expected" ]] && return 0
  done

  return 1
}
