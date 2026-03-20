Feature: star step keyword
  Reuse the previous concrete step type

Scenario: list-like steps
  Given I am in a temp directory
  When I run 'touch one'
  * I run 'touch two'
  Then the file 'one' should exist
  And the file 'two' should exist
