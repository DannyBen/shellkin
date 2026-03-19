Feature: Hello World
  Initial sample test
  Mutiline supported, this is only a comment

Background:
  Given I am in a temp directory

Scenario: Create a file
   When I run 'touch somefile'
   Then the file 'somefile' should exist
    But the file 'some other file' should exist

Scenario: Create another file
   When I run 'touch some-other-file'
   Then the file 'some-other-file' should exist
