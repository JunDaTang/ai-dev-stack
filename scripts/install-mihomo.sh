#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common.sh"
load_env_file "$ROOT_DIR/.env"

MIHOMO_VERSION="${MIHOMO_VERSION:-v1.19.24}"
MIHOMO_BINARY_PATH="${MIHOMO_BINARY_PATH:-/usr/local/bin/mihomo}"
MIHOMO_CONFIG_DIR="${MIHOMO_CONFIG_DIR:-$HOME/clashd}"
MIHOMO_CONFIG_PATH="${MIHOMO_CONFIG_PATH:-$MIHOMO_CONFIG_DIR/config.yaml}"
MIHOMO_SERVICE_NAME="${MIHOMO_SERVICE_NAME:-clash.service}"
MIHOMO_SERVICE_PATH="${MIHOMO_SERVICE_PATH:-/etc/systemd/system/$MIHOMO_SERVICE_NAME}"
MIHOMO_TEMPLATE_PATH="${MIHOMO_TEMPLATE_PATH:-$ROOT_DIR/templates/clash.service}"
MIHOMO_DOWNLOAD_URL="${MIHOMO_DOWNLOAD_URL:-}"
CLASH_SUBSCRIPTION_URL="${CLASH_SUBSCRIPTION_URL:-}"

is_placeholder_value() {
  local value="$1"
  [[ -z "$value" || "$value" == "[REDACTED]" || "$value" == "***" ]]
}

as_root() {
  if [[ "$(id -u)" == "0" ]]; then
    run "$@"
  else
    need_cmd sudo || { err "sudo not found; cannot install Mihomo to system paths"; exit 1; }
    run sudo "$@"
  fi
}

resolve_arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo "amd64" ;;
    aarch64|arm64) echo "arm64" ;;
    armv7l|armv7) echo "armv7" ;;
    *) err "unsupported architecture for Mihomo: $(uname -m)"; exit 1 ;;
  esac
}

resolve_download_url() {
  local arch url
  if [[ -n "$MIHOMO_DOWNLOAD_URL" ]]; then
    printf '%s\n' "$MIHOMO_DOWNLOAD_URL"
    return 0
  fi
  arch="$(resolve_arch)"
  url="https://github.com/MetaCubeX/mihomo/releases/download/${MIHOMO_VERSION}/mihomo-linux-${arch}-${MIHOMO_VERSION}.gz"
  if [[ "${USE_GITHUB_MIRROR:-0}" == "1" ]]; then
    url="https://ghproxy.net/${url}"
  fi
  printf '%s\n' "$url"
}

# Download from URL with multiple fallback sources
download_with_fallback() {
  local dest="$1" desc="$2"
  shift 2
  local urls=("$@")
  local tmp_file

  tmp_file="$(mktemp)"
  for url in "${urls[@]}"; do
    log "trying to download ${desc} from ${url}"
    if curl -fsSL --connect-timeout 15 --max-time 90 "$url" -o "$tmp_file" 2>/dev/null; then
      mv "$tmp_file" "$dest"
      log "downloaded ${desc} successfully"
      return 0
    fi
    log "failed to download ${desc} from ${url}"
  done
  rm -f "$tmp_file"
  return 1
}

# Pre-download MMDB and GeoSite so Mihomo doesn't fail on first start
ensure_mmdb_geosite() {
  local mmdb_path="${MIHOMO_CONFIG_DIR}/geoip.metadb"
  local geosite_path="${MIHOMO_CONFIG_DIR}/geosite.dat"
  local arch="${MIHOMO_MMDB_ARCH:-release}"  # release or prerelease

  ensure_dir "$MIHOMO_CONFIG_DIR"

  if [[ ! -f "$mmdb_path" ]]; then
    download_with_fallback "$mmdb_path" "MMDB" \
      "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@${arch}/geoip.metadb" \
      "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@${arch}/geoip.metadb" \
      "https://github.com/MetaCubeX/meta-rules-dat/raw/${arch}/geoip.metadb" \
      "https://ghproxy.net/https://github.com/MetaCubeX/meta-rules-dat/raw/${arch}/geoip.metadb" \
    || warn "MMDB download failed; Mihomo will auto-download on start"
  fi

  if [[ ! -f "$geosite_path" ]]; then
    download_with_fallback "$geosite_path" "GeoSite" \
      "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@${arch}/geosite.dat" \
      "https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@${arch}/geosite.dat" \
      "https://github.com/MetaCubeX/meta-rules-dat/raw/${arch}/geosite.dat" \
      "https://ghproxy.net/https://github.com/MetaCubeX/meta-rules-dat/raw/${arch}/geosite.dat" \
    || warn "GeoSite download failed; Mihomo will auto-download on start"
  fi
}

