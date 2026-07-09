## Checks whether a step definition type is supported.
stepdef_type_valid() {
  case $1 in
    Given | When | Then)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

## Appends the current parsed step definition to the registry arrays.
stepdef_register() {
  local body=$1

  STEPDEF_TYPES+=("$STEPDEF_TYPE")
  STEPDEF_PATTERNS+=("$STEPDEF_PATTERN")
  STEPDEF_REGEXES+=("$STEPDEF_REGEX")
  STEPDEF_TOKENS_LIST+=("$STEPDEF_TOKENS")
  STEPDEF_CAPTURE_INDEXES_LIST+=("$STEPDEF_CAPTURE_INDEXES")
  STEPDEF_BODIES+=("$body")
}

## Parses one step definition header into reusable fields.
stepdef_parse() {
  local line=$1
  local keyword
  local remainder
  local pattern

  STEPDEF_HEADER_KIND=
  STEPDEF_TYPE=
  STEPDEF_PATTERN=
  STEPDEF_REGEX=
  STEPDEF_TOKENS=
  STEPDEF_CAPTURE_INDEXES=
  STEPDEF_HOOK_TYPE=
  STEPDEF_HOOK_TAG=
  STEPDEF_HOOK_HEADER=

  if [[ ! $line =~ ^@([A-Za-z]+)([[:space:]]+(.*))?$ ]]; then
    return 1
  fi

  keyword=${BASH_REMATCH[1]}
  remainder=${BASH_REMATCH[3]:-}

  if stepdef_type_valid "$keyword"; then
    [[ -n $remainder ]] || return 1

    pattern=$remainder
    STEPDEF_HEADER_KIND=step
    STEPDEF_TYPE=$keyword
    STEPDEF_PATTERN=$pattern
    STEPDEF_REGEX=$(pattern_regex "$pattern")
    STEPDEF_TOKENS=$(pattern_tokens "$pattern")
    STEPDEF_CAPTURE_INDEXES=$(pattern_capture_indexes "$pattern")
    return 0
  fi

  if stepdef_hook_type_valid "$keyword"; then
    if [[ -n $remainder ]]; then
      stepdef_hook_tag_allowed "$keyword" || return 1
      stepdef_hook_tag_valid "$remainder" || return 1
    fi

    STEPDEF_HEADER_KIND=hook
    STEPDEF_HOOK_TYPE=$keyword
    STEPDEF_HOOK_TAG=$remainder
    STEPDEF_HOOK_HEADER="@$keyword"
    if [[ -n $remainder ]]; then
      STEPDEF_HOOK_HEADER+=" $remainder"
    fi
    return 0
  fi

  return 1
}

stepdef_hook_type_valid() {
  case $1 in
    Before | After | BeforeAll | AfterAll)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

stepdef_hook_tag_allowed() {
  case $1 in
    Before | After)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

stepdef_hook_tag_valid() {
  [[ $1 =~ ^@[[:alnum:]_][[:alnum:]_.:-]*$ ]]
}
