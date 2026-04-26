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
- `wsl`: minimal plus placeholders for future Mihomo/CLIProxyAPI automation; those components currently require manual setup.
- `ubuntu-server`: server-oriented shell and CLI bootstrap; Mihomo/CLIProxyAPI remain manual for now.
- `china-server`: server-oriented bootstrap with `USE_GITHUB_MIRROR=1`; Mihomo/CLIProxyAPI remain manual for now.

## Safety

- Secrets stay in `.env`, never in Git.
- Existing config files are backed up under `~/.ai-dev-stack/backups/` before edits.
- Scripts are intended to be idempotent: re-running should check existing tools first.

## CI

The GitHub Actions workflow is tracked at `.github/workflows/ci.yml`.
The same content is also available as a reusable template at `templates/github/ci.yml.example`.

## MVP status

The first version focuses on safe skeleton, PATH fixes, Claude Code/Codex/cc-switch installers, and doctor checks. Mihomo, CLIProxyAPI, and Hermes installation are not automated yet; the repo now treats them as manual setup until portable installers are implemented.
