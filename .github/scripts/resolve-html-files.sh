#!/usr/bin/env bash
# Write paths of HTML files to encrypt into $PIPELINE_DIR/changed-html.txt
# Usage:
#   resolve-html-files.sh all <main_sha>
#   resolve-html-files.sh delta <before_sha> <after_sha>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=pipeline-dir.sh
source "$SCRIPT_DIR/pipeline-dir.sh"

MODE="$1"
CHANGED_HTML=$(pipeline_path changed-html.txt)
CHANGED_PATHS=$(pipeline_path changed-paths.txt)
REPORT_DIRS_FROM_CHANGES=$(pipeline_path report-dirs-from-changes.txt)

: > "$CHANGED_HTML"

list_html_under_dirs() {
  local sha="$1"
  shift
  local dir html
  for dir in "$@"; do
    while IFS= read -r html; do
      [ -z "$html" ] && continue
      printf '%s\n' "$html" >> "$CHANGED_HTML"
    done < <(git ls-tree -r --name-only "$sha" -- "$dir/" | grep '\.html$' || true)
  done
}

list_all_html() {
  local sha="$1"
  git ls-tree -r --name-only "$sha" \
    | grep '\.html$' \
    | grep -v '^password-template/' \
    | grep -v '^\.github/' \
    > "$CHANGED_HTML" || true
}

case "$MODE" in
  all)
    list_all_html "$2"
    ;;
  delta)
    BEFORE_SHA="$2"
    AFTER_SHA="$3"
    if [ "$BEFORE_SHA" = "0000000000000000000000000000000000000000" ]; then
      git diff-tree --no-commit-id --name-only -r "$AFTER_SHA" > "$CHANGED_PATHS"
    else
      git diff --name-only --diff-filter=ACMRT "$BEFORE_SHA" "$AFTER_SHA" > "$CHANGED_PATHS"
    fi

    : > "$REPORT_DIRS_FROM_CHANGES"
    while IFS= read -r path; do
      [ -z "$path" ] && continue
      case "$path" in
        password-template/*|.github/*) continue ;;
      esac
      dir=$(dirname "$path")
      [ "$dir" = "." ] && continue
      printf '%s\n' "$dir" >> "$REPORT_DIRS_FROM_CHANGES"
    done < "$CHANGED_PATHS"

    [ -s "$REPORT_DIRS_FROM_CHANGES" ] || exit 0

    mapfile -t UNIQUE_DIRS < <(sort -u "$REPORT_DIRS_FROM_CHANGES")
    list_html_under_dirs "$AFTER_SHA" "${UNIQUE_DIRS[@]}"
    ;;
  *)
    echo "Usage: resolve-html-files.sh all|delta ..." >&2
    exit 1
    ;;
esac

if [ -s "$CHANGED_HTML" ]; then
  sort -u "$CHANGED_HTML" -o "$CHANGED_HTML"
fi
