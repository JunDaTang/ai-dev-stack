#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common.sh"

if need_cmd cc-switch; then
  log "cc-switch already available: $(command -v cc-switch)"
  cc-switch --version || true
  exit 0
fi
ensure_dir "$HOME/.local/bin"
URL="https://github.com/SaladDay/cc-switch-cli/releases/latest/download/install.sh"
if [[ "${DRY_RUN}" == "1" ]]; then
  log "would download and run $URL"
else
  tmp="$(mktemp -d)"
  curl -fsSL "$URL" -o "$tmp/install.sh"
  CC_SWITCH_FORCE=1 CC_SWITCH_INSTALL_DIR="$HOME/.local/bin" CC_SWITCH_LINUX_LIBC=glibc bash "$tmp/install.sh"
fi
