# ai-dev-stack Optimization Plan

> For Hermes: Use subagent-driven-development skill to implement this plan task-by-task.

Goal: turn ai-dev-stack from a passing MVP into a genuinely reproducible Ubuntu/WSL bootstrap that matches its profile promises.

Architecture: keep the repo shell-first and portable, but make profile behavior honest and verifiable. Prioritize closing the gap between declared install flags and actual installer behavior, then strengthen doctor/test/docs so the repo becomes self-validating.

Tech Stack: Bash, GitHub Actions, systemd, curl, npm, WSL/Ubuntu shell tooling.

---

## Current findings

Confirmed from the current repo state:
- CI is working and passing on `main`.
- `minimal` dry-run and `doctor --dry-run` complete successfully.
- `scripts/install-mihomo.sh` is still an MVP placeholder.
- `scripts/install-cliproxyapi.sh` is still an MVP placeholder.
- `scripts/install-hermes.sh` is still environment-specific and does not install Hermes.
- `profiles/wsl.env` and `profiles/china-server.env` currently enable Mihomo and CLIProxyAPI despite those installers not being fully implemented.
- README still describes the repo as MVP and notes unfinished portability for Mihomo/CLIProxyAPI.

This means the highest-priority issue is product honesty: profile flags currently imply more automation than the scripts actually deliver.

---

## Phase 1: Make profile behavior truthful

### Task 1: Document the support matrix

Objective: make it explicit which features are fully implemented, partial, or placeholder.

Files:
- Modify: `README.md`
- Modify: `docs/troubleshooting.md`
- Create: `docs/support-matrix.md`

Step 1: Add a support matrix file listing each capability:
- shell PATH setup
- Claude Code install
- Codex install
- cc-switch install
- Hermes install
- Mihomo install
- CLIProxyAPI install
- doctor checks

Step 2: For each capability, mark one of:
- supported
- partial
- placeholder
- manual-only

Step 3: Link `README.md` to `docs/support-matrix.md`.

Step 4: Update troubleshooting docs so they distinguish between “expected auto-install” and “manual setup required”.

Step 5: Verify by reading the rendered markdown and ensuring no profile implies completed automation where it does not exist.

Step 6: Commit:
```bash
git add README.md docs/support-matrix.md docs/troubleshooting.md
git commit -m "docs: add support matrix for current installer coverage"
```

### Task 2: Stop profiles from over-promising

Objective: align `profiles/*.env` defaults with real installer support.

Files:
- Modify: `profiles/wsl.env`
- Modify: `profiles/china-server.env`
- Modify: `profiles/ubuntu-server.env`
- Modify: `README.md`

Step 1: Decide policy:
- either disable unfinished installer flags by default
- or keep them enabled but require install scripts to emit explicit `[SKIP] not implemented yet`

Recommended choice: disable unfinished installer flags by default until the installers are real.

Step 2: Update profile env files so only actually supported installers are enabled by default.

Step 3: In README, add a note that unfinished components must currently be installed manually.

Step 4: Verify with:
```bash
./install.sh --profile wsl --dry-run
./install.sh --profile china-server --dry-run
./install.sh --profile ubuntu-server --dry-run
```
Expected: output should not imply successful installation of unfinished components.

Step 5: Commit:
```bash
git add profiles/*.env README.md
git commit -m "fix: align profile defaults with implemented installers"
```

### Task 3: Make unfinished installers fail loudly or skip explicitly

Objective: remove silent ambiguity from partial installer scripts.

Files:
- Modify: `scripts/install-mihomo.sh`
- Modify: `scripts/install-cliproxyapi.sh`
- Modify: `scripts/install-hermes.sh`
- Modify: `scripts/common.sh`

Step 1: Add a helper in `scripts/common.sh` such as:
```bash
not_implemented() {
  warn "$1"
  return 0
}
```
Or, if you want stricter behavior:
```bash
not_implemented() {
  err "$1"
  exit 3
}
```

Step 2: Update each partial installer to emit one consistent message format, for example:
```bash
warn "[SKIP] CLIProxyAPI installer not implemented yet; configure manually"
```

Step 3: Ensure dry-run output and real-run output are both explicit.

Step 4: Verify by running:
```bash
bash scripts/install-mihomo.sh
bash scripts/install-cliproxyapi.sh
bash scripts/install-hermes.sh
```
Expected: clear status, no fake success.

