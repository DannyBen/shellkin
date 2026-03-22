## Classifies one feature file line and stores its parsed parts.
feature_line_parse() {
  local line

  line=$(trim "$1")

  FEATURE_LINE_KIND=
  FEATURE_LINE_NAME=
  FEATURE_STEP_TYPE=
  FEATURE_STEP_TEXT=

  if [[ -z $line ]]; then
    FEATURE_LINE_KIND=blank
    return 0
  fi

  if [[ $line == \#* ]]; then
    FEATURE_LINE_KIND=comment
    return 0
  fi

  if [[ $line =~ ^Feature:[[:space:]]*(.*)$ ]]; then
    FEATURE_LINE_KIND=feature
    FEATURE_LINE_NAME=${BASH_REMATCH[1]}
    return 0
  fi

  if [[ $line =~ ^Background:[[:space:]]*$ ]]; then
    FEATURE_LINE_KIND=background
    return 0
  fi

  if [[ $line =~ ^Scenario:[[:space:]]*(.*)$ ]]; then
    FEATURE_LINE_KIND=scenario
    FEATURE_LINE_NAME=${BASH_REMATCH[1]}
    return 0
  fi

  if [[ $line =~ ^(Given|When|Then|And|But|\*)[[:space:]]+(.+)$ ]]; then
    FEATURE_LINE_KIND=step
    FEATURE_STEP_TYPE=${BASH_REMATCH[1]}
    FEATURE_STEP_TEXT=${BASH_REMATCH[2]}
    return 0
  fi

  if [[ $line == '"""' ]]; then
    FEATURE_LINE_KIND=doc_string_fence
    return 0
  fi

  FEATURE_LINE_KIND=other
  FEATURE_LINE_NAME=$line
}

## Resolves And, But, and * step types to the previous concrete type.
feature_step_type_resolve() {
  local previous_type=$1
  local current_type=$2

  case $current_type in
    And | But | '*')
      [[ -n $previous_type ]] || return 1
      printf '%s' "$previous_type"
      ;;
    *)
      printf '%s' "$current_type"
      ;;
  esac
}
