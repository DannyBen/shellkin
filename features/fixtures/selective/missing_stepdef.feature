Feature: missing step definition
  Unmatched steps should fail safely

Scenario: missing definition
  When I run 'printf one'
  Then I do not exist
  And I also should be skipped
