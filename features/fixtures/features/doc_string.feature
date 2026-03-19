Feature: doc string steps
  Testing witha step that uses doc string

Scenario: two passes
  When I run 'printf "this is a\nmultiline string"'
  Then the output should match
     """
     this is a
     multiline string
     """
