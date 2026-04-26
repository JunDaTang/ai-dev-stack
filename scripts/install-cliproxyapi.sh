#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common.sh"
load_env_file "$ROOT_DIR/.env"

CLIPROXY_WORKDIR="${CLIPROXY_WORKDIR:-$HOME/cliproxyapi}"
CLIPROXY_CONFIG_PATH="${CLIPROXY_CONFIG_PATH:-$CLIPROXY_WORKDIR/config.yaml}"
CLIPROXY_BINARY_PATH="${CLIPROXY_BINARY_PATH:-$CLIPROXY_WORKDIR/cli-proxy-api}"
CLIPROXY_SERVICE_NAME="${CLIPROXY_SERVICE_NAME:-cliproxyapi.service}"
CLIPROXY_BASE_URL="${CLIPROXY_BASE_URL:-http://127.0.0.1:8317}"
CLIPROXY_PROXY_URL="${CLIPROXY_PROXY_URL:-http://127.0.0.1:7890}"
CLIPROXY_PORT="${CLIPROXY_PORT:-8317}"
CLIPROXY_TEMPLATE_PATH="${CLIPROXY_TEMPLATE_PATH:-$ROOT_DIR/templates/cliproxyapi.service}"

ensure_config_value() {
  local key="$1"
  local value="$2"

  if grep -Eq "^[[:space:]]*${key}:" "$CLIPROXY_CONFIG_PATH"; then
    python3 - "$CLIPROXY_CONFIG_PATH" "$key" "$value" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
key = sys.argv[2]
value = sys.argv[3]
text = path.read_text()
pattern = re.compile(rf'^(\s*{re.escape(key)}:\s*).*$' , re.MULTILINE)
text, count = pattern.subn(lambda m: f'{m.group(1)}"{value}"', text, count=1)
if count == 0:
    raise SystemExit(f"missing key: {key}")
path.write_text(text)
PY
  else
    printf '\n%s: "%s"\n' "$key" "$value" >> "$CLIPROXY_CONFIG_PATH"
  fi
}

install_service() {
  local user_unit_dir rendered_service tmp_dir
  [[ -f "$CLIPROXY_TEMPLATE_PATH" ]] || { err "missing service template: $CLIPROXY_TEMPLATE_PATH"; exit 1; }

  user_unit_dir="$HOME/.config/systemd/user"
  tmp_dir="$(mktemp -d)"
  rendered_service="$tmp_dir/$CLIPROXY_SERVICE_NAME"

  sed \
    -e "s#__CLIPROXY_WORKDIR__#$CLIPROXY_WORKDIR#g" \
    -e "s#__CLIPROXY_BINARY_PATH__#$CLIPROXY_BINARY_PATH#g" \
    -e "s#__CLIPROXY_CONFIG_PATH__#$CLIPROXY_CONFIG_PATH#g" \
    "$CLIPROXY_TEMPLATE_PATH" > "$rendered_service"

  ensure_dir "$user_unit_dir"
  if [[ -f "$user_unit_dir/$CLIPROXY_SERVICE_NAME" ]]; then
    backup_file "$user_unit_dir/$CLIPROXY_SERVICE_NAME"
  fi

  if [[ "${DRY_RUN}" == "1" ]]; then
    log "would install user service to $user_unit_dir/$CLIPROXY_SERVICE_NAME"
    log "would run systemctl --user daemon-reload"
    log "would run systemctl --user enable --now $CLIPROXY_SERVICE_NAME"
    return 0
  fi

  install -m644 "$rendered_service" "$user_unit_dir/$CLIPROXY_SERVICE_NAME"

  if ! need_cmd systemctl; then
    warn "systemctl not found; installed user service file but did not enable $CLIPROXY_SERVICE_NAME"
    return 0
  fi

  systemctl --user daemon-reload
  systemctl --user enable --now "$CLIPROXY_SERVICE_NAME"

  if systemctl --user is-active --quiet "$CLIPROXY_SERVICE_NAME"; then
    log "CLIProxyAPI service active: $CLIPROXY_SERVICE_NAME"
  else
    warn "CLIProxyAPI service is not active yet: $CLIPROXY_SERVICE_NAME"
  fi
}

verify_reachable() {
  if [[ "${DRY_RUN}" == "1" ]]; then
    log "would verify CLIProxyAPI at $CLIPROXY_BASE_URL"
    return 0
  fi

  if ! need_cmd curl; then
    warn "curl not found; skipping CLIProxyAPI reachability check"
    return 0
  fi

  if curl -fsS --max-time 3 "$CLIPROXY_BASE_URL" >/dev/null 2>&1; then
    log "CLIProxyAPI reachable: $CLIPROXY_BASE_URL"
  else
    warn "CLIProxyAPI not reachable yet: $CLIPROXY_BASE_URL"
  fi
}

log "starting CLIProxyAPI installer"
log "workdir: $CLIPROXY_WORKDIR"
log "config path: $CLIPROXY_CONFIG_PATH"
log "service name: $CLIPROXY_SERVICE_NAME"

[[ -d "$CLIPROXY_WORKDIR" ]] || { err "CLIProxyAPI workdir not found: $CLIPROXY_WORKDIR"; exit 1; }
[[ -x "$CLIPROXY_BINARY_PATH" ]] || { err "CLIProxyAPI binary not found or not executable: $CLIPROXY_BINARY_PATH"; exit 1; }
[[ -f "$CLIPROXY_CONFIG_PATH" ]] || { err "CLIProxyAPI config not found: $CLIPROXY_CONFIG_PATH"; exit 1; }

if [[ -f "$CLIPROXY_CONFIG_PATH" ]]; then
  backup_file "$CLIPROXY_CONFIG_PATH"
fi

if [[ "${DRY_RUN}" == "1" ]]; then
  log "would set proxy-url to $CLIPROXY_PROXY_URL in $CLIPROXY_CONFIG_PATH"
  log "would set port to $CLIPROXY_PORT in $CLIPROXY_CONFIG_PATH"
else
  ensure_config_value "proxy-url" "$CLIPROXY_PROXY_URL"
  ensure_config_value "port" "$CLIPROXY_PORT"
fi

install_service
verify_reachable

log "CLIProxyAPI installer finished"
