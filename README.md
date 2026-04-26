# ai-dev-stack

English | [简体中文](README.zh-CN.md)

Bootstrap a reproducible AI coding workstation for Ubuntu and WSL.

AI Coding Workstation bootstrap for Ubuntu/WSL.

ai-dev-stack helps turn a clean machine into a practical development environment with:
- safe shell PATH setup
- Claude Code
- Codex
- cc-switch
- optional Mihomo provisioning
- optional CLIProxyAPI wiring from an existing local checkout
- doctor checks for common setup mistakes

## What this repo does

Current automated coverage:
- shell PATH setup for local CLI tools
- Claude Code install/check
- Codex install/check
- cc-switch install/check
- Mihomo installer with configurable binary/config/service paths
- CLIProxyAPI installer path for an existing local checkout
- doctor/healthcheck commands
- dry-run support for installation preview
- backup of files before mutation

Still not fully automated:
- Hermes portable installer

## Quick start

```sh
git clone https://github.com/JunDaTang/ai-dev-stack.git
cd ai-dev-stack
cp examples/config.example.env .env
# edit .env and keep secrets local
./install.sh --profile wsl --dry-run
./install.sh --profile wsl
./install.sh doctor
```

## Core commands

Preview changes without mutating the machine:

```sh
./install.sh --profile minimal --dry-run
./install.sh doctor --dry-run
```

WSL-oriented setup:

```sh
./install.sh --profile wsl
./install.sh doctor
```

Server-oriented setup:

```sh
./install.sh --profile ubuntu-server
./install.sh doctor
```

## Profiles

- `minimal`
  - shell PATH
  - Claude Code
  - Codex
  - cc-switch

- `wsl`
  - everything in `minimal`
  - optional Mihomo when `INSTALL_MIHOMO=1`
  - optional CLIProxyAPI wiring when `INSTALL_CLIPROXYAPI=1`

- `ubuntu-server`
  - server-oriented shell and CLI bootstrap
  - Mihomo remains opt-in
  - CLIProxyAPI remains opt-in and expects an existing local checkout

- `china-server`
  - server-oriented bootstrap with `USE_GITHUB_MIRROR=1`
  - Mihomo can reuse the same installer knobs
  - CLIProxyAPI can reuse the same local-checkout installer path

## Local configuration

Copy and edit:

```sh
cp examples/config.example.env .env
```

Important rules:
- keep secrets only in `.env`
- do not commit `.env`
- use `[REDACTED]`-style placeholders in docs/examples only

Useful example files:
- `examples/config.example.env`
- `examples/wsl.example.env`
- `profiles/minimal.env`
- `profiles/wsl.env`
- `profiles/ubuntu-server.env`
- `profiles/china-server.env`

## Mihomo installer knobs

To let ai-dev-stack provision Mihomo, set these in local `.env` and enable `INSTALL_MIHOMO=1`:

- `CLASH_SUBSCRIPTION_URL`: real Mihomo/Clash subscription URL
- `MIHOMO_VERSION`: release tag, default `v1.19.24`
- `MIHOMO_BINARY_PATH`: install target, default `/usr/local/bin/mihomo`
- `MIHOMO_CONFIG_DIR`: runtime directory, default `$HOME/clashd`
- `MIHOMO_CONFIG_PATH`: config file path, default `$HOME/clashd/config.yaml`
- `MIHOMO_SERVICE_NAME`: systemd unit name, default `clash.service`
- `USE_GITHUB_MIRROR=1`: optional GitHub mirror mode

Preview:

```sh
INSTALL_MIHOMO=1 ./install.sh --profile wsl --dry-run
```

Apply:

```sh
INSTALL_MIHOMO=1 ./install.sh --profile wsl
systemctl status clash.service
mihomo -v
```

## CLIProxyAPI installer knobs

To let ai-dev-stack wire up an existing CLIProxyAPI checkout, set these in local `.env` and enable `INSTALL_CLIPROXYAPI=1`:

- `CLIPROXY_WORKDIR`: checkout path, default `$HOME/cliproxyapi`
- `CLIPROXY_CONFIG_PATH`: config path, default `$HOME/cliproxyapi/config.yaml`
- `CLIPROXY_BINARY_PATH`: binary path, default `$HOME/cliproxyapi/cli-proxy-api`
- `CLIPROXY_SERVICE_NAME`: user systemd unit name, default `cliproxyapi.service`
- `CLIPROXY_PROXY_URL`: value written into config, default `http://127.0.0.1:7890`
- `CLIPROXY_PORT`: value written into config, default `8317`
- `CLIPROXY_BASE_URL`: reachability check target, default `http://127.0.0.1:8317`

Preview:

```sh
INSTALL_CLIPROXYAPI=1 ./install.sh --profile wsl --dry-run
```

Apply:

```sh
INSTALL_CLIPROXYAPI=1 ./install.sh --profile wsl
systemctl --user status cliproxyapi.service
curl -v http://127.0.0.1:8317
```

## Safety

- secrets stay in `.env`, never in Git
- existing files are backed up under `~/.ai-dev-stack/backups/`
- installers are intended to be idempotent
- use `--dry-run` before real changes on a new machine

## Validation

Local checks:

```sh
bash tests/smoke-test.sh
bash tests/shellcheck.sh
./install.sh doctor --dry-run
```

## CI

Tracked GitHub Actions workflow:
- `.github/workflows/ci.yml`

Reusable template copy:
- `templates/github/ci.yml.example`

## Troubleshooting

See:
- `docs/troubleshooting.md`
- `docs/secrets.md`

## Current status

Implemented now:
- shell PATH fixes
- Claude Code / Codex / cc-switch install paths
- doctor checks
- configurable Mihomo installer
- CLIProxyAPI wiring for an existing local checkout

Not implemented yet:
- portable Hermes installer
