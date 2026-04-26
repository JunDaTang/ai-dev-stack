#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common.sh"

ENV_FILE="$HOME/.local/bin/env"
ensure_dir "$HOME/.local/bin"
backup_file "$ENV_FILE"
if [[ "${DRY_RUN}" == "1" ]]; then
  log "would write $ENV_FILE"
else
  cat > "$ENV_FILE" <<'EOF'
#!/bin/sh
# ai-dev-stack: prefer Linux-local AI CLI binaries before Windows PATH entries in WSL.
for dir in "$HOME/.hermes/node/bin" "$HOME/.local/bin"; do
    case ":${PATH}:" in
        *:"$dir":*) ;;
        *) export PATH="$dir:$PATH" ;;
    esac
done
EOF
  chmod +x "$ENV_FILE"
fi

BLOCK=$(cat <<'EOF'
if [ -f "$HOME/.local/bin/env" ]; then . "$HOME/.local/bin/env"; fi
EOF
)
append_once "$HOME/.bashrc" "# ai-dev-stack PATH" "$BLOCK"
append_once "$HOME/.profile" "# ai-dev-stack PATH" "$BLOCK"
log "shell configured; run: source ~/.bashrc && hash -r"
