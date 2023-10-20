#!/usr/bin/env bash

if [ "${BASH_VERSINFO:-0}" -le 3 ]; then
  echo "bash >= 4 required" # for readarray command
  exit 1
fi

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$DIR/src/lint-own-repos.sh"
