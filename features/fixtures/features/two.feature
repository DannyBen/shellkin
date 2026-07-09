Feature: two
  Another passing fixture

@smoke @slow
Scenario: two passes
  When I run 'printf two'
  Then the output should include 'two'
