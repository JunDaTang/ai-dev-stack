#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common.sh"

if need_cmd mihomo; then
  log "Mihomo already available: $(command -v mihomo)"
  mihomo -v || true
  exit 0
fi
warn "Mihomo installer is intentionally conservative in MVP."
warn "Set INSTALL_MIHOMO=1 only after reviewing docs; subscription URL stays in .env and must not be committed."
log "recommended binary target: /usr/local/bin/mihomo; config: /etc/mihomo/config.yaml or ~/clashd/config.yaml"
