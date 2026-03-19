#!/usr/bin/env bash
set -uo pipefail
unset CDPATH

declare -a STEP_TYPES=()
declare -a STEP_PATTERNS=()
declare -a STEP_VARS=()
declare -a STEP_BODIES=()
LAST_EXIT_CODE=0
LAST_STDOUT=
LAST_STDERR=
STEP_FAILURE_MESSAGE=

green=$'\033[32m'
red=$'\033[31m'
blue=$'\033[34m'
yellow=$'\033[33m'
bld=$'\033[1m'
reset=$'\033[0m'

trim() {
  local value=$1
  value=${value#"${value%%[![:space:]]*}"}
  value=${value%"${value##*[![:space:]]}"}
  printf '%s' "$value"
}

chdir() {
  cd "$@"
}

fail() {
  local message=${1:-step failed}
  STEP_FAILURE_MESSAGE=$message
  printf '%s\n' "$message" >&2
  return 1
}

run() {
  local command_string=$1
  local stdout_file
  local stderr_file

  stdout_file=$(mktemp)
  stderr_file=$(mktemp)

  set +e
  bash -lc "$command_string" >"$stdout_file" 2>"$stderr_file"
  LAST_EXIT_CODE=$?
  set -e

  LAST_STDOUT=$(<"$stdout_file")
  LAST_STDERR=$(<"$stderr_file")
  rm -f "$stdout_file" "$stderr_file"

  return 0
}

must_run() {
  run "$1"
  ((LAST_EXIT_CODE == 0))
}

register_step() {
  local type=$1
  local pattern=$2
  local vars=$3
  local body=$4

  STEP_TYPES+=("$type")
  STEP_PATTERNS+=("$pattern")
  STEP_VARS+=("$vars")
  STEP_BODIES+=("$body")
}

compile_pattern() {
  local pattern=$1
  local vars=$2
  local compiled=$pattern
  local escaped=
  local -a names=()
  local i

  if [[ -n $vars ]]; then
    read -r -a names <<< "$vars"
  fi

  if [[ $compiled == *'*'* ]]; then
    escaped=$(printf '%s' "$compiled" | sed -e 's/[][(){}.^$+?|\\]/\\&/g')
    for ((i = 0; i < ${#names[@]}; i++)); do
      if [[ $escaped == *'*'* ]]; then
        escaped=${escaped/\*/(.+)}
      fi
    done
    while [[ $escaped == *'*'* ]]; do
      escaped=${escaped/\*/.*}
    done
    printf '%s' "$escaped"
    return 0
  fi

  if ((${#names[@]} > 0)); then
    for ((i = 0; i < ${#names[@]}; i++)); do
      if [[ $compiled == *"'.+'"* ]]; then
        compiled=${compiled/"'.+'"/"'(.+)'"}
        continue
      fi

      if [[ $compiled == *"'.*'"* ]]; then
        compiled=${compiled/"'.*'"/"'(.*)'"}
        continue
      fi
    done
  fi

  printf '%s' "$compiled"
}

parse_stepdefs() {
  local file=$1
  local line
  local current_type=
  local current_pattern=
  local current_vars=
  local current_body=

  while IFS= read -r line || [[ -n $line ]]; do
    if [[ $line =~ ^@([A-Za-z]+)[[:space:]]+\"([^\"]+)\"([[:space:]]+.*)?$ ]]; then
      if [[ -n $current_type ]]; then
        register_step "$current_type" "$current_pattern" "$current_vars" "$current_body"
      fi

      current_type=${BASH_REMATCH[1]}
      current_vars=$(trim "${BASH_REMATCH[3]:-}")
      current_pattern=$(compile_pattern "${BASH_REMATCH[2]}" "$current_vars")
      current_body=
      continue
    fi

    if [[ -z $current_type ]]; then
      continue
    fi

    if [[ -z $line && -n $current_body ]]; then
      register_step "$current_type" "$current_pattern" "$current_vars" "$current_body"
      current_type=
      current_pattern=
      current_vars=
      current_body=
      continue
    fi

    if [[ -z $line && -z $current_body ]]; then
      continue
    fi

    if [[ -n $current_body ]]; then
      current_body+=$'\n'
    fi
    current_body+=$line
  done < "$file"

  if [[ -n $current_type ]]; then
    register_step "$current_type" "$current_pattern" "$current_vars" "$current_body"
  fi
}

run_step_body() {
  local body=$1
  shift

  local var_name
  local var_value
  local trimmed_body
  local command_name
  local command_string
  STEP_FAILURE_MESSAGE=
  LAST_STDOUT=
  LAST_STDERR=
  LAST_EXIT_CODE=0
  while (($#)); do
    var_name=$1
    var_value=$2
    shift 2
    printf -v "$var_name" '%s' "$var_value"
    export "$var_name"
  done

  trimmed_body=$(trim "$body")
  if [[ $trimmed_body =~ ^\"?\$([A-Za-z_][A-Za-z0-9_]*)\"?$ ]]; then
    command_name=${BASH_REMATCH[1]}
    command_string=${!command_name:-}
    eval "$command_string"
    return 0
  fi

  eval "$body"
}

execute_step() {
  local type=$1
  local text=$2
  local i
  local j
  local step_type
  local status
  local -a vars=()
  local -a assignments=()

  for i in "${!STEP_TYPES[@]}"; do
    step_type=${STEP_TYPES[$i]}
    [[ $step_type == "$type" || $step_type == "Step" ]] || continue

    if [[ $text =~ ${STEP_PATTERNS[$i]} ]]; then
      if [[ -n ${STEP_VARS[$i]} ]]; then
        read -r -a vars <<< "${STEP_VARS[$i]}"
      else
        vars=()
      fi

      if ((${#vars[@]} != ${#BASH_REMATCH[@]} - 1)); then
        printf 'Step definition capture mismatch for %s "%s"\n' "$type" "$text" >&2
        printf 'Expected %d captures, got %d\n' "${#vars[@]}" "$((${#BASH_REMATCH[@]} - 1))" >&2
        return 1
      fi

      assignments=()
      for j in "${!vars[@]}"; do
        assignments+=("${vars[$j]}" "${BASH_REMATCH[$((j + 1))]}")
      done

      set +e
      run_step_body "${STEP_BODIES[$i]}" "${assignments[@]}"
      status=$?
      set -e

      if ((status == 0)); then
        printf '    %b%s %s "%s"%b\n' "$green" "✓" "$type" "$text" "$reset"
      else
        printf '    %b%s %s "%s"%b\n' "$red" "✗" "$type" "$text" "$reset" >&2
        if [[ -n $STEP_FAILURE_MESSAGE ]]; then
          printf '  %s\n' "$STEP_FAILURE_MESSAGE" >&2
        elif [[ -n $LAST_STDERR ]]; then
          printf '  %s\n' "$LAST_STDERR" >&2
        else
          printf '  Step exited with status %d\n' "$status" >&2
        fi
      fi
      return "$status"
    fi
  done

  printf '    %b%s %s "%s"%b\n' "$red" "✗" "$type" "$text" "$reset" >&2
  printf '  No matching step definition\n' >&2
  return 1
}

run_feature() {
  local feature_file=$1
  local line
  local section=
  local feature_seen=0
  local scenario_seen=0
  local background_started=0
  local in_description=0
  local feature_name=
  local scenario_name=
  local previous_type=
  local active_step_type
  local active_step_text
  local failed=0
  local -a background_steps=()
  local -a scenario_steps=()

  run_recorded_step() {
    local recorded=$1
    local step_keyword=${recorded%%$'\t'*}
    local step_text=${recorded#*$'\t'}
    local resolved_type=$step_keyword

    if [[ $step_keyword == "And" || $step_keyword == "But" ]]; then
      if [[ -z $previous_type ]]; then
        printf '    %b%s %s "%s"%b\n' "$red" "✗" "$step_keyword" "$step_text" "$reset" >&2
        printf '  %s cannot be the first step\n' "$step_keyword" >&2
        return 1
      fi
      resolved_type=$previous_type
    else
      previous_type=$step_keyword
    fi

    execute_step "$resolved_type" "$step_text"
  }

  run_scenario() {
    local step
    local scenario_failed=0
    printf '  %bScenario: %s%b\n' "$blue" "$scenario_name" "$reset"
    previous_type=
    set +e
    for step in "${background_steps[@]}"; do
      run_recorded_step "$step" || scenario_failed=1
    done
    for step in "${scenario_steps[@]}"; do
      run_recorded_step "$step" || scenario_failed=1
    done
    set -e
    return "$scenario_failed"
  }

  set +e

  while IFS= read -r line || [[ -n $line ]]; do
    line=$(trim "$line")
    [[ -z $line ]] && continue
    [[ $line == \#* ]] && continue

    if [[ $line =~ ^Feature:[[:space:]]*(.*)$ ]]; then
      feature_seen=1
      section=feature
      in_description=1
      feature_name=${BASH_REMATCH[1]}
      printf '%bFeature:%b %s\n' "$bld" "$reset" "$feature_name"
      continue
    fi

    if [[ $line =~ ^Background:[[:space:]]*$ ]]; then
      if ((feature_seen == 0)); then
        printf 'Background must appear after Feature\n' >&2
        failed=1
        break
      fi
      if ((scenario_seen != 0)); then
        printf 'Background must appear before any Scenario\n' >&2
        failed=1
        break
      fi
      section=background
      background_started=1
      in_description=0
      continue
    fi

    if [[ $line =~ ^Scenario:[[:space:]]*(.*)$ ]]; then
      local next_scenario_name=${BASH_REMATCH[1]}
      if ((feature_seen == 0)); then
        printf 'Scenario must appear after Feature\n' >&2
        failed=1
        break
      fi
      if ((scenario_seen != 0)); then
        run_scenario || failed=1
      fi
      scenario_seen=1
      section=scenario
      in_description=0
      scenario_name=$next_scenario_name
      scenario_steps=()
      continue
    fi

    if [[ $line =~ ^(Given|When|Then|And|But)[[:space:]]+(.+)$ ]]; then
      active_step_type=${BASH_REMATCH[1]}
      active_step_text=${BASH_REMATCH[2]}
      in_description=0

      case $section in
        background)
          background_steps+=("$active_step_type"$'\t'"$active_step_text")
          ;;
        scenario)
          scenario_steps+=("$active_step_type"$'\t'"$active_step_text")
          ;;
        *)
          printf 'Step must appear inside Background or Scenario: %s\n' "$line" >&2
          failed=1
          continue
          ;;
      esac
      continue
    fi

    if [[ $section == "feature" && $in_description == 1 ]]; then
      continue
    fi

    printf 'Unsupported feature line: %s\n' "$line" >&2
    failed=1
  done < "$feature_file"

  if ((failed == 0 && scenario_seen != 0)); then
    run_scenario || failed=1
  elif ((scenario_seen != 0)); then
    run_scenario || failed=1
  fi

  set -e
  return "$failed"
}

step_type_valid() {
  case $1 in
    Given|When|Then|Step)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

main() {
  if (($# != 2)); then
    printf 'Usage: %s STEPDEFS FEATURE\n' "${0##*/}" >&2
    return 1
  fi

  parse_stepdefs "$1"

  local i
  for i in "${!STEP_TYPES[@]}"; do
    if ! step_type_valid "${STEP_TYPES[$i]}"; then
      printf 'Unsupported step definition type: @%s\n' "${STEP_TYPES[$i]}" >&2
      return 1
    fi
  done

  if run_feature "$2"; then
    return 0
  fi
  return 1
}

main "$@"
