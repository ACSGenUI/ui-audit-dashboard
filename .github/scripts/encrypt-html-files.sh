#!/usr/bin/env bash
set -euo pipefail

FILE_LIST="$1"

: > encrypted-output.txt

while IFS= read -r FILE; do
  [ -z "$FILE" ] && continue

  PARENT=$(dirname "$FILE")
  PASSWORD="@${PARENT}#"

  echo "Encrypting $FILE (password ${PASSWORD})"
  TMPFILE=$(mktemp /tmp/staticrypt-XXXXXX.html)
  cp "$FILE" "$TMPFILE"

  npx staticrypt "$TMPFILE" \
    -p "$PASSWORD" \
    --short \
    -t password-template/template.html \
    -d "$PARENT" \
    -c .staticrypt.json

  mv "$PARENT/$(basename "$TMPFILE")" "$FILE"
  rm -f "$TMPFILE"
  echo "$FILE" >> encrypted-output.txt
done < "$FILE_LIST"
