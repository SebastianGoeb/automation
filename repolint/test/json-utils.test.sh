#!/bin/bash

# shellcheck source=/dev/null
. src/validation.sh

### validate_property ###
function test_validate_property_allows_valid() {
  local actual
  actual=$(validate_property '{"a": "b"}' '.a' 'b')
  assertEquals "" "$actual"
}

function test_validate_property_rejects_invalid() {
  local actual
  actual=$(validate_property '{"a": "b"}' '.a' 'c')
  assertNotEquals "" "$actual"
}

function test_validate_property_rejects_missing() {
  local actual
  actual=$(validate_property '{"a": "b"}' '.x' 'y')
  assertNotEquals "" "$actual"
}

### validate_json ###
function test_validate_json_allows_valid() {
  local actual
  actual=$(validate_json '{"a": "b"}' '{"a": "b"}')
  assertEquals "" "$actual"
}

function test_validate_json_rejects_invalid() {
  local actual
  actual=$(validate_json '{"a": "b"}' '{"a": "other"}')
  assertEquals "expected a to be b but was other" "$actual"
}

function test_validate_json_rejects_missing() {
  local actual
  actual=$(validate_json '{"a": "b"}' '{"other": "b"}')
  assertEquals "expected a to be b but was null" "$actual"
}

function test_validate_json_rejects_multiple() {
  local actual
  actual=$(validate_json '{"a": "b", "c": "d"}' '{"a": "other", "other": "d"}')
  assertEquals "expected a to be b but was other
expected c to be d but was null" "$actual"
}

# shellcheck source=/dev/null
. shunit2
