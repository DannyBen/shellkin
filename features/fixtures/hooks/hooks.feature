Feature: hooks
  Before and After hooks

@needs-server
Scenario: tagged hooks run before matching scenarios
  Then the hook log should include 'before'
  And the hook log should include 'server-start'

Scenario: after hooks run after scenarios
  Then the hook log should include 'after'
  And the hook log should include 'server-stop'
