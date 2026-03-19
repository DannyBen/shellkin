features_dir="$(
  CDPATH= cd "${args['dir']}" >/dev/null
  printf '%s' "$PWD"
)"
stepdefs_dir="$features_dir/step_definitions"
feature_status=0
SHELLKIN_ROOT="$(
  CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null
  printf '%s' "$PWD"
)"

STEPDEF_TYPES=()
STEPDEF_PATTERNS=()
STEPDEF_REGEXES=()
STEPDEF_TOKENS_LIST=()
STEPDEF_BODIES=()

readarray -t stepdef_files < <(find "$stepdefs_dir" -maxdepth 1 -type f \( -name '*.sh' -o -name '*.bash' \) | sort)
readarray -t feature_files < <(find "$features_dir" -maxdepth 1 -type f -name '*.feature' | sort)

for stepdef_file in "${stepdef_files[@]}"; do
  stepdefs_file_parse "$stepdef_file"
done

for feature_file in "${feature_files[@]}"; do
  feature_run "$feature_file" || feature_status=1
done

return "$feature_status"
