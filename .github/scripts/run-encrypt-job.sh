#!/usr/bin/env bash
# Single workflow entrypoint: resolve HTML, encrypt, push to reports.
# Scripts are cached before any `git checkout reports` (see pipeline-dir.sh).
set -euo pipefail

MODE="$1"
BEFORE_SHA="${2:-}"
MAIN_SHA="$3"

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
if [ ! -s "$CHANGED_HTML" ]; then
  echo "No HTML files to process."
  exit 0
fi

echo "HTML files to encrypt:"
cat "$CHANGED_HTML"

bash "$SCRIPTS/run-encrypt-pipeline.sh" "$MAIN_SHA" "$CHANGED_HTML"
