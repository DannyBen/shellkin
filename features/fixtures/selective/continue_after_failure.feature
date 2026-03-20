Feature: continue after failure
  Continue to later scenarios by default

Scenario: first fails
  When I fail deliberately
  Then the output should include 'this should be skipped'

Scenario: second still runs
  When I run 'printf second'
  Then the output should include 'second'
