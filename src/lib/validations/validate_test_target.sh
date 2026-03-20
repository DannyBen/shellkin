validate_test_target() {
  local features_dir

  if [[ -f "$1" ]]; then
    features_dir=$(dirname "$1")
    [[ $1 == *.feature ]] || echo "$1 must be a .feature file"
    [[ -d "$features_dir/$SHELLKIN_STEPDEFS_ROOT" ]] || echo "$features_dir/$SHELLKIN_STEPDEFS_ROOT must be a directory"
    return 0
  fi

  [[ -d "$1" ]] || echo "$1 must be a directory"
  [[ -d "$1/$SHELLKIN_STEPDEFS_ROOT" ]] || echo "$1/$SHELLKIN_STEPDEFS_ROOT must be a directory"
}
