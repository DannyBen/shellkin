@access
Feature: rules
  Group examples by business rule

Background:
  Given the current user is 'Dana'

@elevated
Rule: Elevated roles can access protected areas
  These roles have broader access.

  Background:
    Given the current role is 'admin'

  Scenario Outline: Accessing <area>
    Then the user should have access to '<area>'

  Examples:
    | area     |
    | settings |
    | reports  |

@standard
Rule: Standard roles cannot access protected areas

  Background:
    Given the current role is 'member'

  Scenario: Accessing settings
    Then the user should not have access to 'settings'
