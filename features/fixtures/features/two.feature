Feature: two
  Another passing fixture

Scenario: two passes
  When I run 'printf two'
  Then the output should include 'two'
