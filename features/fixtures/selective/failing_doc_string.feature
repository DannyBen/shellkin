Feature: failing doc string
  Print doc string context on failure

Scenario: mismatch
  When I run 'printf hello'
  Then the output should match
    """
    goodbye
    """
