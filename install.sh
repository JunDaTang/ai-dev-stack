#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$ROOT_DIR/scripts/common.sh"

usage() {
  cat <<'EOF'
AI Coding Workstation bootstrap for Ubuntu/WSL.

Usage:
  ./install.sh [--profile minimal|wsl|ubuntu-server|china-server] [--dry-run] [--non-interactive]
  ./install.sh doctor [--dry-run]

Examples:
  cp examples/config.example.env .env
  ./install.sh --profile wsl
  ./install.sh --profile minimal --dry-run
  ./install.sh doctor
EOF
}

COMMAND="install"
while [[ $# -gt 0 ]]; do
  case "$1" in
    doctor) COMMAND="doctor"; shift ;;
    --profile) PROFILE="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; export DRY_RUN; shift ;;
    --non-interactive) NON_INTERACTIVE=1; export NON_INTERACTIVE; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "unknown argument: $1"; usage; exit 2 ;;
  esac
done

load_env_file "$ROOT_DIR/profiles/${PROFILE}.env"
load_env_file "$ROOT_DIR/.env"

if [[ "$COMMAND" == "doctor" ]]; then
  exec "$ROOT_DIR/scripts/healthcheck.sh"
fi

log "profile=${PROFILE} dry_run=${DRY_RUN}"

[[ "${INSTALL_SHELL:-1}" == "1" ]] && "$ROOT_DIR/scripts/configure-shell.sh"
[[ "${INSTALL_HERMES:-0}" == "1" ]] && "$ROOT_DIR/scripts/install-hermes.sh"
[[ "${INSTALL_CLAUDE:-1}" == "1" ]] && "$ROOT_DIR/scripts/install-claude-code.sh"
[[ "${INSTALL_CODEX:-1}" == "1" ]] && "$ROOT_DIR/scripts/install-codex.sh"
[[ "${INSTALL_CC_SWITCH:-1}" == "1" ]] && "$ROOT_DIR/scripts/install-cc-switch.sh"
[[ "${INSTALL_MIHOMO:-0}" == "1" ]] && "$ROOT_DIR/scripts/install-mihomo.sh"
[[ "${INSTALL_CLIPROXYAPI:-0}" == "1" ]] && "$ROOT_DIR/scripts/install-cliproxyapi.sh"

log "done. Run: ./install.sh doctor"
