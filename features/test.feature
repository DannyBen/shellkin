Feature: test
  Run feature tests

Scenario: Running all feature tests
  When I run 'shellkin test features/fixtures/features'
  Then the output should include 'Feature: one'
  And the output should include '3 scenarios, 0 failing'
   And the exit code should mean success

Scenario: Running a failing test
  When I run 'shellkin test features/fixtures/selective/failing.feature'
  Then the output should include 'Feature: two'
   And the output should include '1 scenario, 0 passing, 1 failing'
   And the exit code should mean failure

Scenario: Running a single feature file
  When I run 'shellkin test features/fixtures/features/one.feature'
  Then the output should include 'Feature: one'
   And the output should include '1 scenario, 0 failing'
   And the exit code should mean success

Scenario: Continuing to the next scenario after a failure by default
  When I run 'shellkin test features/fixtures/selective/continue_after_failure.feature'
  Then the output should include 'Scenario: first fails'
  And the output should include 'Then the output should include'
  And the output should include '(skipped)'
  And the output should include 'Scenario: second still runs'
  And the output should include '2 scenarios, 1 passing, 1 failing'
  And the exit code should mean failure

Scenario: Skipping scenario steps after a failing background
  When I run 'shellkin test features/fixtures/selective/background_failure.feature'
  Then the output should include 'Given setup fails'
  And the output should include 'Then I announce'
  And the output should include '(skipped)'
  And the output should include '1 scenario, 0 passing, 1 failing'
  And the exit code should mean failure

Scenario: Failing on a missing step definition
  When I run 'shellkin test features/fixtures/selective/missing_stepdef.feature'
  Then the output should include 'Then I do not exist'
  And the output should include '  - And I also should be skipped (skipped)'
  And the output should include '1 scenario, 0 passing, 1 failing'
  And the exit code should mean failure

Scenario: Printing doc string context for a failing step
  When I run 'shellkin test features/fixtures/selective/failing_doc_string.feature'
  Then the output should include 'Feature: failing doc string'
  And the output should include 'goodbye'
  And the output should include '1 scenario, 0 passing, 1 failing'
  And the exit code should mean failure
