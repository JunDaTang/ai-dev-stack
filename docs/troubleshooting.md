# Troubleshooting

## WSL calls Windows npm shims

Symptom: `codex` or `claude` path starts with `/mnt/c/Users/.../AppData/Roaming/npm`.

Fix:

```sh
./scripts/configure-shell.sh
source ~/.bashrc
hash -r
which codex
which claude
```

Expected paths should prefer `~/.hermes/node/bin` or another Linux-local directory.

## CLIProxyAPI unreachable

Run:

```sh
./install.sh doctor
curl -v http://127.0.0.1:8317
```

Check service status and `.env` `CLIPROXY_BASE_URL`.

Note: ai-dev-stack does not auto-install CLIProxyAPI yet. Current support is manual deployment plus doctor/path checks.

## Doctor warns about Windows shim paths

If `doctor` says `claude`, `codex`, or `cc-switch` uses a Windows shim path like `/mnt/c/...`, re-run:

```sh
./scripts/configure-shell.sh
source ~/.bashrc
hash -r
./install.sh doctor
```

Expected result: Linux-local paths such as `~/.hermes/node/bin` or `~/.local/bin`.

## Doctor warns about placeholder env values

If `doctor` reports `[REDACTED]` or `***` values, copy and edit local config:

```sh
cp examples/config.example.env .env
$EDITOR .env
./install.sh doctor
```

Update at least:
- `CLASH_SUBSCRIPTION_URL`
- `CLIPROXY_API_KEY` (if you use CLIProxyAPI)
