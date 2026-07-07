## Converts a tokenized step pattern into a regular expression.
pattern_regex() {
  local pattern=$1
  local capture_index=0
  local compiled=
  local remainder=$pattern
  local literal
  local quote
  local quote_group

  while [[ $remainder =~ ^([^{}]*)\{([A-Za-z_][A-Za-z0-9_]*)\}(.*)$ ]]; do
    literal=${BASH_REMATCH[1]}
    remainder=${BASH_REMATCH[3]}

    quote=
    if [[ $literal == *\' && $remainder == \'* ]]; then
      quote="'"
    elif [[ $literal == *\" && $remainder == \"* ]]; then
      quote='"'
    fi

    if [[ -n $quote ]]; then
      literal=${literal%?}
      remainder=${remainder#?}
      ((capture_index += 1))
      quote_group=$capture_index

      compiled+=$(_pattern_escape_literal "$literal")
      compiled+='(['\''"])'
      compiled+="(.+)\\$quote_group"
      ((capture_index += 1))
      continue
    fi

    compiled+=$(_pattern_escape_literal "$literal")
    compiled+="(.+)"
    ((capture_index += 1))
  done

  compiled+=$(_pattern_escape_literal "$remainder")

  printf '%s' "$compiled"
}

## Extracts token names from a tokenized step pattern.
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

## Extracts capture group indexes for named tokens in a tokenized step pattern.
pattern_capture_indexes() {
  local pattern=$1
  local capture_index=0
  local remainder=$pattern
  local literal
  local quote
  local indexes=()

  while [[ $remainder =~ ^([^{}]*)\{([A-Za-z_][A-Za-z0-9_]*)\}(.*)$ ]]; do
    literal=${BASH_REMATCH[1]}
    remainder=${BASH_REMATCH[3]}

    quote=
    if [[ $literal == *\' && $remainder == \'* ]]; then
      quote="'"
    elif [[ $literal == *\" && $remainder == \"* ]]; then
      quote='"'
    fi

    if [[ -n $quote ]]; then
      remainder=${remainder#?}
      ((capture_index += 2))
      indexes+=("$capture_index")
      continue
    fi

    ((capture_index += 1))
    indexes+=("$capture_index")
  done

  printf '%s' "${indexes[*]}"
}

## Escapes literal text so it can be embedded in a regular expression.
_pattern_escape_literal() {
  printf '%s' "$1" | sed -e 's/[][(){}.^$+?|\\]/\\&/g'
}
