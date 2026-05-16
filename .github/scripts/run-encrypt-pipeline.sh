#!/usr/bin/env bash
# Prepare reports branch, encrypt listed HTML, commit and push.
# Must run from cached scripts (reports checkout removes .github/scripts/).
set -euo pipefail

MAIN_SHA="$1"
FILE_LIST="$2"

CALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=pipeline-dir.sh
source "$CALLER_DIR/pipeline-dir.sh"

if [ -z "${PIPELINE_SCRIPTS_DIR:-}" ]; then
  pipeline_cache_scripts "$CALLER_DIR"
fi
SCRIPTS="$(pipeline_scripts_dir)"

if [ ! -s "$FILE_LIST" ]; then
  echo "No HTML files to process; skipping."
  exit 0
fi

bash "$SCRIPTS/prepare-reports-branch.sh" "$MAIN_SHA" "$FILE_LIST"
bash "$SCRIPTS/encrypt-html-files.sh" "$FILE_LIST"
bash "$SCRIPTS/commit-reports-branch.sh"
