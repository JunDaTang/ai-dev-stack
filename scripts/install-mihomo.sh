#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common.sh"

if need_cmd mihomo; then
  log "Mihomo already available: $(command -v mihomo)"
  mihomo -v || true
  exit 0
fi
skip "Mihomo installer not implemented yet; configure manually for now."
warn "Set INSTALL_MIHOMO=1 only after the installer is implemented and reviewed; subscription URL stays in .env and must not be committed."
log "recommended manual target: /usr/local/bin/mihomo; config: /etc/mihomo/config.yaml or ~/clashd/config.yaml"
