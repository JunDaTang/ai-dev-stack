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
assert_contains "scripts/healthcheck.sh" "gh auth status"
assert_contains "scripts/healthcheck.sh" "http.proxy"
assert_contains "scripts/healthcheck.sh" "https.proxy"
assert_contains "scripts/healthcheck.sh" "[REDACTED]"
assert_contains "scripts/healthcheck.sh" "Windows shim"
assert_contains ".gitignore" ".env"
assert_contains ".gitignore" "*.key"
assert_contains "README.md" "AI Coding Workstation"
assert_contains "examples/config.example.env" "CLIPROXY_BASE_URL"
assert_contains "examples/config.example.env" "CLIPROXY_WORKDIR"
assert_contains "examples/config.example.env" "CLIPROXY_CONFIG_PATH"
assert_contains "examples/config.example.env" "CLIPROXY_BINARY_PATH"
assert_contains "examples/config.example.env" "CLIPROXY_SERVICE_NAME"
assert_contains "examples/config.example.env" "CLIPROXY_PROXY_URL"
assert_contains "examples/config.example.env" "CLIPROXY_PORT"
assert_contains "examples/config.example.env" "[REDACTED]"
assert_contains "examples/config.example.env" "MIHOMO_VERSION"
assert_contains "examples/config.example.env" "MIHOMO_CONFIG_DIR"
assert_contains "examples/config.example.env" "MIHOMO_BINARY_PATH"
assert_contains "examples/config.example.env" "MIHOMO_SERVICE_NAME"
assert_contains "examples/wsl.example.env" "MIHOMO_VERSION"
assert_contains "examples/wsl.example.env" "MIHOMO_BINARY_PATH"
assert_contains "examples/wsl.example.env" "MIHOMO_CONFIG_DIR"
assert_contains "examples/wsl.example.env" "MIHOMO_CONFIG_PATH"
assert_contains "examples/wsl.example.env" "MIHOMO_SERVICE_NAME"
assert_contains "examples/wsl.example.env" "CLIPROXY_WORKDIR"
assert_contains "examples/wsl.example.env" "CLIPROXY_CONFIG_PATH"
assert_contains "examples/wsl.example.env" "CLIPROXY_BINARY_PATH"
assert_contains "examples/wsl.example.env" "CLIPROXY_SERVICE_NAME"
assert_contains "examples/wsl.example.env" "CLIPROXY_PROXY_URL"
assert_contains "examples/wsl.example.env" "CLIPROXY_PORT"
assert_contains "examples/wsl.example.env" "INSTALL_MIHOMO=0"
assert_contains "examples/wsl.example.env" "INSTALL_CLIPROXYAPI=0"
assert_contains "scripts/install-mihomo.sh" "MIHOMO_BINARY_PATH"
assert_contains "scripts/install-mihomo.sh" "CLASH_SUBSCRIPTION_URL"
assert_contains "scripts/install-mihomo.sh" "systemctl"
assert_contains "scripts/install-cliproxyapi.sh" "CLIPROXY_WORKDIR"
assert_contains "scripts/install-cliproxyapi.sh" "systemctl --user"
assert_contains "scripts/install-cliproxyapi.sh" "proxy-url"
assert_contains "templates/clash.service" "__MIHOMO_BINARY_PATH__"
assert_contains "templates/clash.service" "__MIHOMO_CONFIG_DIR__"
assert_contains "templates/clash.service" "__MIHOMO_CONFIG_PATH__"
assert_contains "templates/cliproxyapi.service" "__CLIPROXY_WORKDIR__"
assert_contains "templates/cliproxyapi.service" "__CLIPROXY_BINARY_PATH__"
assert_contains "templates/cliproxyapi.service" "__CLIPROXY_CONFIG_PATH__"
assert_contains "README.md" "MIHOMO_SERVICE_NAME"
assert_contains "README.md" "CLIPROXY_WORKDIR"
assert_contains "docs/troubleshooting.md" "CLIPROXY_WORKDIR"

# Keep examples/template safe: no real-looking secrets committed.
while IFS= read -r -d '' file; do
  assert_not_contains_regex "$file" '(sk-[A-Za-z0-9_-]{20,}|ghp_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{20,})'
  assert_not_contains_regex "$file" 'clash.*subscription.*https?://'
  assert_not_contains_regex "$file" 'api[_-]?key=[A-Za-z0-9_-]{16,}'
done < <(find . -type f \
  -not -path './.git/*' \
  -not -path './.env' \
  -not -path './tests/smoke-test.sh' \
  -print0)

# Profiles should not claim unfinished installers are enabled by default.
assert_contains "profiles/wsl.env" "INSTALL_MIHOMO=0"
assert_contains "profiles/wsl.env" "INSTALL_CLIPROXYAPI=0"
assert_contains "profiles/ubuntu-server.env" "INSTALL_MIHOMO=0"
assert_contains "profiles/ubuntu-server.env" "INSTALL_CLIPROXYAPI=0"
assert_contains "profiles/china-server.env" "INSTALL_MIHOMO=0"
assert_contains "profiles/china-server.env" "INSTALL_CLIPROXYAPI=0"

# Partial installers must report explicit skip status unless implemented.
assert_contains "scripts/common.sh" "[SKIP]"
assert_contains "scripts/install-mihomo.sh" "starting Mihomo installer"
assert_contains "scripts/install-cliproxyapi.sh" "starting CLIProxyAPI installer"
assert_contains "scripts/install-hermes.sh" "skip \""

# Dry-run should not mutate system and must complete.
bash install.sh --profile minimal --dry-run
bash install.sh --profile wsl --dry-run
bash install.sh --profile ubuntu-server --dry-run
bash install.sh --profile china-server --dry-run
mihomo_dry_run_output="$(INSTALL_MIHOMO=1 bash install.sh --profile wsl --dry-run 2>&1)"
printf '%s\n' "$mihomo_dry_run_output"
grep -Fq "starting Mihomo installer" <<< "$mihomo_dry_run_output" || fail "INSTALL_MIHOMO=1 override did not trigger Mihomo installer"
tmp_cliproxy_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_cliproxy_dir"' EXIT
cat > "$tmp_cliproxy_dir/config.yaml" <<'EOF'
proxy-url: "http://127.0.0.1:7890"
port: "8317"
EOF
cat > "$tmp_cliproxy_dir/cli-proxy-api" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$tmp_cliproxy_dir/cli-proxy-api"
cliproxy_dry_run_output="$(CLIPROXY_WORKDIR="$tmp_cliproxy_dir" CLIPROXY_CONFIG_PATH="$tmp_cliproxy_dir/config.yaml" CLIPROXY_BINARY_PATH="$tmp_cliproxy_dir/cli-proxy-api" INSTALL_CLIPROXYAPI=1 bash install.sh --profile wsl --dry-run 2>&1)"
printf '%s\n' "$cliproxy_dry_run_output"
grep -Fq "starting CLIProxyAPI installer" <<< "$cliproxy_dry_run_output" || fail "INSTALL_CLIPROXYAPI=1 override did not trigger CLIProxyAPI installer"
bash install.sh doctor --dry-run

ok "smoke test passed"
