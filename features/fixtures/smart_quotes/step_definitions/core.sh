@When I capture single quoted token '{value}'
  CAPTURED_VALUE=$value

@When I capture double quoted token "{value}"
  CAPTURED_VALUE=$value

@Then the captured value should equal '{expected}'
  [[ "$CAPTURED_VALUE" == "$expected" ]] || fail "expected '$expected', got '$CAPTURED_VALUE'"

@Then the captured value should equal "{expected}"
  [[ "$CAPTURED_VALUE" == "$expected" ]] || fail "expected '$expected', got '$CAPTURED_VALUE'"
