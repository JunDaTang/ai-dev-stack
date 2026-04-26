#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck install.sh scripts/*.sh tests/*.sh
else
  echo "[WARN] shellcheck not installed; running bash -n fallback"
  bash -n install.sh scripts/*.sh tests/*.sh
fi
