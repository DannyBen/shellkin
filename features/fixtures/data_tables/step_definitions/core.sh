@Given these users exist
  USER_NAMES=()
  USER_ROLES=()
  [[ ${TABLE_HEADER[*]} == "name role" ]] || fail "expected name and role columns"

  for row in "${TABLE_ROWS[@]}"; do
    IFS=$'\t' read -r name role <<<"$row"
    USER_NAMES+=("$name")
    USER_ROLES+=("$role")
  done

@Then user '{name}' should have role '{role}'
  for index in "${!USER_NAMES[@]}"; do
    if [[ ${USER_NAMES[$index]} == "$name" ]]; then
      [[ ${USER_ROLES[$index]} == "$role" ]]
      return
    fi
  done

  fail "user not found: $name"
