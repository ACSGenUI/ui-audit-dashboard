#!/usr/bin/env bash
set -euo pipefail

COMMIT_MSG="$1"

git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"

while IFS= read -r DIR; do
  [ -z "$DIR" ] && continue
  git add "$DIR"
done < report-dirs.txt

git diff --cached --quiet && exit 0

git commit -m "${COMMIT_MSG} (${GITHUB_SHA::7})"
git push -u origin reports
