Feature: --help
  Show help message

Scenario: Run --help
  When I run 'shellkin --help'
  Then the output should include 'shellkin [COMMAND]'
   And the output should include 'Run feature tests'
   And the output should include 'Validate feature files and step definition files'
