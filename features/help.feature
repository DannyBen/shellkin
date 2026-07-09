Feature: --help
  Show help message

Scenario: Run --help
  When I run 'shellkin --help'
  Then the output should include 'shellkin [TARGET] [OPTIONS]'
   And the output should include '--fail-fast, -f'
   And the output should include '--default-target DIR'
   And the output should include '--tag, -t'
   And the output should include '--exclude-tag, -x'
