validate_features_dir() {
  [[ -d "$1" ]] || echo "must be an existing directory"
  [[ -d "$1/step_definitions" ]] || echo "must have a step_definitions directory"
}
