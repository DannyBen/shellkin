## Registers a cleanup command to run after the scenario finishes.
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

## Executes one deferred cleanup command.
defer__run_command() {
  local deferred_command=$1

  eval "$deferred_command"
}

## Executes deferred cleanup commands in reverse registration order.
defer__run_all() {
  local index
  local deferred_command

  for ((index = ${#SCENARIO_DEFERRED_COMMANDS[@]} - 1; index >= 0; index--)); do
    deferred_command=${SCENARIO_DEFERRED_COMMANDS[$index]}
    if defer__run_command "$deferred_command"; then
      :
    else
      FAIL_MESSAGE="deferred action failed: $deferred_command"
      export FAIL_MESSAGE
      return 1
    fi
  done

  return 0
}
