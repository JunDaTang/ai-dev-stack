#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common.sh"

if need_cmd hermes; then
  log "Hermes already available: $(command -v hermes)"
  exit 0
fi
skip "Hermes installer is not implemented; this repo currently supports PATH integration only."
log "If Hermes is already installed under ~/.hermes, configure-shell.sh exposes ~/.hermes/node/bin."
