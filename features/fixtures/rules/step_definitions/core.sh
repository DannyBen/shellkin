@Given the current user is '{name}'
  CURRENT_USER=$name

@Given the current role is '{role}'
  CURRENT_ROLE=$role

@Then the user should have access to '{area}'
  [[ $CURRENT_USER == Dana ]]
  [[ $CURRENT_ROLE == admin ]]
  [[ $area == settings || $area == reports ]]

@Then the user should not have access to '{area}'
  [[ $CURRENT_USER == Dana ]]
  [[ $CURRENT_ROLE == member ]]
  [[ $area == settings ]]
