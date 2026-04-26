#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fail() {
  echo "[FAIL] $*" >&2
  exit 1
}

ok() {
  echo "[OK] $*"
}

assert_file() {
  local path="$1"
  [[ -f "$path" ]] || fail "missing file: $path"
  ok "file exists: $path"
}

assert_executable() {
  local path="$1"
  assert_file "$path"
  [[ -x "$path" ]] || fail "not executable: $path"
  ok "executable: $path"
}

assert_contains() {
  local path="$1"
  local needle="$2"
  grep -Fq -- "$needle" "$path" || fail "missing text in $path: $needle"
  ok "$path contains: $needle"
}

assert_not_contains_regex() {
  local path="$1"
  local regex="$2"
  if grep -Eiq -- "$regex" "$path"; then
    fail "potential secret or forbidden pattern in $path: $regex"
  fi
  ok "$path does not match forbidden pattern: $regex"
}

# Core entrypoints
assert_executable "install.sh"
assert_executable "scripts/common.sh"
assert_executable "scripts/configure-shell.sh"
assert_executable "scripts/healthcheck.sh"
assert_executable "scripts/install-claude-code.sh"
assert_executable "scripts/install-codex.sh"
assert_executable "scripts/install-cc-switch.sh"
assert_executable "scripts/install-mihomo.sh"
assert_executable "scripts/install-cliproxyapi.sh"
assert_executable "scripts/install-hermes.sh"
assert_executable "tests/shellcheck.sh"

# Documentation and examples
assert_file "README.md"
assert_file ".gitignore"
assert_file "examples/config.example.env"
assert_file "examples/wsl.example.env"
assert_file "profiles/minimal.env"
assert_file "profiles/wsl.env"
assert_file "docs/troubleshooting.md"
assert_file "docs/secrets.md"

# Required behavior and safety markers
assert_contains "install.sh" "--profile"
assert_contains "install.sh" "--dry-run"
assert_contains "install.sh" "doctor"
assert_contains "scripts/common.sh" "DRY_RUN"
assert_contains "scripts/common.sh" "backup_file"
assert_contains "scripts/configure-shell.sh" "/.hermes/node/bin"
assert_contains "scripts/healthcheck.sh" "CLIProxyAPI"
assert_contains ".gitignore" ".env"
assert_contains ".gitignore" "*.key"
assert_contains "README.md" "AI Coding Workstation"
assert_contains "examples/config.example.env" "CLIPROXY_BASE_URL"
assert_contains "examples/config.example.env" "[REDACTED]"

# Keep examples/template safe: no real-looking secrets committed.
while IFS= read -r -d '' file; do
  assert_not_contains_regex "$file" '(sk-[A-Za-z0-9_-]{20,}|ghp_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{20,})'
  assert_not_contains_regex "$file" 'clash.*subscription.*https?://'
  assert_not_contains_regex "$file" 'api[_-]?key=[A-Za-z0-9_-]{16,}'
done < <(find . -type f \
  -not -path './.git/*' \
  -not -path './tests/smoke-test.sh' \
  -print0)

# Profiles should not claim unfinished installers are enabled by default.
assert_contains "profiles/wsl.env" "INSTALL_MIHOMO=0"
assert_contains "profiles/wsl.env" "INSTALL_CLIPROXYAPI=0"
assert_contains "profiles/ubuntu-server.env" "INSTALL_MIHOMO=0"
assert_contains "profiles/ubuntu-server.env" "INSTALL_CLIPROXYAPI=0"
assert_contains "profiles/china-server.env" "INSTALL_MIHOMO=0"
assert_contains "profiles/china-server.env" "INSTALL_CLIPROXYAPI=0"

# Partial installers must report explicit skip status.
assert_contains "scripts/common.sh" "[SKIP]"
assert_contains "scripts/install-mihomo.sh" "skip \""
assert_contains "scripts/install-cliproxyapi.sh" "skip \""
assert_contains "scripts/install-hermes.sh" "skip \""

# Dry-run should not mutate system and must complete.
bash install.sh --profile minimal --dry-run
bash install.sh --profile wsl --dry-run
bash install.sh --profile ubuntu-server --dry-run
bash install.sh --profile china-server --dry-run
bash install.sh doctor --dry-run

ok "smoke test passed"
