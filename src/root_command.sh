target_input=${args['target']:-${args['--default-target']}}
stepdefs_subdir=${args['--stepdefs']}
fail_fast=${args['--fail-fast']:-0}
validate_mode=${args['--validate']:-0}
load_args=${args['--load']:-}
load_paths=()
feature_status=0
validation_status=0
validation_total=0
validation_failed=0
feature_files=()

if [[ -n $load_args ]]; then
  eval "load_paths=( $load_args )"
fi

if ! validate_test_target "$target_input" "$stepdefs_subdir"; then
  printf 'validation error in TARGET:\n%s\n' "$VALIDATION_ERROR" >&2
  return 1
fi

TARGET_PATH=$(realpath "$target_input" 2>/dev/null) || {
  printf 'validation error in TARGET:\nunable to resolve path: %s\n' "$target_input" >&2
  return 1
}

STEPDEF_TYPES=()
STEPDEF_PATTERNS=()
STEPDEF_REGEXES=()
STEPDEF_TOKENS_LIST=()
STEPDEF_BODIES=()

if [[ -f $TARGET_PATH ]]; then
  FEATURES_DIR="$(dirname "$TARGET_PATH")"
  feature_files=("$TARGET_PATH")
else
  FEATURES_DIR="$TARGET_PATH"
  readarray -t feature_files < <(find "$FEATURES_DIR" -maxdepth 1 -type f -name '*.feature' | sort)
fi

STEPDEFS_DIR="$FEATURES_DIR/$stepdefs_subdir"
VALIDATION_FEATURES_DIR="$FEATURES_DIR"
VALIDATION_STEPDEFS_DIR="$STEPDEFS_DIR"

support_files_source_all "$FEATURES_DIR" "${load_paths[@]}" || {
  printf '%s\n' "$SUPPORT_ERROR" >&2
  return 1
}

stepdefs_files_find "$STEPDEFS_DIR"

if ((validate_mode != 0)); then
  for stepdef_file in "${STEPDEF_FILES[@]}"; do
    ((validation_total += 1))
    output_validate_file_start "stepdefs" "$(validation_stepdef_relpath "$stepdef_file")"

    if stepdefs_file_parse "$stepdef_file"; then
      output_validate_ok "step definitions"
    else
      output_validate_fail "step definitions"
      output_validate_detail "invalid step definition file"
      validation_status=1
      ((validation_failed += 1))
    fi
  done

  for feature_file in "${feature_files[@]}"; do
    ((validation_total += 1))
    output_validate_file_start "file" "$(validation_feature_relpath "$feature_file")"

    if feature_validate "$feature_file"; then
      output_validate_ok "feature"
    else
      output_validate_fail "feature"
      if [[ -n ${FEATURE_VALIDATION_LINE:-} ]]; then
        output_validate_detail "line ${FEATURE_VALIDATION_LINE}: ${FEATURE_VALIDATION_MESSAGE}"
      fi
      if [[ -n ${FEATURE_VALIDATION_CONTEXT:-} ]]; then
        output_validate_source_line "${FEATURE_VALIDATION_CONTEXT}"
      elif [[ -n ${FEATURE_VALIDATION_MESSAGE:-} && -z ${FEATURE_VALIDATION_LINE:-} ]]; then
        output_validate_detail "$FEATURE_VALIDATION_MESSAGE"
      fi
      validation_status=1
      ((validation_failed += 1))
    fi
  done

  output_validate_summary "$validation_total" "$validation_failed"
  return "$validation_status"
else
  for stepdef_file in "${STEPDEF_FILES[@]}"; do
    stepdefs_file_parse "$stepdef_file"
  done

  TEST_SCENARIOS_TOTAL=0
  TEST_SCENARIOS_FAILED=0
  TEST_FAIL_FAST="$fail_fast"
  TEST_ABORT_RUN=0

  for feature_file in "${feature_files[@]}"; do
    feature_run "$feature_file" || feature_status=1
    if ((TEST_ABORT_RUN != 0)); then
      break
    fi
  done

  output_summary "$TEST_SCENARIOS_TOTAL" "$TEST_SCENARIOS_FAILED"
  return "$feature_status"
fi
