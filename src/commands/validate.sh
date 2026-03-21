target="$(realpath "${args['target']}")"
stepdefs_dir=
support_status=0
validation_status=0
validation_total=0
validation_failed=0

STEPDEF_TYPES=()
STEPDEF_PATTERNS=()
STEPDEF_REGEXES=()
STEPDEF_TOKENS_LIST=()
STEPDEF_BODIES=()

if [[ -f $target ]]; then
  features_dir="$(dirname "$target")"
  feature_files=("$target")
else
  features_dir="$target"
  readarray -t feature_files < <(find "$features_dir" -maxdepth 1 -type f -name '*.feature' | sort)
fi

stepdefs_dir="$features_dir/$SHELLKIN_STEPDEFS_ROOT"
VALIDATION_FEATURES_DIR="$features_dir"
VALIDATION_STEPDEFS_DIR="$stepdefs_dir"

support_file_source "$features_dir" || support_status=1

if ((support_status != 0)); then
  return "$support_status"
fi

readarray -t stepdef_files < <(find "$stepdefs_dir" -maxdepth 1 -type f \( -name '*.sh' -o -name '*.bash' \) | sort)

for stepdef_file in "${stepdef_files[@]}"; do
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
