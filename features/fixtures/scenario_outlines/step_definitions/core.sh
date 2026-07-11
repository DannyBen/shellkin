@Given the user registry is empty
  USER_NAMES=()
  USER_ROLES=()

@When I register user '{name}' with role '{role}'
  USER_NAMES+=("$name")
  USER_ROLES+=("$role")

@Then user '{name}' should have role '{role}'
  for index in "${!USER_NAMES[@]}"; do
    if [[ ${USER_NAMES[$index]} == "$name" ]]; then
      [[ ${USER_ROLES[$index]} == "$role" ]]
      return
    fi
  done

  fail "user not found: $name"
