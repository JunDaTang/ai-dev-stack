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

## Mihomo installer fails or stays manual

Run a non-destructive preview first:

```sh
INSTALL_MIHOMO=1 ./install.sh --profile wsl --dry-run
```

Common causes:
- `CLASH_SUBSCRIPTION_URL` is still `[REDACTED]` in `.env`.
- `sudo` or `systemctl` is unavailable, so the service file cannot be installed/enabled.
- `MIHOMO_BINARY_PATH` points to a non-Linux-local or unwritable path.
- `USE_GITHUB_MIRROR=1` is needed for GitHub downloads from restricted networks.

Real verification after install:

```sh
systemctl status clash.service
mihomo -v
curl -v --connect-timeout 5 -x http://127.0.0.1:7890 https://www.google.com
```

If you already have a working config, keep `MIHOMO_CONFIG_PATH` pointed at it and the installer will reuse or back it up instead of silently pretending success.

## CLIProxyAPI installer fails or service does not start

Run a non-destructive preview first:

```sh
INSTALL_CLIPROXYAPI=1 ./install.sh --profile wsl --dry-run
```

Common causes:
- `CLIPROXY_WORKDIR` does not point to an existing local checkout.
- `CLIPROXY_CONFIG_PATH` is missing.
- `CLIPROXY_WORKDIR/cli-proxy-api` is not executable.
- `systemctl --user` is unavailable or the user service manager is not running.
- `CLIPROXY_PROXY_URL` or `CLIPROXY_PORT` is inconsistent with the intended deployment.

Real verification after install:

```sh
systemctl --user status cliproxyapi.service
curl -v http://127.0.0.1:8317
```

The installer updates `proxy-url` and `port`, installs a user service unit, and then checks `CLIPROXY_BASE_URL`.

## CLIProxyAPI unreachable

Run:

```sh
./install.sh doctor
curl -v http://127.0.0.1:8317
```

Check service status and `.env` `CLIPROXY_BASE_URL`.

If you use the installer path, also verify `CLIPROXY_WORKDIR`, `CLIPROXY_CONFIG_PATH`, and `CLIPROXY_PROXY_URL`.

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
