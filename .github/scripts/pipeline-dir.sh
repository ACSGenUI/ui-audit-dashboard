#!/usr/bin/env bash
# Shared temp dir for pipeline artifacts; removed on exit.
set -euo pipefail

pipeline_init() {
  if [ -z "${PIPELINE_DIR:-}" ]; then
    PIPELINE_DIR=$(mktemp -d)
    export PIPELINE_DIR
    trap 'rm -rf "$PIPELINE_DIR"' EXIT
  fi
}

pipeline_path() {
  pipeline_init
  printf '%s/%s' "$PIPELINE_DIR" "$1"
}
