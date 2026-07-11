## Parses one data table row into a caller-provided array.
feature_table_row_parse() {
  local line=$1
  local -n cells_ref=$2
  local content
  local cell
  local rest

  [[ $line == \|*\| ]] || return 1

  content=${line#\|}
  content=${content%\|}
  cells_ref=()
  rest=$content
  while [[ $rest == *\|* ]]; do
    cell=${rest%%\|*}
    cells_ref+=("$(trim "$cell")")
    rest=${rest#*\|}
  done
  cells_ref+=("$(trim "$rest")")
}

## Attaches one parsed data table row to the previous recorded step.
feature_table_row_apply() {
  local row=$1
  local section=$2
  # shellcheck disable=SC2178  # nameref to an array supplied by name
  local -n background_steps_ref=$3
  # shellcheck disable=SC2178  # nameref to an array supplied by name
  local -n scenario_steps_ref=$4
  local last_index
  local recorded

  case $section in
    background)
      ((${#background_steps_ref[@]} > 0)) || return 1
      last_index=$((${#background_steps_ref[@]} - 1))
      recorded=${background_steps_ref[last_index]}
      background_steps_ref[last_index]="$recorded"$'\x1e'"$row"
      ;;
    scenario)
      ((${#scenario_steps_ref[@]} > 0)) || return 1
      last_index=$((${#scenario_steps_ref[@]} - 1))
      recorded=${scenario_steps_ref[last_index]}
      scenario_steps_ref[last_index]="$recorded"$'\x1e'"$row"
      ;;
    *)
      return 1
      ;;
  esac
}

## Validates the rows attached to one recorded step.
feature_table_validate() {
  local recorded=$1
  local table_data
  local row
  local width=0
  local -a cells=()

  [[ $recorded == *$'\x1e'* ]] || return 0
  table_data=${recorded#*$'\x1e'}

  while IFS= read -r row; do
    feature_table_row_parse "$row" cells || return 1
    if ((width == 0)); then
      width=${#cells[@]}
      ((width > 0)) || return 1
    elif ((${#cells[@]} != width)); then
      return 1
    fi
  done <<<"${table_data//$'\x1e'/$'\n'}"
}

## Exposes an attached data table to a step definition.
feature_table_export() {
  local recorded=$1
  local table_data
  local row
  local index=0
  local -a cells=()

  TABLE_HEADER=()
  TABLE_ROWS=()
  [[ $recorded == *$'\x1e'* ]] || return 0
  feature_table_validate "$recorded" || return 1

  table_data=${recorded#*$'\x1e'}
  while IFS= read -r row; do
    feature_table_row_parse "$row" cells || return 1
    if ((index == 0)); then
      # shellcheck disable=SC2034  # consumed by the evaluated step definition
      TABLE_HEADER=("${cells[@]}")
    else
      TABLE_ROWS+=("$(
        IFS=$'\t'
        printf '%s' "${cells[*]}"
      )")
    fi
    ((index += 1))
  done <<<"${table_data//$'\x1e'/$'\n'}"
}
