#!/usr/bin/env bash
# Write HTML to encrypt and deleted paths for reports branch sync.
# Usage:
#   resolve-html-files.sh all <main_sha>
#   resolve-html-files.sh delta <before_sha> <after_sha>
set -euo pipefail

CALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=pipeline-dir.sh
source "$CALLER_DIR/pipeline-dir.sh"
pipeline_init

CHANGED_HTML=$(pipeline_path changed-html.txt)
CHANGED_PATHS=$(pipeline_path changed-paths.txt)
DELETED_PATHS=$(pipeline_path deleted-paths.txt)
REPORT_DIRS_FROM_CHANGES=$(pipeline_path report-dirs-from-changes.txt)

: > "$CHANGED_HTML"
: > "$DELETED_PATHS"

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

filter_excluded() {
  grep -v '^password-template/' | grep -v '^\.github/' || true
}

case "${1:?mode}" in
  all)
    list_all_html "${2:?main sha}"
    ;;
  delta)
    BEFORE_SHA="${2:?before sha}"
    AFTER_SHA="${3:?after sha}"
    if [ "$BEFORE_SHA" = "0000000000000000000000000000000000000000" ]; then
      git diff-tree --no-commit-id --name-only -r "$AFTER_SHA" | filter_excluded > "$CHANGED_PATHS" || true
      : > "$DELETED_PATHS"
    else
      git diff --name-only --diff-filter=ACMRT "$BEFORE_SHA" "$AFTER_SHA" | filter_excluded > "$CHANGED_PATHS" || true
      git diff --name-only --diff-filter=D "$BEFORE_SHA" "$AFTER_SHA" | filter_excluded > "$DELETED_PATHS" || true
    fi

    : > "$REPORT_DIRS_FROM_CHANGES"
    while IFS= read -r path; do
      [ -z "$path" ] && continue
      dir=$(dirname "$path")
      [ "$dir" = "." ] && continue
      printf '%s\n' "$dir" >> "$REPORT_DIRS_FROM_CHANGES"
    done < "$CHANGED_PATHS"

    while IFS= read -r path; do
      [ -z "$path" ] && continue
      dir=$(dirname "$path")
      [ "$dir" = "." ] && continue
      printf '%s\n' "$dir" >> "$REPORT_DIRS_FROM_CHANGES"
    done < "$DELETED_PATHS"

    if [ -s "$REPORT_DIRS_FROM_CHANGES" ]; then
      sort -u "$REPORT_DIRS_FROM_CHANGES" -o "$REPORT_DIRS_FROM_CHANGES"
      mapfile -t UNIQUE_DIRS < <(cat "$REPORT_DIRS_FROM_CHANGES")
      list_html_under_dirs "$AFTER_SHA" "${UNIQUE_DIRS[@]}"
    fi
    ;;
  *)
    echo "Usage: resolve-html-files.sh all|delta ..." >&2
    exit 1
    ;;
esac

if [ -s "$CHANGED_HTML" ]; then
  sort -u "$CHANGED_HTML" -o "$CHANGED_HTML"
fi

if [ -s "$DELETED_PATHS" ]; then
  sort -u "$DELETED_PATHS" -o "$DELETED_PATHS"
fi
