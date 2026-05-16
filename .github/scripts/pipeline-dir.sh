#!/usr/bin/env bash
# Shared temp dir for pipeline artifacts; scripts cached before reports-branch checkout.
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

# Copy scripts into PIPELINE_DIR so they survive `git checkout reports`
# (reports branch does not contain .github/scripts/).
pipeline_cache_scripts() {
  local src="${1:?script source directory}"
  pipeline_init
  if [ -z "${PIPELINE_SCRIPTS_DIR:-}" ]; then
    PIPELINE_SCRIPTS_DIR=$(pipeline_path scripts)
    export PIPELINE_SCRIPTS_DIR
  fi
  if [ ! -f "$PIPELINE_SCRIPTS_DIR/pipeline-dir.sh" ]; then
    mkdir -p "$PIPELINE_SCRIPTS_DIR"
    cp -a "$src/." "$PIPELINE_SCRIPTS_DIR/"
  fi
}

pipeline_scripts_dir() {
  if [ -z "${PIPELINE_SCRIPTS_DIR:-}" ] || [ ! -d "$PIPELINE_SCRIPTS_DIR" ]; then
    echo "Pipeline scripts not cached; call pipeline_cache_scripts first." >&2
    exit 1
  fi
  printf '%s\n' "$PIPELINE_SCRIPTS_DIR"
}

pipeline_bootstrap() {
  local src="${1:?script source directory}"
  pipeline_cache_scripts "$src"
}
