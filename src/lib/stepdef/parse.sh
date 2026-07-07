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
  local pattern

  STEPDEF_TYPE=
  STEPDEF_PATTERN=
  STEPDEF_REGEX=
  STEPDEF_TOKENS=
  STEPDEF_CAPTURE_INDEXES=

  if [[ ! $line =~ ^@([A-Za-z]+)[[:space:]]+(.+)$ ]]; then
    return 1
  fi

  pattern=${BASH_REMATCH[2]}

  if ! stepdef_type_valid "${BASH_REMATCH[1]}"; then
    return 1
  fi

  STEPDEF_TYPE=${BASH_REMATCH[1]}
  STEPDEF_PATTERN=$pattern
  STEPDEF_REGEX=$(pattern_regex "$pattern")
  STEPDEF_TOKENS=$(pattern_tokens "$pattern")
  STEPDEF_CAPTURE_INDEXES=$(pattern_capture_indexes "$pattern")

  return 0
}
