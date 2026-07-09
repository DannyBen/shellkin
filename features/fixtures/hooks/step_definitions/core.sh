@Before
  printf 'before\n' >>"$HOOK_LOG"

@After
  printf 'after\n' >>"$HOOK_LOG"

@Before @needs-server
  printf 'server-start\n' >>"$HOOK_LOG"

@After @needs-server
  printf 'server-stop\n' >>"$HOOK_LOG"

@Then the hook log should include '{text}'
  [[ "$(cat "$HOOK_LOG")" == *"$text"* ]]
