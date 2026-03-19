stepdefs_file_parse() {
  local file=$1
  local line
  local trimmed_line
  local current_type=
  local current_pattern=
  local current_regex=
  local current_tokens=
  local current_body=

  while IFS= read -r line || [[ -n $line ]]; do
    trimmed_line=$(trim "$line")

    if [[ $trimmed_line == @* ]]; then
      if [[ -n $current_type ]]; then
        STEPDEF_TYPE=$current_type
        STEPDEF_PATTERN=$current_pattern
        STEPDEF_REGEX=$current_regex
        STEPDEF_TOKENS=$current_tokens
        stepdef_register "$current_body"
      fi

      if ! stepdef_parse "$trimmed_line"; then
        return 1
      fi

      current_type=$STEPDEF_TYPE
      current_pattern=$STEPDEF_PATTERN
      current_regex=$STEPDEF_REGEX
      current_tokens=$STEPDEF_TOKENS
      current_body=
      continue
    fi

    if [[ -z $current_type ]]; then
      continue
    fi

    if [[ -z $trimmed_line && -n $current_body ]]; then
      STEPDEF_TYPE=$current_type
      STEPDEF_PATTERN=$current_pattern
      STEPDEF_REGEX=$current_regex
      STEPDEF_TOKENS=$current_tokens
      stepdef_register "$current_body"

      current_type=
      current_pattern=
      current_regex=
      current_tokens=
      current_body=
      continue
    fi

    if [[ -z $trimmed_line && -z $current_body ]]; then
      continue
    fi

    if [[ -n $current_body ]]; then
      current_body+=$'\n'
    fi
    current_body+=$line
  done < "$file"

  if [[ -n $current_type ]]; then
    STEPDEF_TYPE=$current_type
    STEPDEF_PATTERN=$current_pattern
    STEPDEF_REGEX=$current_regex
    STEPDEF_TOKENS=$current_tokens
    stepdef_register "$current_body"
  fi
}
