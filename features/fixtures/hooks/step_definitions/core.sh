@BeforeAll
  printf 'before-all\n' >>"$HOOK_LOG"

@Before
  printf 'before\n' >>"$HOOK_LOG"

@After
  printf 'after\n' >>"$HOOK_LOG"

@Before @needs-server
  printf 'server-start\n' >>"$HOOK_LOG"

@After @needs-server
  printf 'server-stop\n' >>"$HOOK_LOG"

@AfterAll
  printf 'after-all\n' >>"$HOOK_LOG"
  printf 'HOOK_COUNTS before-all=%s before=%s after=%s after-all=%s server-start=%s server-stop=%s\n' \
    "$(grep -c '^before-all$' "$HOOK_LOG")" \
    "$(grep -c '^before$' "$HOOK_LOG")" \
    "$(grep -c '^after$' "$HOOK_LOG")" \
    "$(grep -c '^after-all$' "$HOOK_LOG")" \
    "$(grep -c '^server-start$' "$HOOK_LOG")" \
    "$(grep -c '^server-stop$' "$HOOK_LOG")"

@Then the hook log should include '{text}'
  [[ "$(cat "$HOOK_LOG")" == *"$text"* ]]
