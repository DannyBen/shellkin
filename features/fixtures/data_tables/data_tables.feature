Feature: data tables
  Pass structured examples to step definitions

Scenario: Creating several users
  Given these users exist
    | name  | role   |
    | Alice | admin  |
    | Bob   | member |
  Then user 'Alice' should have role 'admin'
  And user 'Bob' should have role 'member'
