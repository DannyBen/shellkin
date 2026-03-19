Feature: two
  Failing fixture

Scenario: two fails
  When I run 'printf two'
  Then the output should include 'missing'
