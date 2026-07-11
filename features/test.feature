Feature: test
  Run feature tests

Scenario: Running all feature tests
  When I run 'shellkin features/fixtures/features'
  Then the output should include 'Feature: one'
   And the output should include '3 scenarios, 0 failing'
   And the exit code should mean success

Scenario: Filtering scenarios by tag
  When I run 'shellkin -t @smoke -x @slow features/fixtures/features'
  Then the output should include 'Feature: one'
  And the output should include 'Scenario 2: one passes'
  And the output should include '1 scenario, 0 failing'
  And the exit code should mean success

Scenario: Running hooks from step definition files
  When I run 'shellkin features/fixtures/hooks'
  Then the output should include 'Feature: hooks'
  And the output should include 'HOOK_COUNTS before-all=1 before=2 after=2 after-all=1 server-start=1 server-stop=1'
  And the output should include '2 scenarios, 0 failing'
  And the exit code should mean success

Scenario: Running a feature that uses a data table
  When I run 'shellkin features/fixtures/data_tables'
  Then the output should include 'Feature: data tables'
  And the output should include 'Scenario 1: Creating several users'
  And the output should include '1 scenario, 0 failing'
  And the exit code should mean success

Scenario: Running a scenario outline
  When I run 'shellkin features/fixtures/scenario_outlines'
  Then the output should include 'Feature: scenario outlines'
  And the output should include 'Scenario 1: Creating Alice as admin'
  And the output should include 'Scenario 2: Creating Bob as member'
  And the output should include '2 scenarios, 0 failing'
  And the exit code should mean success

Scenario: Selecting one expanded scenario outline row
  When I run 'shellkin features/fixtures/scenario_outlines:2'
  Then the output should include 'Scenario 2: Creating Bob as member'
  And the output should not include 'Creating Alice as admin'
  And the output should include '1 scenario, 0 failing'
  And the exit code should mean success

Scenario: Running a failing test
  When I run 'shellkin features/fixtures/selective/failing.feature'
  Then the output should include 'Feature: two'
   And the output should include '1 scenario, 0 passing, 1 failing'
   And the exit code should mean failure

Scenario: Running a single feature file
  When I run 'shellkin features/fixtures/features/one.feature'
  Then the output should include 'Feature: one'
   And the output should include '1 scenario, 0 failing'
   And the exit code should mean success

Scenario: Using --default-target when TARGET is omitted
  When I run 'shellkin --default-target features/fixtures/features'
  Then the output should include 'Feature: one'
  And the output should include '3 scenarios, 0 failing'
  And the exit code should mean success

Scenario: Letting TARGET override --default-target
  When I run 'shellkin --default-target features/fixtures/selective features/fixtures/features/one.feature'
  Then the output should include 'Feature: one'
  And the output should include '1 scenario, 0 failing'
  And the exit code should mean success

Scenario: Using --default-target together with --stepdefs
  When I run 'shellkin --default-target features/fixtures/configurable/sample.feature --stepdefs steps'
  Then the output should include 'Feature: configurable fixture'
  And the output should include '1 scenario, 0 failing'
  And the exit code should mean success

Scenario: Loading multiple support files in order
  When I run 'shellkin --stepdefs steps --load first_support.sh --load second_support.sh features/fixtures/configurable/load_order.feature'
  Then the output should include 'hello world'
  And the output should include '1 scenario, 0 failing'
  And the exit code should mean success

Scenario: Running a feature that uses the star step keyword
  When I run 'shellkin features/fixtures/selective/star_step.feature'
  Then the output should include 'Feature: star step keyword'
  And the output should include 'When I run'
  And the output should include '* I run'
  And the output should include '1 scenario, 0 failing'
  And the exit code should mean success

Scenario: Continuing to the next scenario after a failure by default
  When I run 'shellkin features/fixtures/selective/continue_after_failure.feature'
  Then the output should include 'Scenario 1: first fails'
  And the output should include 'Then the output should include'
  And the output should include '(skipped)'
  And the output should include 'Scenario 2: second still runs'
  And the output should include '2 scenarios, 1 passing, 1 failing'
  And the exit code should mean failure

Scenario: Skipping scenario steps after a failing background
  When I run 'shellkin features/fixtures/selective/background_failure.feature'
  Then the output should include 'Given setup fails'
  And the output should include 'Then I announce'
  And the output should include '(skipped)'
  And the output should include '1 scenario, 0 passing, 1 failing'
  And the exit code should mean failure

Scenario: Failing on a missing step definition
  When I run 'shellkin features/fixtures/selective/missing_stepdef.feature'
  Then the output should include 'Then I do not exist'
  And the output should include '  - And I also should be skipped (skipped)'
  And the output should include '1 scenario, 0 passing, 1 failing'
  And the exit code should mean failure

Scenario: Printing doc string context for a failing step
  When I run 'shellkin features/fixtures/selective/failing_doc_string.feature'
  Then the output should include 'Feature: failing doc string'
  And the output should include 'goodbye'
  And the output should include '1 scenario, 0 passing, 1 failing'
  And the exit code should mean failure

Scenario: Matching quoted tokens with interchangeable quote delimiters
  When I run 'shellkin features/fixtures/smart_quotes/success.feature'
  Then the output should include '6 scenarios, 0 failing'
  And the exit code should mean success

Scenario: Rejecting unquoted values for quoted token patterns
  When I run 'shellkin features/fixtures/smart_quotes/unquoted.feature'
  Then the output should include 'No matching step definition'
  And the exit code should mean failure
