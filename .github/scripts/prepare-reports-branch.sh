#!/usr/bin/env bash
set -euo pipefail

MAIN_SHA="$1"
FILE_LIST="$2"

git fetch origin reports 2>/dev/null || true

if git show-ref --verify --quiet refs/remotes/origin/reports; then
  git checkout -B reports origin/reports
else
  git checkout --orphan reports
  git rm -rf . 2>/dev/null || true
fi

# Collect unique parent directories for each HTML file
: > report-dirs.txt
while IFS= read -r FILE; do
  [ -z "$FILE" ] && continue
  dirname "$FILE" >> report-dirs.txt
done < "$FILE_LIST"
sort -u report-dirs.txt -o report-dirs.txt

copy_dir_from_main() {
  local dir="$1"
  while IFS= read -r path; do
    [ -z "$path" ] && continue
    mkdir -p "$(dirname "$path")"
    git show "$MAIN_SHA:$path" > "$path"
  done < <(git ls-tree -r --name-only "$MAIN_SHA" -- "$dir/")
}

while IFS= read -r DIR; do
  [ -z "$DIR" ] && continue
  echo "Copying directory from main: $DIR/"
  copy_dir_from_main "$DIR"
done < report-dirs.txt

# Needed only for the encryption step in CI (not committed to reports)
git show "$MAIN_SHA:.staticrypt.json" > .staticrypt.json
mkdir -p password-template
git show "$MAIN_SHA:password-template/template.html" > password-template/template.html
