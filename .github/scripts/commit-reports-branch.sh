#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=pipeline-dir.sh
source "$SCRIPT_DIR/pipeline-dir.sh"

REPORT_DIRS=$(pipeline_path report-dirs.txt)

if [ ! -s "$REPORT_DIRS" ]; then
  echo "No report directories to commit; skipping."
  exit 0
fi

COMMIT_MSG="${COMMIT_MSG:-chore: update reports from main}"

git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"

while IFS= read -r DIR; do
  [ -z "$DIR" ] && continue
  git add -- "$DIR"
done < "$REPORT_DIRS"

git diff --cached --quiet && exit 0

git commit -m "${COMMIT_MSG} (${GITHUB_SHA::7})"
git push -u origin reports
