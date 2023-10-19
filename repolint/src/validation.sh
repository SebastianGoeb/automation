#!/bin/bash

function validate_property() {
  local json="$1"
  local query="$2"
  local expected="$3"

  local actual
  actual=$(echo "$json" | jq -r "$query")

  if ! echo "$actual" | grep -q "$expected"; then
    echo "expected $query to be $expected but was $actual"
  else
    echo ""
  fi
}

function validate_json() {
  local expected="$1"
  local actual="$2"

  local keys
  keys="$(jq -r 'keys[]' <<<"$expected")"

  declare -a errors
  for key in $keys; do
    local expected_property
    expected_property="$(jq -r ".$key" <<<"$expected")"
    local actual_property
    actual_property="$(jq -r ".$key" <<<"$actual")"

    if [[ "$expected_property" != "$actual_property" ]]; then
      errors+=("expected $key to be $expected_property but was $actual_property")
    fi
  done

  num_errors="${#errors[@]}"
  if [ "$num_errors" -ne 0 ]; then
    for err in "${errors[@]}"; do
      echo "$err"
    done
    return 1
  fi
}
