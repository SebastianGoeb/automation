#!/usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

### Imports ###

# shellcheck source=/dev/null
. "$DIR/validation.sh"

repo="$1"

### Validation ###

echo "$repo"

# expects $GITHUB_TOKEN
repo_json="$(gh api "repos/$repo")"

if echo "$repo_json" | jq '.private' | grep 'true' >/dev/null; then
  expected_json="$(cat "$DIR/../private_repo_expected.json")"
else
  expected_json="$(cat "$DIR/../public_repo_expected.json")"
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

### GitHub ###

# Create a new check run
# echo "::group::creating check run"
# check_run=$(
#   gh api "repos/{owner}/{repo}/check-runs" \
#     -X POST \
#     -F "name=Lint Repo Settings" \
#     -F "head_sha=${PR_SHA}" \
#     -F "status=in_progress" \
#     -F "started_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
# )
# check_run_id=$(echo "$check_run" | jq .id)
# echo "::endgroup::"

# if [ -n "$errors" ]; then
#   current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
#   echo "::group::updating check run"
#   json_payload=$(
#     jq -n \
#       --arg completed_at "$current_date" \
#       --arg title "$num_errors errors" \
#       --arg summary "Repo is misconfigured" \
#       '{
#       "conclusion": "failure",
#       "completed_at": $completed_at,
#       "output": {
#         "title": $title,
#         "summary": $summary
#       }
#     }'
#   )
#   gh api "repos/${GITHUB_REPOSITORY}/check-runs/$check_run_id" \
#     -X PATCH \
#     --input <(echo "$json_payload")
#   echo "::endgroup::"

#   exit 1
# else
#   echo "::group::updating check run"
#   json_payload=$(
#     jq -n \
#       --arg completed_at "$current_date" \
#       '{
#       "conclusion": "success",
#       "completed_at": $completed_at,
#       "output": {
#         "title": "All Good",
#         "summary": "Repo is configured correctly"
#       }
#     }'
#   )
#   gh api "repos/${GITHUB_REPOSITORY}/check-runs/$check_run_id" \
#     -X PATCH \
#     --input <(echo "$json_payload")
#   echo "::endgroup::"
# fi
