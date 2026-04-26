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

check_linux_local_cmd() {
  local name="$1"
  if ! need_cmd "$name"; then
    printf '[WARN] %s not found for Linux-local path check\n' "$name"
    return 0
  fi
  local resolved
  resolved="$(command -v "$name")"
  case "$resolved" in
    /mnt/c/*|/mnt/d/*|/mnt/e/*)
      printf '[WARN] %s uses Windows shim path: %s\n' "$name" "$resolved"
      ;;
    *)
      printf '[OK] %s uses Linux-local path: %s\n' "$name" "$resolved"
      ;;
  esac
}

check_placeholder_env() {
  local name="$1"
  local value="${!name:-}"
  [[ -n "$value" ]] || return 0
  case "$value" in
    "[REDACTED]"|"***")
      printf '[WARN] %s still uses placeholder value: %s\n' "$name" "$value"
      ;;
  esac
}

check_proxy_setting() {
  local key="$1"
  local value
  value="$(git config --global --get "$key" 2>/dev/null || true)"
  if [[ -n "$value" ]]; then
    printf '[OK] git %s=%s\n' "$key" "$value"
  else
    printf '[WARN] git %s not set\n' "$key"
  fi
}

check_gh_auth() {
  if ! need_cmd gh; then
    echo '[WARN] gh not found'
    return 0
  fi
  if [[ "${DRY_RUN}" == "1" ]]; then
    log 'would run gh auth status'
    return 0
  fi
  if gh auth status >/dev/null 2>&1; then
    echo '[OK] gh auth status succeeded'
  else
    echo '[WARN] gh auth status failed'
  fi
}

check_cmd claude
check_cmd codex
check_cmd cc-switch
check_cmd mihomo
check_linux_local_cmd claude
check_linux_local_cmd codex
check_linux_local_cmd cc-switch
check_gh_auth
check_proxy_setting http.proxy
check_proxy_setting https.proxy
check_placeholder_env CLASH_SUBSCRIPTION_URL
check_placeholder_env CLIPROXY_API_KEY

CLIPROXY_WORKDIR="${CLIPROXY_WORKDIR:-$HOME/cliproxyapi}"
CLIPROXY_CONFIG_PATH="${CLIPROXY_CONFIG_PATH:-$CLIPROXY_WORKDIR/config.yaml}"
CLIPROXY_SERVICE_NAME="${CLIPROXY_SERVICE_NAME:-cliproxyapi.service}"
CLIPROXY_BASE_URL="${CLIPROXY_BASE_URL:-http://127.0.0.1:8317}"

if [[ -d "$CLIPROXY_WORKDIR" ]]; then
  echo "[OK] CLIProxyAPI workdir exists: $CLIPROXY_WORKDIR"
else
  echo "[WARN] CLIProxyAPI workdir missing: $CLIPROXY_WORKDIR"
fi

if [[ -f "$CLIPROXY_CONFIG_PATH" ]]; then
  echo "[OK] CLIProxyAPI config exists: $CLIPROXY_CONFIG_PATH"
else
  echo "[WARN] CLIProxyAPI config missing: $CLIPROXY_CONFIG_PATH"
fi

if [[ "${DRY_RUN}" == "1" ]]; then
  log "would check CLIProxyAPI at $CLIPROXY_BASE_URL"
  log "would check systemctl --user status $CLIPROXY_SERVICE_NAME"
elif command -v curl >/dev/null 2>&1 && curl -fsS --max-time 3 "$CLIPROXY_BASE_URL" >/dev/null 2>&1; then
  echo "[OK] CLIProxyAPI reachable: $CLIPROXY_BASE_URL"
else
  echo "[WARN] CLIProxyAPI not reachable: $CLIPROXY_BASE_URL"
fi

if [[ "${DRY_RUN}" != "1" ]] && need_cmd systemctl; then
  if systemctl --user is-active --quiet "$CLIPROXY_SERVICE_NAME"; then
    echo "[OK] CLIProxyAPI user service active: $CLIPROXY_SERVICE_NAME"
  else
    echo "[WARN] CLIProxyAPI user service not active: $CLIPROXY_SERVICE_NAME"
  fi
fi

if is_wsl; then
  case ":$PATH:" in
    *:"$HOME/.hermes/node/bin":*) echo "[OK] WSL PATH contains ~/.hermes/node/bin" ;;
    *) echo "[WARN] WSL PATH missing ~/.hermes/node/bin" ;;
  esac
fi
