#!/usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

### Imports ###

# shellcheck source=/dev/null
. "$DIR/validation.sh"

repo="$1"

### Validation ###

echo "$repo"

repo_json="$(gh api "repos/$repo")"

if echo "$repo_json" | jq '.private' | grep 'true' >/dev/null; then
  expected_json="$(jq '.private' "$DIR/../expected_settings.json")"
else
  expected_json="$(jq '.public' "$DIR/../expected_settings.json")"
fi

errors="$(validate_json "$expected_json" "$repo_json")"
readarray -t errors_arr <<<"$errors"

# report errors, summary
if [ -n "$errors" ]; then
  echo "$errors"

  num_errors="${#errors_arr[@]}"
  echo "$num_errors errors"
  exit 1
else
  echo "all good!"
fi
