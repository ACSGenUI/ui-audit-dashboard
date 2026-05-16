#!/usr/bin/env bash
set -euo pipefail

CALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=pipeline-dir.sh
source "$CALLER_DIR/pipeline-dir.sh"
pipeline_init

MAIN_SHA="$1"
FILE_LIST="$2"
PIPELINE_MODE="${PIPELINE_MODE:-delta}"

REPORT_DIRS=$(pipeline_path report-dirs.txt)
DELETED_PATHS=$(pipeline_path deleted-paths.txt)

if [ ! -s "$FILE_LIST" ] && [ ! -s "$DELETED_PATHS" ] && [ "$PIPELINE_MODE" != "all" ]; then
  echo "Nothing to sync or delete on reports branch."
  exit 1
fi

git fetch origin reports 2>/dev/null || true

if git show-ref --verify --quiet refs/remotes/origin/reports; then
  git checkout -B reports origin/reports
else
  git checkout --orphan reports
  git rm -rf . 2>/dev/null || true
fi

if [ "$PIPELINE_MODE" = "all" ]; then
  echo "Cleaning reports branch before full rebuild"
  mapfile -t TRACKED < <(git ls-files 2>/dev/null || true)
  if [ "${#TRACKED[@]}" -gt 0 ]; then
    git rm -rf "${TRACKED[@]}" 2>/dev/null || true
  fi
  git clean -fdx
fi

: > "$REPORT_DIRS"
if [ -s "$FILE_LIST" ]; then
  while IFS= read -r FILE; do
    [ -z "$FILE" ] && continue
    PARENT=$(dirname "$FILE")
    if [ "$PARENT" = "." ]; then
      echo "Refusing to copy repo root for HTML at $FILE; place HTML in a subdirectory."
      exit 1
    fi
    printf '%s\n' "$PARENT" >> "$REPORT_DIRS"
  done < "$FILE_LIST"
fi

if [ -s "$DELETED_PATHS" ] && [ "$PIPELINE_MODE" = "delta" ]; then
  bash "$CALLER_DIR/apply-reports-deletions.sh" "$MAIN_SHA" "$DELETED_PATHS" "$REPORT_DIRS"
fi

if [ -s "$REPORT_DIRS" ]; then
  sort -u "$REPORT_DIRS" -o "$REPORT_DIRS"
fi

if [ -s "$FILE_LIST" ]; then
  for required in .staticrypt.json password-template/template.html; do
    if ! git cat-file -e "$MAIN_SHA:$required" 2>/dev/null; then
      echo "Missing required file on main: $required"
      exit 1
    fi
  done

  while IFS= read -r DIR; do
    [ -z "$DIR" ] && continue
    if [ -z "$(git ls-tree -r --name-only "$MAIN_SHA" -- "$DIR/" 2>/dev/null || true)" ]; then
      continue
    fi
    echo "Syncing $DIR/ from main"
    rm -rf -- "$DIR"
    git checkout "$MAIN_SHA" -- "$DIR/"
  done < "$REPORT_DIRS"

  git show "$MAIN_SHA:.staticrypt.json" > .staticrypt.json
  mkdir -p password-template
  git show "$MAIN_SHA:password-template/template.html" > password-template/template.html
fi
