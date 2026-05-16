#!/usr/bin/env bash
# List plaintext HTML to encrypt: client root (e.g. Abbvie/*.html) and nested paths.
set -euo pipefail

find . -type f -name '*.html' \
  ! -path './password-template/*' \
  ! -path './.git/*' \
  ! -path './.github/*' \
  | sed 's|^\./||' \
  | sort -u
