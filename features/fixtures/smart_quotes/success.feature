Feature: smart quotes fixture
  Exercise quoted token delimiters

Scenario: single quoted pattern with single quoted value
  When I capture single quoted token 'plain text'
  Then the captured value should equal 'plain text'

Scenario: single quoted pattern with double quoted value
  When I capture single quoted token "plain text"
  Then the captured value should equal "plain text"

Scenario: double quoted pattern with single quoted value
  When I capture double quoted token 'plain text'
  Then the captured value should equal 'plain text'

Scenario: double quoted pattern with double quoted value
  When I capture double quoted token "plain text"
  Then the captured value should equal "plain text"

Scenario: single quoted pattern preserves embedded single quotes
  When I capture single quoted token "Something's wrong"
  Then the captured value should equal "Something's wrong"

Scenario: double quoted pattern preserves embedded double quotes
  When I capture double quoted token 'Jim "Jimbo" Jackson'
  Then the captured value should equal 'Jim "Jimbo" Jackson'
