#!/usr/bin/env bash
set -euo pipefail

CALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=pipeline-dir.sh
source "$CALLER_DIR/pipeline-dir.sh"
pipeline_init

MAIN_SHA="$1"
FILE_LIST="$2"
REPORT_DIRS=$(pipeline_path report-dirs.txt)

if [ ! -s "$FILE_LIST" ]; then
  echo "File list is empty; nothing to copy."
  exit 1
fi

git fetch origin reports 2>/dev/null || true

if git show-ref --verify --quiet refs/remotes/origin/reports; then
  git checkout -B reports origin/reports
else
  git checkout --orphan reports
  git rm -rf . 2>/dev/null || true
fi

: > "$REPORT_DIRS"
while IFS= read -r FILE; do
  [ -z "$FILE" ] && continue
  PARENT=$(dirname "$FILE")
  if [ "$PARENT" = "." ]; then
    echo "Refusing to copy repo root for HTML at $FILE; place HTML in a subdirectory."
    exit 1
  fi
  printf '%s\n' "$PARENT" >> "$REPORT_DIRS"
done < "$FILE_LIST"
sort -u "$REPORT_DIRS" -o "$REPORT_DIRS"

for required in .staticrypt.json password-template/template.html; do
  if ! git cat-file -e "$MAIN_SHA:$required" 2>/dev/null; then
    echo "Missing required file on main: $required"
    exit 1
  fi
done

while IFS= read -r DIR; do
  [ -z "$DIR" ] && continue
  echo "Syncing $DIR/ from main"
  rm -rf -- "$DIR"
  git checkout "$MAIN_SHA" -- "$DIR/"
done < "$REPORT_DIRS"

git show "$MAIN_SHA:.staticrypt.json" > .staticrypt.json
mkdir -p password-template
git show "$MAIN_SHA:password-template/template.html" > password-template/template.html
