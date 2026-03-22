## Fails the current step with an optional message.
fail() {
  FAIL_MESSAGE=${1-}
  export FAIL_MESSAGE
  return 1
}
