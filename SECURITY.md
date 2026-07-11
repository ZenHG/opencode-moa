# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly:

- **Do not** open a public Issue for security bugs.
- Email the maintainers or use [GitHub Security Advisories](https://github.com/ZenHG/opencode-moa/security/advisories/new) to report privately.

## API Key Safety

This configuration package uses OpenCode Go API keys. Please observe:

- **Never** commit real API keys to git — the key file `.opencode/local/opencode-go.key` is git-ignored by design.
- **Never** paste real keys in Issues, PRs, or Discussions.
- Use the `{file:}` provider option to reference the key file externally; do not inline the key in `opencode.json`.
- If you accidentally exposed a key, rotate it immediately at [opencode.ai/auth](https://opencode.ai/auth).

## Model Provider Keys

If you switch from the default Go plan to your own provider (Anthropic, OpenAI, etc.), the same rules apply:

- Store keys in git-ignored local files, never in tracked config.
- Use `{file:}` references in `opencode.json`.

## Scope

This project is a **configuration package**, not runtime code. Its attack surface is limited to:

- The `opencode.json` provider configuration (key file path reference).
- The agent `.md` frontmatter (model IDs, no secrets).

There is no executable code shipped; all logic lives in OpenCode itself.
