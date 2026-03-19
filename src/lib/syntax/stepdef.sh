stepdef_type_valid() {
  case $1 in
    Given|When|Then|Step)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

stepdef_register() {
  local body=$1

  STEPDEF_TYPES+=("$STEPDEF_TYPE")
  STEPDEF_PATTERNS+=("$STEPDEF_PATTERN")
  STEPDEF_REGEXES+=("$STEPDEF_REGEX")
  STEPDEF_TOKENS_LIST+=("$STEPDEF_TOKENS")
  STEPDEF_BODIES+=("$body")
}

stepdef_parse() {
  local line=$1
  local pattern

  STEPDEF_TYPE=
  STEPDEF_PATTERN=
  STEPDEF_REGEX=
  STEPDEF_TOKENS=

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

  return 0
}
