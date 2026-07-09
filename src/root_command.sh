target_arg=${args['target']:-}
default_target=${args['--default-target']}
target_input=
target_scenario=
stepdefs_subdir=${args['--stepdefs']}
fail_fast=${args['--fail-fast']:-0}
validate_mode=${args['--validate']:-0}
init_mode=${args['--init']:-0}
load_args=${args['--load']:-}
tag_args=${args['--tag']:-}
exclude_tag_args=${args['--exclude-tag']:-}
load_paths=()
include_tags=()
exclude_tags=()
feature_status=0
validation_status=0
validation_total=0
validation_failed=0
feature_files=()

if [[ -n $load_args ]]; then
  eval "load_paths=( $load_args )"
fi

if [[ -n $tag_args ]]; then
  eval "include_tags=( $tag_args )"
fi

if [[ -n $exclude_tag_args ]]; then
  eval "exclude_tags=( $exclude_tag_args )"
fi

if ! feature_tags_validate "${include_tags[@]}" "${exclude_tags[@]}"; then
  printf 'validation error in TAGS:\n%s\n' "$FEATURE_TAG_ERROR" >&2
  return 1
fi

if ((init_mode != 0)); then
  init_target=${target_arg:-$default_target}

  if init_files_create "$init_target" "$stepdefs_subdir"; then
    return 0
  fi

  printf 'init error:\n%s\n' "$INIT_ERROR" >&2
  return 1
fi

if ! parse_test_target "$target_arg" "$default_target"; then
  printf 'validation error in TARGET:\n%s\n' "$VALIDATION_ERROR" >&2
  return 1
fi

target_input=$TEST_TARGET_PATH
target_scenario=$TEST_TARGET_SCENARIO

if ! validate_test_target "$target_input" "$target_scenario" "$stepdefs_subdir"; then
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
STEPDEF_CAPTURE_INDEXES_LIST=()
STEPDEF_BODIES=()
SHELLKIN_BEFORE_HOOK_TAGS=()
SHELLKIN_BEFORE_HOOK_HEADERS=()
SHELLKIN_BEFORE_HOOK_BODIES=()
SHELLKIN_AFTER_HOOK_TAGS=()
SHELLKIN_AFTER_HOOK_HEADERS=()
SHELLKIN_AFTER_HOOK_BODIES=()

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

support_file_source_if_present "$FEATURES_DIR" support.sh || {
  printf '%s\n' "$SUPPORT_ERROR" >&2
  return 1
}

support_files_source_all "$FEATURES_DIR" "${load_paths[@]}" || {
  printf '%s\n' "$SUPPORT_ERROR" >&2
  return 1
}

stepdefs_files_find "$STEPDEFS_DIR"

if ((validate_mode != 0)); then
  TARGET_SCENARIO_NUMBER=$target_scenario
  TARGET_SCENARIO_MATCHED=0
  VALIDATION_SCENARIOS_INDEX=0

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

  if [[ -n $target_scenario && $validation_status -eq 0 && $TARGET_SCENARIO_MATCHED -eq 0 ]]; then
    printf 'validation error in TARGET:\nscenario number out of range: %s\n' "$target_scenario" >&2
    return 1
  fi

  output_validate_summary "$validation_total" "$validation_failed"
  return "$validation_status"
else
  for stepdef_file in "${STEPDEF_FILES[@]}"; do
    stepdefs_file_parse "$stepdef_file"
  done

  TARGET_SCENARIO_NUMBER=$target_scenario
  TARGET_SCENARIO_MATCHED=0
  TEST_SCENARIOS_INDEX=0
  TEST_SCENARIOS_TOTAL=0
  TEST_SCENARIOS_FAILED=0
  TEST_FAIL_FAST="$fail_fast"
  TEST_INCLUDE_TAGS=("${include_tags[@]}")
  TEST_EXCLUDE_TAGS=("${exclude_tags[@]}")
  TEST_ABORT_RUN=0

  for feature_file in "${feature_files[@]}"; do
    feature_run "$feature_file" || feature_status=1
    if ((TEST_ABORT_RUN != 0)); then
      break
    fi
  done

  if [[ -n $target_scenario && $feature_status -eq 0 && $TARGET_SCENARIO_MATCHED -eq 0 ]]; then
    printf 'validation error in TARGET:\nscenario number out of range: %s\n' "$target_scenario" >&2
    return 1
  fi

  output_summary "$TEST_SCENARIOS_TOTAL" "$TEST_SCENARIOS_FAILED"
  return "$feature_status"
fi
