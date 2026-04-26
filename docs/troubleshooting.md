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
