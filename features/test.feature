Feature: test
  Run feature tests

Scenario: Running all feature tests
  When I run 'shellkin test features/fixtures/features'
  Then the output should include 'Feature: one'
  And the output should include '2 scenarios, 0 failing'
   And the exit code should mean success

Scenario: Running a failing test
  When I run 'shellkin test features/fixtures/failing-features'
  Then the output should include 'Feature: two'
   And the output should include '2 scenarios, 1 passing, 1 failing'
   And the exit code should mean failure

Scenario: Running a single feature file
  When I run 'shellkin test features/fixtures/features/one.feature'
  Then the output should include 'Feature: one'
   And the output should include '1 scenario, 0 failing'
   And the exit code should mean success
