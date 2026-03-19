Feature: one
  Passing fixture

Scenario: one passes
  When I run 'printf one'
  Then the output should include 'one'
