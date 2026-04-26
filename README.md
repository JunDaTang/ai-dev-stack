# ai-dev-stack

AI Coding Workstation bootstrap for Ubuntu/WSL.

Goal: turn a clean Ubuntu or WSL machine into a reproducible AI coding environment with Claude Code, Codex, cc-switch, optional Mihomo proxy, optional CLIProxyAPI, and safe shell PATH handling.

## Quick start

```sh
git clone https://github.com/JedTang/ai-dev-stack.git
cd ai-dev-stack
cp examples/config.example.env .env
# edit .env; keep secrets local
./install.sh --profile wsl
./install.sh doctor
```

Dry-run first:

```sh
./install.sh --profile minimal --dry-run
./install.sh doctor --dry-run
```

## Profiles

- `minimal`: shell PATH, Claude Code, Codex, cc-switch.
- `wsl`: minimal plus optional Mihomo installer support when you set `INSTALL_MIHOMO=1` and provide a real `CLASH_SUBSCRIPTION_URL`; CLIProxyAPI can also be wired up from an existing local checkout when you set `INSTALL_CLIPROXYAPI=1`.
- `ubuntu-server`: server-oriented shell and CLI bootstrap; Mihomo/CLIProxyAPI remain opt-in and expect an existing local CLIProxyAPI checkout.
- `china-server`: server-oriented bootstrap with `USE_GITHUB_MIRROR=1`; Mihomo installer can reuse the same env knobs, and CLIProxyAPI can reuse the same local-checkout installer path.

## Safety

- Secrets stay in `.env`, never in Git.
- Existing config files are backed up under `~/.ai-dev-stack/backups/` before edits.
- Scripts are intended to be idempotent: re-running should check existing tools first.

## CI

The GitHub Actions workflow is tracked at `.github/workflows/ci.yml`.
The same content is also available as a reusable template at `templates/github/ci.yml.example`.

## Mihomo installer knobs

When you want ai-dev-stack to provision Mihomo, set these in local `.env` and then enable `INSTALL_MIHOMO=1`:

- `CLASH_SUBSCRIPTION_URL`: your real Mihomo/Clash subscription URL.
- `MIHOMO_VERSION`: release tag to install, default `v1.19.24`.
- `MIHOMO_BINARY_PATH`: install target, default `/usr/local/bin/mihomo`.
- `MIHOMO_CONFIG_DIR`: runtime directory, default `$HOME/clashd`.
- `MIHOMO_CONFIG_PATH`: config file path, default `$HOME/clashd/config.yaml`.
- `MIHOMO_SERVICE_NAME`: systemd unit name, default `clash.service`.
- `USE_GITHUB_MIRROR=1`: optional mirror mode for GitHub downloads.

Dry-run preview:

```sh
INSTALL_MIHOMO=1 ./install.sh --profile wsl --dry-run
```

Real run on a safe machine:

```sh
INSTALL_MIHOMO=1 ./install.sh --profile wsl
systemctl status clash.service
mihomo -v
```

## CLIProxyAPI installer knobs

When you want ai-dev-stack to wire up an existing CLIProxyAPI checkout, set these in local `.env` and then enable `INSTALL_CLIPROXYAPI=1`:

- `CLIPROXY_WORKDIR`: existing local checkout path, default `$HOME/cliproxyapi`.
- `CLIPROXY_CONFIG_PATH`: config file to update, default `$HOME/cliproxyapi/config.yaml`.
- `CLIPROXY_SERVICE_NAME`: user systemd unit name, default `cliproxyapi.service`.
- `CLIPROXY_PROXY_URL`: proxy URL to write into config, default `http://127.0.0.1:7890`.
- `CLIPROXY_PORT`: port to write into config, default `8317`.
- `CLIPROXY_BASE_URL`: reachability check target, default `http://127.0.0.1:8317`.

Dry-run preview:

```sh
INSTALL_CLIPROXYAPI=1 ./install.sh --profile wsl --dry-run
```

Real run on a safe machine:

```sh
INSTALL_CLIPROXYAPI=1 ./install.sh --profile wsl
systemctl --user status cliproxyapi.service
curl -v http://127.0.0.1:8317
```

## MVP status

The repo now automates shell PATH fixes, Claude Code/Codex/cc-switch install, doctor checks, a configurable Mihomo installer path, and CLIProxyAPI wiring for an existing local checkout. Hermes installation remains manual/setup-oriented until a portable installer is implemented.
