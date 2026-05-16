#!/usr/bin/env bash
# Resolve HTML to encrypt, run pipeline, clean up temp files on exit.
set -euo pipefail

MODE="$1"
BEFORE_SHA="${2:-}"
MAIN_SHA="$3"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=pipeline-dir.sh
source "$SCRIPT_DIR/pipeline-dir.sh"
pipeline_init

if [ "$MODE" = "all" ]; then
  bash "$SCRIPT_DIR/resolve-html-files.sh" all "$MAIN_SHA"
else
  bash "$SCRIPT_DIR/resolve-html-files.sh" delta "$BEFORE_SHA" "$MAIN_SHA"
fi

CHANGED_HTML=$(pipeline_path changed-html.txt)
if [ ! -s "$CHANGED_HTML" ]; then
  echo "No HTML files to process."
  exit 0
fi

echo "HTML files to encrypt:"
cat "$CHANGED_HTML"

bash "$SCRIPT_DIR/run-encrypt-pipeline.sh" "$MAIN_SHA" "$CHANGED_HTML"
