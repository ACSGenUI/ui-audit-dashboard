#!/usr/bin/env bash
# Prepare reports branch, encrypt listed HTML, commit and push.
set -euo pipefail

MAIN_SHA="$1"
FILE_LIST="$2"

if [ ! -s "$FILE_LIST" ]; then
  echo "No HTML files to process; skipping."
  exit 0
fi

bash "$(dirname "$0")/prepare-reports-branch.sh" "$MAIN_SHA" "$FILE_LIST"
bash "$(dirname "$0")/encrypt-html-files.sh" "$FILE_LIST"
bash "$(dirname "$0")/commit-reports-branch.sh"
