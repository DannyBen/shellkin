Feature: two
  Single-file failing acceptance case

Scenario: two fails
  When I run 'printf two'
  Then the output should include 'missing'
