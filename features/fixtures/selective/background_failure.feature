Feature: background failure
  Fail background safely

Background:
  Given setup fails

Scenario: scenario steps are skipped
  Then I announce 'this should be skipped'
