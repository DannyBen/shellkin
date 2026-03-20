target="$(realpath "${args['target']}")"
stepdefs_dir=
feature_status=0

STEPDEF_TYPES=()
STEPDEF_PATTERNS=()
STEPDEF_REGEXES=()
STEPDEF_TOKENS_LIST=()
STEPDEF_BODIES=()
TEST_SCENARIOS_TOTAL=0
TEST_SCENARIOS_FAILED=0

if [[ -f $target ]]; then
  features_dir="$(dirname "$target")"
  feature_files=("$target")
else
  features_dir="$target"
  readarray -t feature_files < <(find "$features_dir" -maxdepth 1 -type f -name '*.feature' | sort)
fi

stepdefs_dir="$features_dir/$SHELLKIN_STEPDEFS_ROOT"

readarray -t stepdef_files < <(find "$stepdefs_dir" -maxdepth 1 -type f \( -name '*.sh' -o -name '*.bash' \) | sort)

for stepdef_file in "${stepdef_files[@]}"; do
  stepdefs_file_parse "$stepdef_file"
done

for feature_file in "${feature_files[@]}"; do
  feature_run "$feature_file" || feature_status=1
done

output_summary "$TEST_SCENARIOS_TOTAL" "$TEST_SCENARIOS_FAILED"

return "$feature_status"
