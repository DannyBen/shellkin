Feature: load order fixture
  Fixture for repeated --load support files

Scenario: support files load in order
  When I print loaded support values
  Then the output should include 'hello world'
