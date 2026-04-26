#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common.sh"
load_env_file "$ROOT_DIR/.env"

check_cmd() {
  local name="$1"
  if need_cmd "$name"; then
    printf '[OK] %s: %s\n' "$name" "$(command -v "$name")"
    "$name" --version 2>/dev/null | head -1 || true
  else
    printf '[WARN] %s not found\n' "$name"
  fi
}

check_cmd claude
check_cmd codex
check_cmd cc-switch
check_cmd mihomo

CLIPROXY_BASE_URL="${CLIPROXY_BASE_URL:-http://127.0.0.1:8317}"
if [[ "${DRY_RUN}" == "1" ]]; then
  log "would check CLIProxyAPI at $CLIPROXY_BASE_URL"
elif command -v curl >/dev/null 2>&1 && curl -fsS --max-time 3 "$CLIPROXY_BASE_URL" >/dev/null 2>&1; then
  echo "[OK] CLIProxyAPI reachable: $CLIPROXY_BASE_URL"
else
  echo "[WARN] CLIProxyAPI not reachable: $CLIPROXY_BASE_URL"
fi

if is_wsl; then
  case ":$PATH:" in
    *:"$HOME/.hermes/node/bin":*) echo "[OK] WSL PATH contains ~/.hermes/node/bin" ;;
    *) echo "[WARN] WSL PATH missing ~/.hermes/node/bin" ;;
  esac
fi
