#!/bin/bash

declare -a errors

function validate_jq() {
  local json="$1"
  local query="$2"
  local expected="$3"

  local actual
  actual=$(echo "$json" | jq -r "$query")

  if ! echo "$actual" | grep -q "$expected"; then
    errors+=("expected $query to be $expected but was $actual")
  fi
}

# Create a new check run
echo "::group::creating check run"
check_run=$(
  gh api "repos/{owner}/{repo}/check-runs" \
    -X POST \
    -F "name=Lint Repo Settings" \
    -F "head_sha=${PR_SHA}" \
    -F "status=in_progress" \
    -F "started_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
)
check_run_id=$(echo "$check_run" | jq .id)
echo "::endgroup::"

# fetch json for the git repo we are currently in
repo=$(GITHUB_TOKEN="$LINT_REPO_SETTINGS_PAT" gh api 'repos/{owner}/{repo}')

# validate what we care about
validate_jq "$repo" '.allow_squash_merge' 'true'
validate_jq "$repo" '.allow_merge_commit' 'false'
validate_jq "$repo" '.allow_rebase_merge' 'false'
validate_jq "$repo" '.delete_branch_on_merge' 'true'
validate_jq "$repo" '.allow_update_branch' 'true'
validate_jq "$repo" '.use_squash_pr_title_as_default' 'true'

if echo "$repo" | jq '.private' | grep 'true' >/dev/null; then
  echo "::warning::Repo is private, skipping some validations"
else
  validate_jq "$repo" '.allow_auto_merge' 'true'
fi

num_errors="${#errors[@]}"

# report errors
current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
if [ "$num_errors" -ne 0 ]; then
  for err in "${errors[@]}"; do
    echo "::error::$err"
  done

  echo "::group::updating check run"
  json_payload=$(
    jq -n \
      --arg completed_at "$current_date" \
      --arg title "$num_errors errors" \
      --arg summary "Repo is misconfigured" \
      '{
      "conclusion": "failure",
      "completed_at": $completed_at,
      "output": {
        "title": $title,
        "summary": $summary
      }
    }'
  )
  gh api "repos/${GITHUB_REPOSITORY}/check-runs/$check_run_id" \
    -X PATCH \
    --input <(echo "$json_payload")
  echo "::endgroup::"

  exit 1
else
  echo "all good!"

  echo "::group::updating check run"
  json_payload=$(
    jq -n \
      --arg completed_at "$current_date" \
      '{
      "conclusion": "success",
      "completed_at": $completed_at,
      "output": {
        "title": "All Good",
        "summary": "Repo is configured correctly"
      }
    }'
  )
  gh api "repos/${GITHUB_REPOSITORY}/check-runs/$check_run_id" \
    -X PATCH \
    --input <(echo "$json_payload")
  echo "::endgroup::"
fi
