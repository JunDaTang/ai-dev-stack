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

CC_SWITCH_REPO="${CC_SWITCH_REPO:-SaladDay/cc-switch-cli}"
CC_SWITCH_LINUX_LIBC="${CC_SWITCH_LINUX_LIBC:-glibc}"

# Detect architecture
case "$(uname -m)" in
  x86_64|amd64) arch="x64" ;;
  aarch64|arm64) arch="arm64" ;;
  *) err "unsupported architecture for cc-switch: $(uname -m)"; exit 1 ;;
esac

resolve_cc_switch_url() {
  local native_url mirror_url
  native_url="https://github.com/${CC_SWITCH_REPO}/releases/latest/download/cc-switch-cli-linux-${arch}.tar.gz"

  # Use GitHub mirror when requested (e.g. ghproxy.net for China/walled-garden)
  if [[ "${USE_GITHUB_MIRROR:-0}" == "1" ]]; then
    printf '%s\n' "https://ghproxy.net/${native_url}"
  else
    printf '%s\n' "$native_url"
  fi
}

resolve_cc_switch_musl_url() {
  local native_url mirror_url
  native_url="https://github.com/${CC_SWITCH_REPO}/releases/latest/download/cc-switch-cli-linux-${arch}-musl.tar.gz"

  if [[ "${USE_GITHUB_MIRROR:-0}" == "1" ]]; then
    printf '%s\n' "https://ghproxy.net/${native_url}"
  else
    printf '%s\n' "$native_url"
  fi
}

install_from_url() {
  local url="$1"
  local tmp_dir tmp_archive

  tmp_dir="$(mktemp -d)"
  tmp_archive="$tmp_dir/cc-switch.tar.gz"

  log "downloading cc-switch from ${url}"
  if ! curl -fsSL --connect-timeout 15 --max-time 90 "$url" -o "$tmp_archive"; then
    rm -rf "$tmp_dir"
    return 1
  fi

  tar xzf "$tmp_archive" -C "$tmp_dir" 2>/dev/null || {
    # Some archives have a subdirectory
    extracted_dir=$(mktemp -d)
    tar xzf "$tmp_archive" -C "$extracted_dir"
    find "$extracted_dir" -name "cc-switch" -type f -exec mv {} "$tmp_dir/" \;
    rm -rf "$extracted_dir"
  }

  if [[ ! -f "$tmp_dir/cc-switch" ]]; then
    rm -rf "$tmp_dir"
    return 1
  fi

  install -m755 "$tmp_dir/cc-switch" "$HOME/.local/bin/cc-switch"
  rm -rf "$tmp_dir"
  return 0
}

if [[ "${DRY_RUN}" == "1" ]]; then
  log "would download and install cc-switch (${CC_SWITCH_LINUX_LIBC}, ${arch})"
else
  # Try primary URL first
  if [[ "$CC_SWITCH_LINUX_LIBC" == "musl" ]]; then
    install_from_url "$(resolve_cc_switch_musl_url)" || {
      # Fallback to glibc if musl fails
      warn "musl download failed, falling back to glibc"
      install_from_url "$(resolve_cc_switch_url)"
    }
  else
    install_from_url "$(resolve_cc_switch_url)" || {
      # If mirror is enabled and primary fails, try direct
      if [[ "${USE_GITHUB_MIRROR:-0}" == "1" ]]; then
        warn "mirror download failed, falling back to direct GitHub"
        install_from_url "https://github.com/${CC_SWITCH_REPO}/releases/latest/download/cc-switch-cli-linux-${arch}.tar.gz"
      else
        # Try musl variant as fallback
        warn "glibc download failed, trying musl variant"
        install_from_url "$(resolve_cc_switch_musl_url)"
      fi
    }
  fi

  if need_cmd cc-switch; then
    log "cc-switch installed: $(command -v cc-switch)"
    cc-switch --version || true
  else
    err "cc-switch installation failed"
    exit 1
  fi
fi
