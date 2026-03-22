## Validates that a target path and step definitions directory are usable.
validate_test_target() {
  local target=$1
  local stepdefs_dir=$2
  local features_dir
  local -a errors=()

  VALIDATION_ERROR=

  if [[ -f "$target" ]]; then
    features_dir=$(dirname "$target")
    [[ $target == *.feature ]] || errors+=("$target must be a .feature file or a directory")
    [[ -d "$features_dir/$stepdefs_dir" ]] || errors+=("$features_dir/$stepdefs_dir must be a directory")
  else
    [[ -d "$target" ]] || errors+=("$target must be a directory")
    [[ -d "$target/$stepdefs_dir" ]] || errors+=("$target/$stepdefs_dir must be a directory")
  fi

  if ((${#errors[@]} != 0)); then
    VALIDATION_ERROR=$(printf '%s\n' "${errors[@]}")
    return 1
  fi
}
