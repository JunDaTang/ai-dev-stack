#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common.sh"

CLIPROXY_BASE_URL="${CLIPROXY_BASE_URL:-http://127.0.0.1:8317}"
log "CLIProxyAPI base URL: $CLIPROXY_BASE_URL"
skip "CLIProxyAPI installer not implemented yet; configure or deploy it manually for now."
warn "Keep CLIProxyAPI credentials in .env only."
