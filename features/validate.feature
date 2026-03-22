Feature: validate
  Validate feature and step definitions file

Scenario: Validating a runtime-failing feature without executing it
  When I run 'shellkin --validate features/fixtures/selective/failing.feature'
  Then the output should include 'file: failing.feature'
  And the output should include '✓ feature'
  And the exit code should mean success

Scenario: Failing validation on an unmatched step
  When I run 'shellkin --validate features/fixtures/selective/missing_stepdef.feature'
  Then the output should include 'line 6: no matching step definition'
  And the exit code should mean failure
