Feature: scenario outlines
  Run the same scenario with several examples

Background:
  Given the user registry is empty

Scenario Outline: Creating <name> as <role>
  When I register user '<name>' with role '<role>'
  Then user '<name>' should have role '<role>'

Examples:
  | name  | role   |
  | Alice | admin  |
  | Bob   | member |
