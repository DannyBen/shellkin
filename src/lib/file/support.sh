support_file_resolve() {
  local features_dir=$1

  SUPPORT_FILE="$features_dir/$SHELLKIN_SUPPORT_FILE"
}

support_file_source() {
  local features_dir=$1

  support_file_resolve "$features_dir"

  if [[ -f $SUPPORT_FILE ]]; then
    # shellcheck disable=SC1090
    source "$SUPPORT_FILE"
  fi
}