Step 5: Commit:
```bash
git add scripts/common.sh scripts/install-mihomo.sh scripts/install-cliproxyapi.sh scripts/install-hermes.sh
git commit -m "fix: make partial installers report explicit skip status"
```

---

## Phase 2: Implement the highest-value missing automation

### Task 4: Implement WSL Mihomo installer

Objective: make `INSTALL_MIHOMO=1` on WSL actually install and verify Mihomo.

Files:
- Modify: `scripts/install-mihomo.sh`
- Modify: `examples/config.example.env`
- Modify: `docs/troubleshooting.md`
- Modify: `README.md`
- Optional: `templates/clash.service`

Implementation target:
- download Mihomo release artifact or install from a trusted source
- place binary in a Linux-local path
- set up config path
- optionally install/refresh a systemd service file
- preserve subscription URL in `.env`, never in git

Step 1: Write the desired behavior in comments and docs before coding.

Step 2: Add env variables for configurable paths, for example:
- `MIHOMO_CONFIG_DIR`
- `MIHOMO_BINARY_PATH`
- `MIHOMO_SERVICE_NAME`

Step 3: Implement idempotent checks:
- if binary exists, print version
- if config exists, do not overwrite without backup
- if service exists, reload/enable carefully

Step 4: Add a non-destructive dry-run path.

Step 5: Verify on WSL with:
```bash
./install.sh --profile wsl --dry-run
./install.sh doctor --dry-run
```
Then real verification on a safe machine:
```bash
systemctl status clash.service
mihomo -v
```

Step 6: Commit:
```bash
git add scripts/install-mihomo.sh examples/config.example.env README.md docs/troubleshooting.md templates/clash.service
git commit -m "feat: implement WSL Mihomo installer"
```

### Task 5: Implement CLIProxyAPI installer

Objective: make `INSTALL_CLIPROXYAPI=1` actually provision CLIProxyAPI or clearly configure an existing install.

Files:
- Modify: `scripts/install-cliproxyapi.sh`
- Modify: `examples/config.example.env`
- Modify: `docs/troubleshooting.md`
- Modify: `README.md`
- Optional: `templates/cliproxyapi.service`

Implementation target:
- support existing local clone/path-based deployment
- configure base URL and service wiring
- avoid committing secrets
- verify endpoint reachability

Step 1: Decide supported install mode:
- clone/build the repo automatically
- or configure/manage a pre-existing checkout path

Recommended first implementation: configure/manage a pre-existing checkout path passed via env.

Step 2: Add env variables such as:
- `CLIPROXY_WORKDIR`
- `CLIPROXY_SERVICE_NAME`
- `CLIPROXY_PROXY_URL`
- `CLIPROXY_PORT`

Step 3: Implement backup + templating logic for service/config generation.

Step 4: Add idempotent verification:
```bash
curl -fsS http://127.0.0.1:8317
```
Or an endpoint-specific health check if available.

Step 5: Verify both dry-run and real-run behavior.

Step 6: Commit:
```bash
git add scripts/install-cliproxyapi.sh examples/config.example.env README.md docs/troubleshooting.md templates/cliproxyapi.service
git commit -m "feat: implement CLIProxyAPI installer"
```

### Task 6: Decide Hermes installer scope

Objective: either implement Hermes installation or clearly redefine the feature as PATH support only.

Files:
- Modify: `scripts/install-hermes.sh`
- Modify: `README.md`
- Modify: `docs/support-matrix.md`

Decision point:
- If Hermes install is intentionally out of scope, rename expectations to “Hermes PATH integration”.
- If in scope, implement installation steps and verification.

Recommended near-term choice: keep it out of scope and rename it honestly.

Step 1: Rename wording from “install Hermes” to “expose existing Hermes install on PATH” wherever applicable.

Step 2: Ensure `INSTALL_HERMES` semantics are documented precisely.

Step 3: Verify docs and script output are consistent.

Step 4: Commit:
```bash
git add scripts/install-hermes.sh README.md docs/support-matrix.md
git commit -m "docs: clarify Hermes integration scope"
```

---

## Phase 3: Strengthen doctor and test coverage

### Task 7: Upgrade doctor into a real acceptance check

Objective: make `./install.sh doctor` validate practical usability, not just command presence.

Files:
- Modify: `scripts/healthcheck.sh`
- Modify: `README.md`
- Modify: `docs/troubleshooting.md`

Step 1: Add checks for command provenance on WSL:
- verify `claude` path is Linux-local
- verify `codex` path is Linux-local
- verify `cc-switch` path is Linux-local

