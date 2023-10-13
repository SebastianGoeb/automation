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

# Create a new check run
check_run=$(
  gh api "repos/{owner}/{repo}/check-runs" \
    -X POST \
    -F "name=Lint Repo Settings" \
    -F "head_sha=${PR_SHA}" \
    -F "status=in_progress" \
    -F "started_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
)
check_run_id=$(echo "$check_run" | jq .id)

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

# gh api "repos/${GITHUB_REPOSITORY}/statuses/${PR_SHA}" \
#   -X POST \
#   -f "state=error" \
#   -f "description=$num_errors errors" \
#   -f "context=continuous-integration/my-check"

# report errors
if [ "$num_errors" -ne 0 ]; then
  printf "%s\n" "${errors[@]}"

  gh api "repos/{owner}/{repo}/check-runs/$check_run_id" \
    -X PATCH \
    -F "conclusion=action_required" \
    -F "completed_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    -F "output.title=Repo is Misconfigured" \
    -F "output.summary=$num_errors errors"

  exit 1
else
  echo "all good!"

  gh api "repos/{owner}/{repo}/check-runs/$check_run_id" \
    -X PATCH \
    -F "conclusion=success" \
    -F "completed_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    -F "output.title=Repo Settings are Good" \
    -F "output.summary=all good"
fi
