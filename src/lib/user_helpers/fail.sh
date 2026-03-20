fail() {
  FAIL_MESSAGE=${1-}
  export FAIL_MESSAGE
  return 1
}
