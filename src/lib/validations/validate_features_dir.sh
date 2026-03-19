validate_features_dir() {
  [[ -d "$1" ]] || echo "$1 must be an directory"
  [[ -d "$1/step_definitions" ]] || echo "$1/step_definitions must be a directory"
}
