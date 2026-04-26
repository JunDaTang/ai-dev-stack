# Secrets

Do not commit real API keys, auth tokens, Clash subscription URLs, or cc-switch databases.

Use `.env` for local values. This repository only contains examples with `[REDACTED]` placeholders.

Recommended flow:

1. `cp examples/config.example.env .env`
2. Edit `.env` locally.
3. Run `./install.sh --profile wsl`.

Before publishing, run `tests/smoke-test.sh` to catch common secret patterns.
