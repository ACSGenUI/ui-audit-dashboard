#!/usr/bin/env bash
# Remove files and folders deleted on main from the reports branch working tree.
set -euo pipefail

MAIN_SHA="$1"
DELETED_PATHS="$2"
REPORT_DIRS="$3"

dir_exists_on_main() {
  local sha="$1" dir="$2"
  [ -n "$(git ls-tree -r --name-only "$sha" -- "$dir/" 2>/dev/null || true)" ]
}

if [ ! -s "$DELETED_PATHS" ]; then
  exit 0
fi

: > "${REPORT_DIRS}.tmp"
[ -f "$REPORT_DIRS" ] && [ -s "$REPORT_DIRS" ] && cat "$REPORT_DIRS" >> "${REPORT_DIRS}.tmp" || true

while IFS= read -r path; do
  [ -z "$path" ] && continue
  case "$path" in
    password-template/*|.github/*) continue ;;
  esac

  dir=$(dirname "$path")
  [ "$dir" = "." ] && continue
  printf '%s\n' "$dir" >> "${REPORT_DIRS}.tmp"

  if dir_exists_on_main "$MAIN_SHA" "$dir"; then
    if [ -e "$path" ] || git ls-files --error-unmatch "$path" &>/dev/null; then
      echo "Removing deleted file from reports: $path"
      git rm -f -- "$path" 2>/dev/null || rm -f -- "$path"
    fi
  else
    if [ -d "$dir" ] || git ls-files -- "$dir" &>/dev/null; then
      echo "Removing deleted folder from reports: $dir/"
      git rm -rf -- "$dir" 2>/dev/null || rm -rf -- "$dir"
    fi
  fi
done < "$DELETED_PATHS"

sort -u "${REPORT_DIRS}.tmp" -o "$REPORT_DIRS"
rm -f "${REPORT_DIRS}.tmp"
