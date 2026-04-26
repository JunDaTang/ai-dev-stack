#!/usr/bin/env bash
set -euo pipefail

AI_DEV_STACK_DIR="${AI_DEV_STACK_DIR:-$HOME/.ai-dev-stack}"
DRY_RUN="${DRY_RUN:-0}"
NON_INTERACTIVE="${NON_INTERACTIVE:-0}"
PROFILE="${PROFILE:-wsl}"

log() { printf '[ai-dev-stack] %s\n' "$*"; }
warn() { printf '[ai-dev-stack][WARN] %s\n' "$*" >&2; }
err() { printf '[ai-dev-stack][ERROR] %s\n' "$*" >&2; }

run() {
  if [[ "${DRY_RUN}" == "1" ]]; then
    printf '[dry-run] %q ' "$@"; printf '\n'
  else
    "$@"
  fi
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || return 1
}

ensure_dir() {
  local dir="$1"
  [[ "${DRY_RUN}" == "1" ]] && { log "would create dir: $dir"; return 0; }
  mkdir -p "$dir"
}

backup_file() {
  local file="$1"
  [[ -e "$file" ]] || return 0
  local stamp backup_dir backup
  stamp="$(date +%Y%m%d-%H%M%S)"
  backup_dir="$AI_DEV_STACK_DIR/backups"
  backup="$backup_dir/$(basename "$file").$stamp.bak"
  ensure_dir "$backup_dir"
  run cp -a "$file" "$backup"
  log "backup: $file -> $backup"
}

append_once() {
  local file="$1" marker="$2" content="$3"
  if [[ -f "$file" ]] && grep -Fq "$marker" "$file"; then
    log "already configured: $file ($marker)"
    return 0
  fi
  backup_file "$file"
  if [[ "${DRY_RUN}" == "1" ]]; then
    log "would append block to $file: $marker"
  else
    printf '\n%s\n%s\n' "$marker" "$content" >> "$file"
  fi
}

load_env_file() {
  local env_file="$1"
  [[ -f "$env_file" ]] || return 0
  set -a
  # shellcheck disable=SC1090
  source "$env_file"
  set +a
}

is_wsl() {
  grep -qi microsoft /proc/version 2>/dev/null
}