Step 2: Add optional service checks when installed:
- `systemctl is-active clash.service`
- `systemctl is-active cliproxyapi.service`

Step 3: Add proxy/network checks where relevant:
- local port reachability
- configured git proxy
- configured CLIProxy proxy URL

Step 4: Add env sanity checks:
- warn if placeholder values like `[REDACTED]` or `***` are still present in active `.env`

Step 5: Verify both dry-run and real-run.

Step 6: Commit:
```bash
git add scripts/healthcheck.sh README.md docs/troubleshooting.md
git commit -m "feat: strengthen doctor checks for WSL and proxy tooling"
```

### Task 8: Expand smoke tests around profile behavior

Objective: make regressions around profile semantics visible in CI.

Files:
- Modify: `tests/smoke-test.sh`
- Modify: `.github/workflows/ci.yml`

Step 1: Add assertions that profile files do not enable unsupported capabilities silently.

Step 2: Add checks that placeholder installers emit explicit skip or warning messages.

Step 3: Add matrix-like script coverage for:
- `./install.sh --profile minimal --dry-run`
- `./install.sh --profile wsl --dry-run`
- `./install.sh --profile ubuntu-server --dry-run`
- `./install.sh --profile china-server --dry-run`

Step 4: Keep runtime fast enough for CI.

Step 5: Verify locally:
```bash
tests/shellcheck.sh
tests/smoke-test.sh
```

Step 6: Commit:
```bash
git add tests/smoke-test.sh .github/workflows/ci.yml
git commit -m "test: expand smoke coverage for profile behavior"
```

---

## Phase 4: Improve portability and operator experience

### Task 9: Add explicit env schema documentation

Objective: make required and optional env vars discoverable.

Files:
- Create: `docs/env-schema.md`
- Modify: `examples/config.example.env`
- Modify: `examples/wsl.example.env`
- Modify: `README.md`

Step 1: Document each env var with:
- purpose
- example value
- whether required
- which profile uses it
- whether it contains secrets

Step 2: Ensure example env files match the docs exactly.

Step 3: Verify there are no undocumented variables referenced by scripts.

Step 4: Commit:
```bash
git add docs/env-schema.md examples/config.example.env examples/wsl.example.env README.md
git commit -m "docs: add environment variable schema"
```

### Task 10: Make server profiles concrete

Objective: either implement or narrow the scope of `ubuntu-server` and `china-server`.

Files:
- Modify: `profiles/ubuntu-server.env`
- Modify: `profiles/china-server.env`
- Modify: `README.md`
- Optional: create `docs/server-profiles.md`

Step 1: Define exactly what is different between these two profiles.

Step 2: If mirror/offline features are not implemented, say so plainly and avoid implying they work.

Step 3: If implementing them, add exact behavior such as:
- alternate GitHub download URLs
- npm registry mirror settings
- offline bundle support

Step 4: Verify dry-run output is profile-specific and understandable.

Step 5: Commit:
```bash
git add profiles/ubuntu-server.env profiles/china-server.env README.md docs/server-profiles.md
 git commit -m "docs: clarify server profile behavior"
```

---

## Recommended execution order

If you want the fastest path to a trustworthy repo, do tasks in this order:
1. Task 2 — align profile defaults
2. Task 3 — explicit skip behavior for partial installers
3. Task 7 — strengthen doctor
4. Task 8 — expand smoke tests
5. Task 4 — implement Mihomo installer
6. Task 5 — implement CLIProxyAPI installer
7. Task 1 / 9 / 10 — finish docs and profile clarity
8. Task 6 — finalize Hermes scope

---

## Acceptance criteria for “v1 trustworthy bootstrap”

The repo should count as truly upgraded when all of the following are true:
- Every enabled profile flag corresponds to a real, tested behavior.
- Every unfinished feature is marked clearly in both docs and runtime output.
- `./install.sh --profile <name> --dry-run` is predictable for every profile.
- `./install.sh doctor` can explain the most common real-world WSL failures.
- CI verifies not just syntax but also profile semantics.
- WSL setup for Claude Code, Codex, cc-switch, Mihomo, and CLIProxyAPI is reproducible from docs.

---

## Suggested immediate next action

Start with Task 2 and Task 3 in one short branch. They are low-risk, improve truthfulness immediately, and reduce user confusion even before the full Mihomo/CLIProxyAPI automation lands.
