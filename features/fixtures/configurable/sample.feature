Feature: configurable fixture
  Fixture for configurable CLI flags

Scenario: sample passes
  When I print configured output
  Then the output should include 'configured'
