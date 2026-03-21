defer() {
  local deferred_command=

  (($# > 0)) || return 1

  if (($# == 1)); then
    deferred_command=$1
  else
    printf -v deferred_command '%q ' "$@"
    deferred_command=${deferred_command% }
  fi

  SCENARIO_DEFERRED_COMMANDS+=("$deferred_command")
}

defer__run_command() {
  local deferred_command=$1

  eval "$deferred_command"
}

defer__run_all() {
  local index
  local deferred_command
  local status=0

  for ((index=${#SCENARIO_DEFERRED_COMMANDS[@]} - 1; index >= 0; index--)); do
    deferred_command=${SCENARIO_DEFERRED_COMMANDS[$index]}
    defer__run_command "$deferred_command" || status=1
  done

  return "$status"
}
