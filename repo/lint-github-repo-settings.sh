#!/bin/bash

declare -a errors

function validate_jq() {
  local json="$1"
  local query="$2"
  local expected="$3"

  local actual
  actual=$(echo "$json" | jq -r "$query")

  if ! echo "$actual" | grep -q "$expected"; then
    errors+=("$query is set incorrectly:
    expected: $expected
    but was:  $actual
")
  fi
}

# fetch json for the git repo we are currently in
repo=$(gh api 'repos/{owner}/{repo}')

# validate what we care about
validate_jq "$repo" '.allow_squash_merge' 'true'
validate_jq "$repo" '.allow_merge_commit' 'false'
validate_jq "$repo" '.allow_rebase_merge' 'false'
validate_jq "$repo" '.allow_auto_merge' 'true'
validate_jq "$repo" '.delete_branch_on_merge' 'true'
validate_jq "$repo" '.allow_update_branch' 'true'
validate_jq "$repo" '.use_squash_pr_title_as_default' 'true'

echo "::notice file=app.js,line=1,col=5,endColumn=7::Missing semicolon"
echo "::warning file=app.js,line=1,col=5,endColumn=7::Missing semicolon"
echo "::error file=app.js,line=1,col=5,endColumn=7::Missing semicolon"

num_errors="${#errors[@]}"

# gh api "repos/${GITHUB_REPOSITORY}/statuses/${GITHUB_SHA}" \
#   -X POST \
#   -f "state=error" \
#   -f "description=$num_errors errors" \
#   -f "context=continuous-integration/my-check"

# Create a new check run
response=$(
  gh api "repos/{owner}/{repo}/check-runs" \
    -X POST \
    -F "name=My Custom Check" \
    -F "head_sha=${GITHUB_SHA}" \
    -F "status=in_progress" \
    -F "started_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
)

echo
echo "$response"

# Extract the check_run_id from the response
check_run_id=$(echo "$response" | jq .id)

# ... Here you'd run your checks ...
echo "sleeping"
sleep 10

# After your checks, update the check run with a conclusion
gh api "repos/{owner}/{repo}/check-runs/$check_run_id" \
  -X PATCH \
  -F "conclusion=success" \
  -F "completed_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  -F "output.title=Check Results" \
  -F "output.summary=$num_errors errors"

# report errors
if [ "$num_errors" -ne 0 ]; then
  printf "%s\n" "${errors[@]}"
  exit 1
else
  echo "all good!"
fi
