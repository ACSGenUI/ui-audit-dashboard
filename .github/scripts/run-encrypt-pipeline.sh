#!/usr/bin/env bash
# Prepare reports branch, encrypt listed HTML, commit and push.
set -euo pipefail

MAIN_SHA="$1"
FILE_LIST="${2:-}"

CALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=pipeline-dir.sh
source "$CALLER_DIR/pipeline-dir.sh"

if [ -z "${PIPELINE_SCRIPTS_DIR:-}" ]; then
  pipeline_cache_scripts "$CALLER_DIR"
fi
SCRIPTS="$(pipeline_scripts_dir)"

DELETED_PATHS=$(pipeline_path deleted-paths.txt)
PIPELINE_MODE="${PIPELINE_MODE:-delta}"

if [ ! -s "$FILE_LIST" ] && [ ! -s "$DELETED_PATHS" ] && [ "$PIPELINE_MODE" != "all" ]; then
  echo "No HTML files or deletions to process; skipping."
  exit 0
fi

bash "$SCRIPTS/prepare-reports-branch.sh" "$MAIN_SHA" "$FILE_LIST"

if [ -s "$FILE_LIST" ]; then
  bash "$SCRIPTS/encrypt-html-files.sh" "$FILE_LIST"
fi

bash "$SCRIPTS/commit-reports-branch.sh"