install_binary() {
  local tmp_dir archive extracted url
  if [[ -x "$MIHOMO_BINARY_PATH" ]]; then
    log "Mihomo already available at target path: $MIHOMO_BINARY_PATH"
    "$MIHOMO_BINARY_PATH" -v || true
    return 0
  fi

  url="$(resolve_download_url)"
  log "installing Mihomo ${MIHOMO_VERSION} to $MIHOMO_BINARY_PATH"
  if [[ "${DRY_RUN}" == "1" ]]; then
    log "would download Mihomo from $url"
    log "would install Mihomo binary to $MIHOMO_BINARY_PATH"
    return 0
  fi

  need_cmd curl || { err "curl not found"; exit 1; }
  need_cmd gunzip || { err "gunzip not found"; exit 1; }

  tmp_dir="$(mktemp -d)"
  archive="$tmp_dir/mihomo.gz"
  extracted="$tmp_dir/mihomo"

  if ! download_with_fallback "$archive" "Mihomo binary" "$url"; then
    err "Mihomo binary download failed from all sources"
    exit 1
  fi

  gunzip -c "$archive" > "$extracted"
  chmod +x "$extracted"
  as_root install -Dm755 "$extracted" "$MIHOMO_BINARY_PATH"
  "$MIHOMO_BINARY_PATH" -v || true
}

install_config() {
  local tmp_dir downloaded_config

  ensure_dir "$MIHOMO_CONFIG_DIR"

  if is_placeholder_value "$CLASH_SUBSCRIPTION_URL"; then
    if [[ -f "$MIHOMO_CONFIG_PATH" ]]; then
      log "existing Mihomo config preserved: $MIHOMO_CONFIG_PATH"
      return 0
    fi
    if [[ "${DRY_RUN}" == "1" ]]; then
      warn "dry-run: Mihomo config would require a valid CLASH_SUBSCRIPTION_URL or a pre-existing $MIHOMO_CONFIG_PATH"
      return 0
    fi
    err "CLASH_SUBSCRIPTION_URL is not configured and no existing Mihomo config was found at $MIHOMO_CONFIG_PATH"
    exit 1
  fi

  if [[ "${DRY_RUN}" == "1" ]]; then
    log "would download Mihomo subscription to $MIHOMO_CONFIG_PATH"
    return 0
  fi

  need_cmd curl || { err "curl not found"; exit 1; }

  tmp_dir="$(mktemp -d)"
  downloaded_config="$tmp_dir/config.yaml"
  curl -fsSL -A "ClashMeta/${MIHOMO_VERSION}" "$CLASH_SUBSCRIPTION_URL" -o "$downloaded_config"

  if [[ -f "$MIHOMO_CONFIG_PATH" ]]; then
    backup_file "$MIHOMO_CONFIG_PATH"
  fi
  install -m600 "$downloaded_config" "$MIHOMO_CONFIG_PATH"
  log "Mihomo config installed: $MIHOMO_CONFIG_PATH"
}

install_service() {
  local tmp_dir rendered_service
  [[ -f "$MIHOMO_TEMPLATE_PATH" ]] || { err "missing service template: $MIHOMO_TEMPLATE_PATH"; exit 1; }

  tmp_dir="$(mktemp -d)"
  rendered_service="$tmp_dir/$MIHOMO_SERVICE_NAME"
  sed \
    -e "s#__MIHOMO_BINARY_PATH__#$MIHOMO_BINARY_PATH#g" \
    -e "s#__MIHOMO_CONFIG_DIR__#$MIHOMO_CONFIG_DIR#g" \
    -e "s#__MIHOMO_CONFIG_PATH__#$MIHOMO_CONFIG_PATH#g" \
    "$MIHOMO_TEMPLATE_PATH" > "$rendered_service"

  as_root install -Dm644 "$rendered_service" "$MIHOMO_SERVICE_PATH"

  if ! need_cmd systemctl; then
    warn "systemctl not found; installed service file but did not enable $MIHOMO_SERVICE_NAME"
    return 0
  fi

  as_root systemctl daemon-reload
  as_root systemctl enable --now "$MIHOMO_SERVICE_NAME"

  if [[ "${DRY_RUN}" == "1" ]]; then
    log "would verify systemctl status for $MIHOMO_SERVICE_NAME"
  elif as_root systemctl is-active --quiet "$MIHOMO_SERVICE_NAME"; then
    log "Mihomo service active: $MIHOMO_SERVICE_NAME"
  else
    warn "Mihomo service is not active yet: $MIHOMO_SERVICE_NAME"
  fi
}

log "starting Mihomo installer"
log "binary path: $MIHOMO_BINARY_PATH"
log "config path: $MIHOMO_CONFIG_PATH"
log "service name: $MIHOMO_SERVICE_NAME"

install_binary
install_config
ensure_mmdb_geosite
install_service

log "Mihomo installer finished"
