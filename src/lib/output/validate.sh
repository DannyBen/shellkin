## Converts a feature file path to a display path relative to the target root.
validation_feature_relpath() {
  local file=$1

  if [[ $file == "$VALIDATION_FEATURES_DIR/"* ]]; then
    printf '%s' "${file#"$VALIDATION_FEATURES_DIR"/}"
  else
    basename "$file"
  fi
}

## Converts a step definition file path to a display path relative to the stepdefs root.
validation_stepdef_relpath() {
  local file=$1

  if [[ $file == "$VALIDATION_STEPDEFS_DIR/"* ]]; then
    printf '%s' "${file#"$VALIDATION_STEPDEFS_DIR"/}"
  else
    basename "$file"
  fi
}

## Prints the heading for one validation target.
output_validate_file_start() {
  local label=$1
  local path=$2

  bold "\n$label: $path"
}

## Prints a passing validation result line.
output_validate_ok() {
  green "  ✓ $1"
}

## Prints a failing validation result line.
output_validate_fail() {
  red "  ✗ $1"
}

## Prints one indented validation detail line.
output_validate_detail() {
  local detail=$1

  printf '    %s\n' "$detail"
}

## Prints one highlighted source line for validation context.
output_validate_source_line() {
  local source_line=$1

  blue "    $source_line"
}

## Prints the final summary for a validation run.
output_validate_summary() {
  local total_files=$1
  local failed_files=$2
  local passed_files=$((total_files - failed_files))
  local label

  label=$(
    if ((total_files == 1)); then
      printf '%s' "file"
    else
      printf '%s' "files"
    fi
  )

  if ((failed_files == 0)); then
    green_bold "\nvalidation passed: $total_files $label checked"
    return 0
  fi

  red_bold "\nvalidation failed: $passed_files passing, $failed_files failing"
}
