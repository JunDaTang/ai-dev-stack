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
- `wsl`: minimal plus Mihomo/CLIProxyAPI hooks for WSL.
- `ubuntu-server`: server-oriented hooks.
- `china-server`: server profile with mirror/offline flags reserved.

## Safety

- Secrets stay in `.env`, never in Git.
- Existing config files are backed up under `~/.ai-dev-stack/backups/` before edits.
- Scripts are intended to be idempotent: re-running should check existing tools first.

## CI template

A GitHub Actions workflow template is included at `templates/github/ci.yml.example`.
Copy it to `.github/workflows/ci.yml` after your GitHub token has the `workflow` scope.

## MVP status

The first version focuses on safe skeleton, PATH fixes, Claude Code/Codex/cc-switch installers, and doctor checks. Mihomo and CLIProxyAPI installers are conservative placeholders until service paths are made fully portable.
