#!/usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

login="$(gh api user | jq -r '.login')"

gh api user/repos |
  jq -r --arg login "$login" '.[] | select(.owner.login == $login ) | .full_name' |
  parallel "$DIR/lint-repo.sh {} ; echo"
