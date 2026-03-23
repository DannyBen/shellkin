## Sources each requested support file relative to the features directory.
support_files_source_all() {
  local features_dir=$1
  shift
  local load_file

  for load_file in "$@"; do
    support__file_source "$features_dir" "$load_file" || return 1
  done
}

## Sources one support file if it exists, otherwise succeeds silently.
support_file_source_if_present() {
  local features_dir=$1
  local load_path=$2

  support__file_resolve "$features_dir" "$load_path" || return 1

  [[ -f $SUPPORT_FILE ]] || return 0

  # shellcheck disable=SC1090
  source "$SUPPORT_FILE"
}

## Resolves one support file path relative to the features directory.
support__file_resolve() {
  local features_dir=$1
  local load_path=$2

  SUPPORT_ERROR=

  if [[ $load_path == /* ]]; then
    SUPPORT_ERROR="load path must be relative to the features directory: $load_path"
    return 1
  fi

  SUPPORT_FILE="$features_dir/$load_path"
}

## Sources one resolved support file or sets SUPPORT_ERROR on failure.
support__file_source() {
  local features_dir=$1
  local load_path=$2

  support__file_resolve "$features_dir" "$load_path" || return 1

  if [[ ! -f $SUPPORT_FILE ]]; then
    SUPPORT_ERROR="load file not found: $load_path"
    return 1
  fi

  # shellcheck disable=SC1090
  source "$SUPPORT_FILE"
}
