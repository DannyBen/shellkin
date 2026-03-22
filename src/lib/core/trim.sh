## Removes leading and trailing whitespace from a string.
trim() {
  local value="${1-}"

  value=${value#"${value%%[![:space:]]*}"}
  value=${value%"${value##*[![:space:]]}"}

  printf '%s' "$value"
}
