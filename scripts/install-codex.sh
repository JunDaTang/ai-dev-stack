#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common.sh"

if need_cmd codex; then
  log "Codex already available: $(command -v codex)"
  codex --version || true
  exit 0
fi
need_cmd npm || { err "npm not found. Install Node.js/npm first."; exit 1; }
run npm install -g @openai/codex
