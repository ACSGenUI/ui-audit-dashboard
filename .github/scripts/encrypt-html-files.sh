#!/usr/bin/env bash
set -euo pipefail

FILE_LIST="$1"

if [ ! -s "$FILE_LIST" ]; then
  echo "File list is empty; nothing to encrypt."
  exit 1
fi

if [ ! -f .staticrypt.json ] || [ ! -f password-template/template.html ]; then
  echo "Missing StatiCrypt config or template; run prepare-reports-branch.sh first."
  exit 1
fi

while IFS= read -r FILE; do
  [ -z "$FILE" ] && continue
  if [ ! -f "$FILE" ]; then
    echo "HTML file not found: $FILE"
    exit 1
  fi

  PARENT=$(dirname "$FILE")
  PASSWORD="@${PARENT}#"
  # basename = immediate parent folder (e.g. Abbvie, lh-temp)
  TEMPLATE_TITLE=$(basename "$PARENT")
  echo "Encrypting $FILE (title: ${TEMPLATE_TITLE})"

  npx --yes staticrypt@3 "$FILE" \
    -p "$PASSWORD" \
    --short \
    -t password-template/template.html \
    --template-title "$TEMPLATE_TITLE" \
    --template-button "Show Report" \
    --template-instructions "PRoGenAI Analysis Report" \
    -d "$PARENT" \
    -c .staticrypt.json
done < "$FILE_LIST"
