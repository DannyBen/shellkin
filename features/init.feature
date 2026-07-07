Feature: --init
  Initialize a runnable features directory

Scenario: Initializing a runnable features directory
  Given I am in a temp directory
  When I run 'shellkin --init'
  Then the output should include 'initialized shellkin features directory: features'
  And the exit code should mean success
  When I run 'shellkin'
  Then the output should include 'Feature: shellkin example'
  And the output should include '1 scenario, 0 failing'
  And the exit code should mean success
