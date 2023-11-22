#!/usr/bin/env bash

# extract own username based on login/PAT
username="$(gh api user | jq -r '.login')"

# get all repos under my control
# keep only those actually owned by me
# update all their settings in parallel
gh api user/repos |
  jq -r --arg username "$username" '.[] | select(.owner.login == $username ) | .full_name' |
  parallel --will-cite -j0 gh api --method PATCH repos/{} --input settings.json | jq -r '.full_name'
