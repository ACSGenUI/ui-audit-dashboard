#!/usr/bin/env bash
# Single workflow entrypoint: resolve HTML, encrypt, push to reports.
set -euo pipefail

MODE="$1"
BEFORE_SHA="${2:-}"
MAIN_SHA="$3"

export PIPELINE_MODE="$MODE"

REPO_SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=pipeline-dir.sh
source "$REPO_SCRIPTS/pipeline-dir.sh"
pipeline_bootstrap "$REPO_SCRIPTS"
SCRIPTS="$(pipeline_scripts_dir)"

if [ "$MODE" = "all" ]; then
  bash "$SCRIPTS/resolve-html-files.sh" all "$MAIN_SHA"
else
  bash "$SCRIPTS/resolve-html-files.sh" delta "$BEFORE_SHA" "$MAIN_SHA"
fi

CHANGED_HTML=$(pipeline_path changed-html.txt)
DELETED_PATHS=$(pipeline_path deleted-paths.txt)

if [ "$MODE" = "all" ]; then
  if [ ! -s "$CHANGED_HTML" ]; then
    echo "No HTML files on main to encrypt."
    exit 0
  fi
elif [ ! -s "$CHANGED_HTML" ] && [ ! -s "$DELETED_PATHS" ]; then
  echo "No changes to apply on reports branch."
  exit 0
fi

[ -s "$CHANGED_HTML" ] && { echo "HTML files to encrypt:"; cat "$CHANGED_HTML"; }
[ -s "$DELETED_PATHS" ] && { echo "Paths deleted on main:"; cat "$DELETED_PATHS"; }

bash "$SCRIPTS/run-encrypt-pipeline.sh" "$MAIN_SHA" "$CHANGED_HTML"
