Feature: one
  Passing fixture

@smoke
Scenario: one passes
  When I run 'printf one'
  Then the output should include 'one'
