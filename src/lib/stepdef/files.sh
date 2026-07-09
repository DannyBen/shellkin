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
  local next_header_kind=
  local next_hook_type=
  local next_hook_tag=
  local next_hook_header=
  local parsed_new_header=0
  local current_type=
  local current_pattern=
  local current_regex=
  local current_tokens=
  local current_capture_indexes=
  local current_header_kind=
  local current_hook_type=
  local current_hook_tag=
  local current_hook_header=
  local current_body=

  while IFS= read -r line || [[ -n $line ]]; do
    trimmed_line=$(trim "$line")

    parsed_new_header=0
    if [[ $trimmed_line == @* ]]; then
      if stepdef_parse "$trimmed_line"; then
        parsed_new_header=1
        next_header_kind=$STEPDEF_HEADER_KIND
        next_type=$STEPDEF_TYPE
        next_pattern=$STEPDEF_PATTERN
        next_regex=$STEPDEF_REGEX
        next_tokens=$STEPDEF_TOKENS
        next_capture_indexes=$STEPDEF_CAPTURE_INDEXES
        next_hook_type=$STEPDEF_HOOK_TYPE
        next_hook_tag=$STEPDEF_HOOK_TAG
        next_hook_header=$STEPDEF_HOOK_HEADER
      elif [[ -z $current_header_kind ]]; then
        return 1
      fi
    fi

    if ((parsed_new_header != 0)); then
      if [[ -n $current_header_kind ]]; then
        STEPDEF_HEADER_KIND=$current_header_kind
        STEPDEF_TYPE=$current_type
        STEPDEF_PATTERN=$current_pattern
        STEPDEF_REGEX=$current_regex
        STEPDEF_TOKENS=$current_tokens
        STEPDEF_CAPTURE_INDEXES=$current_capture_indexes
        STEPDEF_HOOK_TYPE=$current_hook_type
        STEPDEF_HOOK_TAG=$current_hook_tag
        STEPDEF_HOOK_HEADER=$current_hook_header
        stepdefs__current_register "$current_body"
      fi

      current_header_kind=$next_header_kind
      current_type=$next_type
      current_pattern=$next_pattern
      current_regex=$next_regex
      current_tokens=$next_tokens
      current_capture_indexes=$next_capture_indexes
      current_hook_type=$next_hook_type
      current_hook_tag=$next_hook_tag
      current_hook_header=$next_hook_header
      current_body=
      continue
    fi

    if [[ -z $current_header_kind ]]; then
      continue
    fi

    if [[ -n $current_body ]]; then
      current_body+=$'\n'
    fi
    current_body+=$line
  done <"$file"

  if [[ -n $current_header_kind ]]; then
    STEPDEF_HEADER_KIND=$current_header_kind
    STEPDEF_TYPE=$current_type
    STEPDEF_PATTERN=$current_pattern
    STEPDEF_REGEX=$current_regex
    STEPDEF_TOKENS=$current_tokens
    STEPDEF_CAPTURE_INDEXES=$current_capture_indexes
    STEPDEF_HOOK_TYPE=$current_hook_type
    STEPDEF_HOOK_TAG=$current_hook_tag
    STEPDEF_HOOK_HEADER=$current_hook_header
    stepdefs__current_register "$current_body"
  fi
}

stepdefs__current_register() {
  local body=$1

  case $STEPDEF_HEADER_KIND in
    step)
      stepdef_register "$body"
      ;;
    hook)
      stepdef_hook_register "$body"
      ;;
  esac
}
