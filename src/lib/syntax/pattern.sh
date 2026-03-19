pattern_regex() {
  local pattern=$1
  local compiled=
  local remainder=$pattern
  local literal

  while [[ $remainder =~ ^([^{}]*)\{([A-Za-z_][A-Za-z0-9_]*)\}(.*)$ ]]; do
    literal=${BASH_REMATCH[1]}
    remainder=${BASH_REMATCH[3]}

    compiled+=$(_pattern_escape_literal "$literal")
    compiled+="(.+)"
  done

  compiled+=$(_pattern_escape_literal "$remainder")

  printf '%s' "$compiled"
}

pattern_tokens() {
  local pattern=$1
  local remainder=$pattern
  local tokens=()

  while [[ $remainder =~ ^([^{}]*)\{([A-Za-z_][A-Za-z0-9_]*)\}(.*)$ ]]; do
    tokens+=("${BASH_REMATCH[2]}")
    remainder=${BASH_REMATCH[3]}
  done

  printf '%s' "${tokens[*]}"
}

_pattern_escape_literal() {
  printf '%s' "$1" | sed -e 's/[][(){}.^$+?|\\]/\\&/g'
}
