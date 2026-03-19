validate_test_target() {
  if [[ -f "$1" ]]; then
    [[ $1 == *.feature ]] || echo "$1 must be a .feature file"
    [[ -d "$(dirname "$1")/step_definitions" ]] || echo "$(dirname "$1")/step_definitions must be a directory"
    return 0
  fi

  [[ -d "$1" ]] || echo "$1 must be a directory"
  [[ -d "$1/step_definitions" ]] || echo "$1/step_definitions must be a directory"
}
