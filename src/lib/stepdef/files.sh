## Collects step definition files from a step definitions directory.
stepdefs_files_find() {
  local stepdefs_dir=$1

  readarray -t STEPDEF_FILES < <(find "$stepdefs_dir" -maxdepth 1 -type f \( -name '*.sh' -o -name '*.bash' \) | sort)
}

## Parses one step definition file and registers its step bodies.
stepdefs_file_parse() {
  local file=$1
  local line
  local trimmed_line
  local next_type=
  local next_pattern=
  local next_regex=
  local next_tokens=
  local next_capture_indexes=
  local parsed_new_header=0
  local current_type=
  local current_pattern=
  local current_regex=
  local current_tokens=
  local current_capture_indexes=
  local current_body=

  while IFS= read -r line || [[ -n $line ]]; do
    trimmed_line=$(trim "$line")

    parsed_new_header=0
    if [[ $trimmed_line == @* ]]; then
      if stepdef_parse "$trimmed_line"; then
        parsed_new_header=1
        next_type=$STEPDEF_TYPE
        next_pattern=$STEPDEF_PATTERN
        next_regex=$STEPDEF_REGEX
        next_tokens=$STEPDEF_TOKENS
        next_capture_indexes=$STEPDEF_CAPTURE_INDEXES
      elif [[ -z $current_type ]]; then
        return 1
      fi
    fi

    if ((parsed_new_header != 0)); then
      if [[ -n $current_type ]]; then
        STEPDEF_TYPE=$current_type
        STEPDEF_PATTERN=$current_pattern
        STEPDEF_REGEX=$current_regex
        STEPDEF_TOKENS=$current_tokens
        STEPDEF_CAPTURE_INDEXES=$current_capture_indexes
        stepdef_register "$current_body"
      fi

      current_type=$next_type
      current_pattern=$next_pattern
      current_regex=$next_regex
      current_tokens=$next_tokens
      current_capture_indexes=$next_capture_indexes
      current_body=
      continue
    fi

    if [[ -z $current_type ]]; then
      continue
    fi

    if [[ -n $current_body ]]; then
      current_body+=$'\n'
    fi
    current_body+=$line
  done <"$file"

  if [[ -n $current_type ]]; then
    STEPDEF_TYPE=$current_type
    STEPDEF_PATTERN=$current_pattern
    STEPDEF_REGEX=$current_regex
    STEPDEF_TOKENS=$current_tokens
    STEPDEF_CAPTURE_INDEXES=$current_capture_indexes
    stepdef_register "$current_body"
  fi
}
