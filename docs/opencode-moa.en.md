---
name: opencode-moa
description: 22-agent Cost-Optimal MoA configuration. Cost-efficient models act as tool agents, mid-tier models give opinions, flagship models fuse. One-shot deploy, can be deleted afterward.
---

# OpenCode MoA Deployment Manual

---

## Prerequisites

### Required

| Requirement         | Check command          | Notes                                                                                                                                                                                                  |
| ------------------- | ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| OpenCode installed  | `opencode --version`   | **>= 1.3.4** (agent-level `reasoningEffort`/`hidden`/`task` support; `@ai-sdk/openai-compatible` transparently passes through reasoning parameters, **no** `forceReasoning` needed; only `@ai-sdk/openai` has a passthrough regression at >=1.3.4), [install](https://opencode.ai/install) |
| OpenCode Go plan    | opencode.ai console    | [Subscribe](https://opencode.ai/auth), first month $5, then $10/month                                                                                                                                 |
| Git installed       | `git --version`        | Used to clone the repo                                                                                                                                                                                 |
| OpenCode Go API Key | created in opencode.ai console | Created in the Zen console (opencode.ai)                                                                                                                                                          |

### Optional (needed by install scripts)

| Requirement       | Check command     | Notes                                                         |
| ----------------- | ----------------- | ------------------------------------------------------------ |
| PowerShell Core   | `pwsh --version`  | needed by install.ps1, bundled with Windows or `brew install powershell` |
| jq                | `jq --version`    | needed by install.sh for JSON merge, `apt install jq` / `brew install jq` |

> No pwsh/jq is fine — you can use Method 1 (AI auto-deploy) or Method 3 (manual merge).

### Provider configuration (required)

All 22 agents use **`opencode-go/<model-id>`** (the official Go model ID format). Sub-agents resolve this prefix through the provider registry. **You must have an `opencode-go` provider with credentials** (otherwise the built-in `opencode` provider has no key and silently downgrades to `public`, Go paid models get disabled → `OpenCode Go provider error` / `Upstream request failed`).

Two authentication methods, choose one:

> **AI deployment instruction (choose one required)**
>
> **Method A (recommended, AI writes directly):**
>
> 1. Ask the user: "Please enter your OpenCode Go API Key (created at opencode.ai/auth)."
> 2. Ensure the directory exists and write the **real key only** into `.opencode/local/opencode-go.key` (one line, no trailing newline/spaces; this file is git-ignored and never committed):
>    ```bash
>    mkdir -p .opencode/local
>    printf '%s' "<THE_USER_KEY>" > .opencode/local/opencode-go.key
>    ```
> 3. Add the provider config block below to the project `opencode.json`, with `apiKey` set to `{file:.opencode/local/opencode-go.key}` (it **references** the key file — do **not** paste the raw key into `apiKey`).
> 4. Confirm completion and tell the user to restart OpenCode.
>
> **Method B (placeholder, no key over chat):**
>
> 1. Add the provider config block below to the project `opencode.json`, with the `apiKey` field set to `<YOUR_GO_API_KEY>` (placeholder).
> 2. Tell the user: open `opencode.json`, replace `<YOUR_GO_API_KEY>` with your real key created at opencode.ai/auth, save and restart OpenCode.
> 3. The key never goes through chat; the user does it locally.
>
> **This step cannot be skipped.** Otherwise all 22 agents fail silently.

---

**Method A (recommended, project-level by default): write the key directly in the config**

**Written to the project `opencode.json` by default** — a self-contained deployment: provider + key both live inside the project, so even if the system-level directory is deleted/empty it has no effect. **You must create `.opencode/local/opencode-go.key` containing the real key first** (see Method A above); `apiKey` then references that file via `{file:}` (`.opencode/local/opencode-go.key`, excluded by `.gitignore`, not committed). Only switch to the system-level config (outside the repo; real paths per platform below under "System-level paths") when you want to **share one key across multiple projects**.

> ⚠️ **`forceReasoning` is only needed for `@ai-sdk/openai` — this project defaults to `@ai-sdk/openai-compatible`, do not add it**: the reasoning passthrough regression in opencode >= 1.3.4 ([issue #20815](https://github.com/anomalyco/opencode/issues/20815)) **only affects custom providers with `"npm": "@ai-sdk/openai"`** (AI SDK v6 validates against a "known reasoning model list", and silently drops `reasoningEffort` if not in it). This issue is confirmed to **not affect `@ai-sdk/openai-compatible`** — `reasoningEffort` passes through correctly as `reasoning_effort`. This project's provider uses `openai-compatible`, so **no `forceReasoning` is needed or should be added** (adding it is a no-op and misleads later readers into thinking it's required). Only when you change `npm` to `@ai-sdk/openai` (e.g. to use the responses API) must you add `forceReasoning: true` in `options` (only needed at >=1.3.4; lower versions ignore the field).

**System-level paths (recognized on all platforms, but the spelling differs):**

| Platform        | Real path                                          | Equivalent `~` spelling                              |
| --------------- | -------------------------------------------------- | ---------------------------------------------------- |
| Linux / macOS   | `~/.config/opencode/opencode.json`                 | same as left                                         |
| Windows         | `C:\Users\<you>\.config\opencode\opencode.json`    | `%USERPROFILE%\.config\opencode\opencode.json`       |

> 🔴 **Debunking:** many third-party docs write the Windows path as `%APPDATA%\opencode\` (e.g. some MCP plugin READMEs). **That is wrong** — OpenCode on Windows uses `%USERPROFILE%\.config\opencode`, not `%APPDATA%\opencode`. Putting the config at the wrong path leads to "deployment succeeds but all agents can't connect" with no obvious error.

> 🔴 **Same-directory dual-file warning**: OpenCode officially supports **both `.json` and `.jsonc`** formats, but **leaving both `opencode.json` and `opencode.jsonc` in the same directory has undefined priority** — the official config docs only say "both formats supported" and list the global path as `opencode.json`, without specifying which wins in a same-directory dual-file situation. The two files may also conflict (e.g. one enables a provider, the other disables it). **Safe practice: keep only one file per directory**, and make the kept one contain a valid `opencode-go` provider + real key; don't rely on "both present" as a fallback.

> 🔴 **`apiKey` cannot be a placeholder / empty**: writing `<YOUR_GO_API_KEY>`, an empty string, or omitting it makes deployment look complete but at runtime all 22 agents return 401/403 `Upstream request failed`. Both this project's hard gate and T0 will block this.

```jsonc
{
  "provider": {
    "opencode-go": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "OpenCode Go (MoA)",
      "options": {
        "baseURL": "https://opencode.ai/zen/go/v1",
        "apiKey": "{file:.opencode/local/opencode-go.key}"
      },
      "models": {
        "deepseek-v4-flash": { "name": "deepseek-v4-flash" },
        "mimo-v2.5":        { "name": "mimo-v2.5" },
        "mimo-v2.5-pro":    { "name": "mimo-v2.5-pro" },
        "minimax-m3":       { "name": "minimax-m3" },
        "glm-5.2":          { "name": "glm-5.2" },
        "qwen3.7-max":      { "name": "qwen3.7-max" },
        "qwen3.7-plus":     { "name": "qwen3.7-plus" },
        "kimi-k2.7-code":   { "name": "kimi-k2.7-code" },
        "deepseek-v4-pro":  { "name": "deepseek-v4-pro" }
      }
    }
  }
}
```

- No TUI interaction needed — works on desktop / headless / CI / WSL alike.
- `opencode-go` does not conflict with the built-in Zen provider (`opencode`); Zen and built-in agents like @explore are unaffected.
- All 9 models are verified to return 200 OK on the `zen/go/v1` endpoint.
- **You must restart OpenCode after changing the provider** for it to re-read `apiKey` (and any provider option change) — hot edits don't take effect.

---

**Method B (alternative): `/connect` inside TUI**

 Terminal GUI users only. In the TUI type `/connect` (or press Ctrl+P to open the command palette) → type `/connect` → select OpenCode Go → log in to opencode.ai → paste API key. The key is stored in `~/.local/share/opencode/auth.json`, same effect as above.

> `/connect` is a TUI command, unavailable on desktop / headless. Method A (config file) and Method B (auth) can coexist, with Method A taking precedence.

---

**Verification:**

- After restarting OpenCode → `/models` shows `opencode-go/deepseek-v4-flash` etc. (not marked `Free`).
- `@tool-handler` responds normally.
- `pwsh .opencode/tests/T0-static-verify.ps1` → all PASS (with system-level key, WARN also counts as pass, FAIL=0).

> ⚠️ The file containing the real key (`.opencode/local/opencode-go.key`) is not tracked by git (`*.key` and `.opencode/local/` are excluded by `.gitignore`). The system-level `~/.config/opencode/` is outside the repo.

---

### Error fallback

If neither `/connect` nor the config file set up the `opencode-go` provider, tool-layer calls will report `Upstream request failed`:

```
tool-handler (opencode-go/deepseek-v4-flash) failed
  → auto retry once
  → still fails → ask user:
    A. configure provider then retry
    B. skip tool layer, give solution directly (higher cost, no code material)
    C. switch to free model (/models, pick a Free model)
```

This fallback chain is already implemented in the concierge-router's prompt. Execution continues only after the user chooses — it never silently routes past the ask.

---

By default opencode uses a single model from start to finish. Changing one character and designing a system architecture use the same prompt, same temperature, same context. No division of labor.

This package deploys a **22-agent Cost-Optimal MoA** architecture (1 concierge-router + 21 specialized subagents, of which 18 are hidden). The core design principle is just one line:

> **Use flash and MiMo for grunt work, mid-tier for opinions, flagship for fusion.** Each model only does what it does best; never waste a single call.

### Cost tiers

```
Monthly quota comparison (OpenCode Go plan $10/month):
  DeepSeek V4 Flash   158,000 calls → tool layer (use freely)
  MiMo-V2.5           150,400 calls → tool layer (use freely)
  ─── above are the tool agents, ~80% of call volume (design target, not measured) ───
  MiniMax M3           16,000 calls
  DeepSeek V4 Pro      17,150 calls
  Qwen3.7 Plus         21,600 calls
  ─── above are mid-tier opinion models, ~18% (design target, not measured) ───
  Kimi K2.7 Code        9,250 calls
  Qwen3.7 Max           4,770 calls
  GLM-5.2               4,300 calls
  ─── above are flagship fusion models, ~2% (design target, not measured) ───
```

### How to use

**Method 1: just state the need (recommended)**

> Help me write a Markdown-to-HTML function

The concierge-router automatically: judges complexity → dispatches the tool agent to gather context → 3 mid-tier opinions in parallel → flagship fusion → flash implementation → pro QA. No agent switching, no model selection needed.

**Method 2: command-specified flow**

| Command            | Scenario                          | Who does the work                |
| ------------------ | --------------------------------- | -------------------------------- |
| `/moa-quick`       | config change, translation, simple query | @swift                       |
| `/moa-medium`      | function module, bug fix, single-file refactor | eng + creative + coder → fuse   |
| `/moa-flagship`    | system architecture, large refactor | 3 flagship opinions → fuse → implement → QA |
| `/moa-frontend`    | UI restore, CSS, screenshot fix   | restore + logic + motion → lead      |
| `/moa-describe`    | screenshot/image to text          | vision-translator                        |

**Method 3: `@` invoke (usable independently)**

Type `@` and pick an agent to talk directly. Each agent can be used independently:

- `@tool-handler` / `@vision-translator` → read files / screenshots directly
- `@mid-eng` → asks whether to gather material first; if you say "yes" it auto-calls the tool agent
- `@mid-fuse` → you give it the three solutions directly, it fuses and outputs (if you don't have three, it prompts you to use the concierge-router)

### Fallback chain

```
tool-handler (Flash) failed → immediate retry once
  → retry succeeds → return normally
  → retry fails → tool-handler-mimo (MiMo) failed → immediate retry once
    → retry succeeds → return normally
    → retry fails → ask user:
      A. wait a few minutes and retry
      B. skip tool layer, call opinion layer directly (higher cost)
      C. switch to free model
```

> Most provider errors (502/503/timeout) are transient; a quick retry usually succeeds.

---

## AI Execution

### Execution rules

- **Read before write**: before writing a file, check existing files at the target path to avoid overwriting.
- **Self-check each block**: after completing each Block, self-check that the file exists and content is complete before moving on.
- **Fallback**: if a model's provider is not configured in `opencode.json`, change that agent's `model` field to `default`.

---

### Block 0: Environment check

> ⚠️ **Pre-check**: before starting deployment, confirm you have completed the key setup in the **"Provider configuration"** section above (the system-level `~/.config/opencode/opencode.json` has registered `provider.opencode-go` with a valid key). OpenCode only loads the project-level `opencode.json` and the system-level `~/.config/opencode/opencode.json`, **not `user_config.json`**. If you haven't configured it, go back and do it first, otherwise the 22 agents will all fail to connect after deployment.

```bash
# detect run mode
if [ -n "$OPENCODE_CLIENT" ]; then
    echo "run mode: $([ "$OPENCODE_CLIENT" = "desktop" ] && echo "desktop" || echo "CLI")"
else
    if command -v opencode >/dev/null 2>&1; then
        echo "run mode: CLI"
        opencode --version || true
    else
        # desktop sub-shell / sandbox often reports not found due to different PATH even when installed — only warn, don't block file deployment, and never skip provider setup because of it
        echo "⚠️ opencode not found in current shell (PATH may differ); files can still be deployed; verify in a shell that has opencode or after restarting the desktop app"
    fi
fi
```

> 🔴 **Provider hard gate (must check after deploy)**: after file deployment, you must assert that **either the project `opencode.json` or the system-level `~/.config/opencode/opencode.json` (one per directory, keep only one)** contains `provider.opencode-go` and `apiKey` is a **real key** (neither the `<YOUR_GO_API_KEY>` placeholder, nor empty/missing). If not satisfied, the AI **must re-run the Provider step above to rebuild the provider** and must not announce "deployment successful" — otherwise it produces an empty shell of "complete files but all 22 agents can't connect".

---

### Block 1: Directory structure

```bash
mkdir -p .opencode/agents .opencode/commands .opencode/skills .opencode/tests
```

---

### reasoning_effort support matrix (measured)

`reasoningEffort` is a legal passthrough parameter (agents doc *Additional* section), but **the OpenCode Go gateway only accepts lowercase values, and unsupported values hard-fail with 400 (it does not auto-downgrade to default)**. The table below is the measured result per model against the `zen/go/v1` endpoint (`OK`=normal return, `400`=request rejected, `500*`=backend transient instability):

> ⚠️ **Prerequisites**: for the `reasoningEffort` values in this matrix to actually take effect, two conditions must be met:
>
> 1. The provider uses `@ai-sdk/openai-compatible` (this project's default): this SDK **transparently passes through** `reasoningEffort` with no switch needed — the matrix values below take effect directly. The passthrough regression only happens with `@ai-sdk/openai` (>=1.3.4), where `forceReasoning: true` is then needed.
> 2. The agent's `reasoningEffort` field is spelled all lowercase (`medium` not `Medium`). Uppercase gets rejected by the gateway with 400.
>    If an agent reports `Upstream request failed` and the log contains 400, suspect these two points first rather than assuming the model is down.

| Model              | low | medium | high | max  | xhigh | none | minimal | Notes                                  |
| ------------------ | --- | ------ | ---- | ---- | ----- | ---- | ------- | -------------------------------------- |
| deepseek-v4-flash  | OK  | OK     | OK   | OK   | OK    | 400  | 400     | all tiers supported                    |
| mimo-v2.5          | OK  | OK     | OK   | 500* | 500*  | 500* | 500*    | max/xhigh occasionally 500, use high   |
| mimo-v2.5-pro      | OK  | OK     | OK   | OK   | OK    | OK   | OK      | all tiers supported                    |
| minimax-m3         | OK  | OK     | OK   | OK   | OK    | OK   | OK      | all tiers supported                    |
| glm-5.2            | OK  | OK     | OK   | OK   | OK    | OK   | 400     | all tiers supported                    |
| qwen3.7-max        | OK  | OK     | OK   | 400  | OK    | OK   | OK      | `max` is 400, use `xhigh` for max      |
| qwen3.7-plus       | OK  | OK     | OK   | 400  | OK    | OK   | OK      | `max` is 400, use `xhigh` for max      |
| kimi-k2.7-code     | OK  | OK     | OK   | 400  | 400   | 400  | OK      | max only up to `high`                  |
| deepseek-v4-pro    | OK  | OK     | OK   | OK   | OK    | 400  | 400     | all tiers supported                    |

**Rules:**

1. Values must be lowercase: `low` / `medium` / `high` / `max` / `xhigh` / `none` / `minimal`. Uppercase `Medium`/`High` always 400.
2. `extreme` / `extended` / `xmedium` / `adaptive` / `auto` are 400 on all models, unusable.
3. An unsupported value for a model → that agent gets 400 (`Upstream request failed`) directly, **no fallback to default strength**. The default only applies when `reasoningEffort` is entirely omitted.
4. This package's parameters: tool/quick-task layer uses `medium` (high call volume, cost control); opinion/fusion layer bumps to the model's highest supported tier (minimax/glm/pro/mimo-pro→`max`, qwen-max→`xhigh`, kimi→`high`) to maximize reasoning quality.

> ⚠️ **Do not manually switch "variant / reasoning tier" in the TUI**: OpenCode's variant selection (desktop `Ctrl+t`, or picking in the model list) **overrides** the `reasoningEffort` configured for the agent in `opencode.json` / agent `.md`, and writes it to the model selection cache — `~/.local/state/opencode/model.json` on Linux / macOS / **WSL** (WSL runs on a Windows host but uses the Linux path, not the Windows path), `%USERPROFILE%\.local\state\opencode\model.json` on Windows — which **persists across restarts (the two path forms already cover every platform, consistent across all)**. Note: on Unix the path is governed by `XDG_STATE_HOME` and can be redirected. Once you switch manually, this package's low→xhigh tiers get silently overridden and are hard to notice. To change reasoning strength, edit the agent's `reasoningEffort` field and restart, instead of switching variants in the TUI.

### `@` menu display cap and `hidden` convention

OpenCode's `@` autocomplete menu has a **display line cap** (about 10 lines); agents beyond it get truncated and no longer shown. Sorting is by name, unrelated to category.

Mitigation: set `hidden: true` for agents that **are only orchestrated by the concierge-router via the Task tool and the user almost never types `@` to call**. This field **only hides the `@` menu item, it does not block Task calls** (the concierge-router calls them via Task), so the fusion chain behavior is unaffected.

**The 18 orchestration-layer agents set to `hidden: true`:**

- flag-arch / flag-plan / flag-eng / flag-fuse / flag-impl / flag-qa (flagship fusion chain, concierge-router-driven)
- mid-eng / mid-creative / mid-coder / mid-fuse (opinion layer, concierge-router-driven)
- fe-restore / fe-logic / fe-motion / fe-lead (frontend opinion + fusion, concierge-router-driven)
- residual-extractor / confidence-assessor / fusion-fallback (analysis + fallback layer, concierge-router-driven)
- tool-handler-mimo (tool agent fallback, concierge-router retry-chain driven)

**Kept visible (users often `@` them):** concierge-router (primary), tool-handler, vision-translator, swift, plus built-in explore / general.

> `hidden` only takes effect on `mode: subagent`; the primary agent (concierge-router) is not in the `@` menu and needs no setting.

> 🔧 **Customization — nothing here is hard-bound.** Agent names and their `model` assignments are starting-point suggestions, not contracts:
> - **Models**: change any agent's `model:` to any model/provider you have access to. The 9 `opencode-go` model IDs in the provider block are declarations only — swap them freely (e.g. drop Go and use your own Anthropic/OpenAI key).
> - **Agent names**: you may rename any agent, but a rename is a global find-and-replace — you must update **every** reference or deployment breaks: the concierge-router's `task:` whitelist, `opencode.json`'s `permission.task` whitelist, and all cross-agent `@`/`task` calls. Miss one and that agent goes unreachable (task call denied).
> - **The router itself**: keep `concierge-router` identical across its own frontmatter, the `task:` whitelist above, and `opencode.json`'s `default_agent`.

### Block 2: 22 Agent files

All agents are written to `.opencode/agents/`. Check existing files in the directory before writing to avoid overwriting same-named files.

Write order:

1. concierge-router (primary)
2. tool-handler → tool-handler-mimo → swift → vision-translator
3. mid-eng → mid-creative → mid-coder → mid-fuse
4. flag-arch → flag-plan → flag-eng → flag-fuse → flag-impl → flag-qa
5. fe-restore → fe-logic → fe-motion → fe-lead
6. residual-extractor → confidence-assessor → fusion-fallback (hidden, concierge-driven)

**Self-check**: `Get-ChildItem .opencode/agents/*.md` count should be 22.

#### concierge-router

`.opencode/agents/concierge-router.md`:

```markdown
---
description: Entry-point router; dispatches by task complexity, produces no code or plans
mode: primary
model: opencode-go/deepseek-v4-flash
temperature: 0.1
reasoningEffort: medium
max_tokens: 2048
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
  "*": deny
  task:
    "*": deny
    "tool-handler": allow
    "tool-handler-mimo": allow
    "swift": allow
    "vision-translator": allow
    "mid-eng": allow
    "mid-creative": allow
    "mid-coder": allow
    "mid-fuse": allow
    "flag-arch": allow
    "flag-plan": allow
    "flag-eng": allow
    "flag-fuse": allow
    "flag-impl": allow
    "flag-qa": allow
    "fe-restore": allow
    "fe-logic": allow
    "fe-motion": allow
    "fe-lead": allow
    "fusion-fallback": allow
    "residual-extractor": allow
    "confidence-assessor": allow
---

Receive a request → task(@tool-handler) probes whether the tool layer is available
  → available → continue normal routing
  → unavailable → task(@tool-handler-mimo)
    → available → continue normal routing
    → unavailable → stop and ask the user:

      "The tool layer is temporarily down (Flash and MiMo both unreachable).

       A. Wait a few minutes and retry
       B. Skip the tool layer and call the opinion layer directly (costlier, ~3–10×)
       C. Switch to a free model to proceed

       ⚠️ Free-model limits:
       - Smaller context window — may lose info on large projects
       - Slower response, may need retry
       - Free for now, may later be paid

         Tip: option C is manual — open the model list with /models and pick a free model (Windows desktop client: also Ctrl+'), then type your request directly."

      → user picks A → retry tool-handler after 30s
      → user picks B → call the opinion layer (no material passed; it returns a plan)
      → user picks C → concierge-router prints the manual steps

      ⚠️ Important: when the tool layer fails, you MUST stop and wait for the user's choice before continuing. Do not skip the ask and run normal routing on your own.

Normal routing:
  small task → @swift
  needs context → @tool-handler (parallel @tool-handler-mimo for large volume)
  screenshot → +@vision-translator
  medium → @tool-handler → parallel @mid-eng @mid-creative @mid-coder → @mid-fuse → @residual-extractor
  large → @tool-handler → parallel @flag-arch @flag-plan @flag-eng → @flag-fuse → @flag-impl → @flag-qa → @residual-extractor
  UI → parallel @fe-restore @fe-logic @fe-motion → @fe-lead

Forward the fused-layer output to the user; hide intermediate results.
If an agent fails or times out → skip it and continue with what returned. If the fusion agent (mid-fuse / flag-fuse) fails, returns empty, or errors → @fusion-fallback compares the three plans and outputs one. All fail → STUCK: cannot route.
STUCK → tell the user to press Tab to switch to the plan agent (Windows desktop client: also Ctrl+.).
```

#### tool-handler

`.opencode/agents/tool-handler.md`:

```markdown
---
description: Reads code, searches files, calls MCP; gives no opinions
mode: subagent
model: opencode-go/deepseek-v4-flash
temperature: 0.1
reasoningEffort: medium
max_tokens: 2048
permission:
  edit: deny
  bash: deny
---

Performs read/search only. Returns file paths + original text or summaries. Does not analyze or propose solutions.

On failure → retry once immediately
  → retry succeeds → return normally
  → retry fails → output ERROR category: cause, then terminate
    ERROR_PROVIDER: provider returned 502/503/timeout (transient connection drop)
    ERROR_AUTH: auth failure
    ERROR_UNKNOWN: other error
```

#### tool-handler-mimo

`.opencode/agents/tool-handler-mimo.md`:

```markdown
---
description: Tool handler; MiMo model as fallback
mode: subagent
hidden: true
model: opencode-go/mimo-v2.5
temperature: 0.1
reasoningEffort: medium
max_tokens: 2048
permission:
  edit: deny
  bash: deny
---

Performs read/search only. Returns file paths + original text or summaries. Does not analyze or propose solutions.

On failure → retry once immediately
  → retry succeeds → return normally
  → retry fails → output ERROR category: cause, then terminate
    ERROR_PROVIDER: provider returned 502/503/timeout (transient connection drop)
    ERROR_AUTH: auth failure
    ERROR_UNKNOWN: other error
```

#### swift

`.opencode/agents/swift.md`:

```markdown
---
description: Handles simple, small tasks quickly
mode: subagent
model: opencode-go/deepseek-v4-flash
temperature: 0.2
reasoningEffort: medium
max_tokens: 2048
permission:
  edit: allow
  bash: allow
---

Specializes in simple, well-defined small tasks. Delivers results directly — no preamble, no filler.

Out of scope → ESCALATE:
On failure → retry once immediately
  → retry succeeds → return normally
  → retry fails → stuck → STUCK: explain the cause
```

#### vision-translator

`.opencode/agents/vision-translator.md`:

```markdown
---
description: Converts screenshots / UI images / error images to text descriptions
mode: subagent
model: opencode-go/mimo-v2.5
temperature: 0.2
reasoningEffort: medium
max_tokens: 2048
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
---

Convert screenshot to a precise text description:
1. Overall layout
2. Content of each region
3. Color style, spacing
4. Errors: full error + stack trace
5. Code screenshots: line-by-line reconstruction

On failure → retry once immediately
  → retry succeeds → return normally
  → retry fails → stuck → STUCK: explain the cause
```

#### mid-eng

`.opencode/agents/mid-eng.md`:

```markdown
---
description: Engineering-perspective plan
mode: subagent
model: opencode-go/minimax-m3
temperature: 0.4
reasoningEffort: max
max_tokens: 16384
hidden: true
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
  task:
    "tool-handler": allow
    "vision-translator": allow
---

You are one of MoA's three opinion agents (engineering view). Produce plans from material. Engineering-minded, maintainable, defensive programming.

When directly @-called with no context: ask the user whether to gather material first.
yes → task(@tool-handler) gathers material → produce plan
no → produce plan directly

When called without material (tool layer failed):
  → ask user: "No material received. Produce a plan directly, or wait for the tool layer to recover?"
  → user picks direct → produce a plan from the requirement description (no code read, no MCP, pure logical reasoning)
  → user picks wait → output "WAITING: waiting for tool layer to recover"

---memory layer---
(core idea + key decisions)
---plan---
```

#### mid-creative

`.opencode/agents/mid-creative.md`:

```markdown
---
description: Creative-perspective plan
mode: subagent
model: opencode-go/deepseek-v4-pro
temperature: 0.5
reasoningEffort: medium
max_tokens: 16384
hidden: true
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
  task:
    "tool-handler": allow
    "vision-translator": allow
---

You are one of MoA's three opinion agents (creative view). Deliberately differ from the engineering view. Novel, differentiated design.

When directly @-called with no context: ask the user whether to gather material first.
yes → task(@tool-handler) gathers material → produce plan
no → produce plan directly

When called without material (tool layer failed):
  → ask user: "No material received. Produce a plan directly, or wait for the tool layer to recover?"
  → user picks direct → produce a plan from the requirement description (no code read, no MCP, pure logical reasoning)
  → user picks wait → output "WAITING: waiting for tool layer to recover"

---memory layer---
(difference from & edge over the engineering plan)
---plan---
```

#### mid-coder

`.opencode/agents/mid-coder.md`:

```markdown
---
description: Pragmatic-perspective plan
mode: subagent
model: opencode-go/deepseek-v4-flash
temperature: 0.3
reasoningEffort: medium
max_tokens: 16384
hidden: true
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
  task:
    "tool-handler": allow
    "vision-translator": allow
---

You are one of MoA's three opinion agents (coder view). Fastest and most direct. When engineering/creative over-design, offer a simpler alternative.

When directly @-called with no context: ask the user whether to gather material first.
yes → task(@tool-handler) gathers material → produce plan
no → produce plan directly

---memory layer---
(core difference from the other two plans)
---plan---
```

#### mid-fuse

`.opencode/agents/mid-fuse.md`:

```markdown
---
description: Fuses three plans into one
mode: subagent
hidden: true
model: opencode-go/kimi-k2.7-code
temperature: 0.3
reasoningEffort: high
max_tokens: 16384
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
---

Compare the engineering, creative, and coder plans. Keep consensus, pick the best on divergence, fuse differences. Deliver only one.

Briefly state the fusion decision
---plan---
Complete fused code
```

#### flag-arch

`.opencode/agents/flag-arch.md`:

```markdown
---
description: Top-level architecture design
mode: subagent
hidden: true
model: opencode-go/qwen3.7-max
temperature: 0.4
reasoningEffort: xhigh
max_tokens: 16384
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
  task:
    "tool-handler": allow
    "vision-translator": allow
---

You are one of the flagship's three opinion agents (architecture). Plans only, do not edit files.

When directly @-called with no context: ask the user whether to gather material first.
yes → task(@tool-handler) gathers material → produce plan
no → produce plan directly

When called without material (tool layer failed):
  → ask user: "No material received. Produce a plan directly, or wait for the tool layer to recover?"
  → user picks direct → produce a plan from the requirement description (no code read, no MCP, pure logical reasoning)
  → user picks wait → output "WAITING: waiting for tool layer to recover"

---ARCHITECTURE DESIGN---
Core decisions (≤5) | Tech choices + reasons | Module split + data flow | Interface definitions | Risks + mitigation
```

#### flag-plan

`.opencode/agents/flag-plan.md`:

```markdown
---
description: Structured plan design
mode: subagent
hidden: true
model: opencode-go/glm-5.2
temperature: 0.4
reasoningEffort: max
max_tokens: 16384
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
  task:
    "tool-handler": allow
    "vision-translator": allow
---

You are one of the flagship's three opinion agents (planning). Limited quota, use only for very complex tasks.

When directly @-called with no context: ask the user whether to gather material first.
yes → task(@tool-handler) gathers material → produce plan
no → produce plan directly

When called without material (tool layer failed):
  → ask user: "No material received. Produce a plan directly, or wait for the tool layer to recover?"
  → user picks direct → produce a plan from the requirement description (no code read, no MCP, pure logical reasoning)
  → user picks wait → output "WAITING: waiting for tool layer to recover"

---PLAN---
Problem-domain analysis | Plan structure | Execution path | Risks & responses
```

#### flag-eng

`.opencode/agents/flag-eng.md`:

```markdown
---
description: Large-scale implementation plan
mode: subagent
hidden: true
model: opencode-go/minimax-m3
temperature: 0.5
reasoningEffort: max
max_tokens: 16384
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
  task:
    "tool-handler": allow
    "vision-translator": allow
---

You are one of the flagship's three opinion agents (engineering). Cross-module interface consistency, performance & overhead, observability.

When directly @-called with no context: ask the user whether to gather material first.
yes → task(@tool-handler) gathers material → produce plan
no → produce plan directly

When called without material (tool layer failed):
  → ask user: "No material received. Produce a plan directly, or wait for the tool layer to recover?"
  → user picks direct → produce a plan from the requirement description (no code read, no MCP, pure logical reasoning)
  → user picks wait → output "WAITING: waiting for tool layer to recover"

---ENGINEERING PLAN---
Implementation points | Module split + interfaces | Performance & capacity | Observability
```

#### flag-fuse

`.opencode/agents/flag-fuse.md`:

```markdown
---
description: Fuses three architecture plans
mode: subagent
hidden: true
model: opencode-go/qwen3.7-max
temperature: 0.3
reasoningEffort: high
max_tokens: 16384
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
---

Compare the architecture, planning, and engineering plans. Keep consensus, note divergence, fuse differences. Deliver only one.
Briefly state the fusion rationale

---FUSED PLAN---
```

#### flag-impl

`.opencode/agents/flag-impl.md`:

```markdown
---
description: Implements the fused plan
mode: subagent
hidden: true
model: opencode-go/deepseek-v4-flash
temperature: 0.2
reasoningEffort: medium
max_tokens: 16384
permission:
  edit: allow
  bash: allow
---

Code per the fused plan. Do not change interface signatures. Report ambiguity, do not decide on your own.

On failure → retry once immediately
  → retry succeeds → return normally
  → retry fails → stuck → STUCK: explain the cause

---IMPLEMENTATION NOTES---
(scope + key decisions)
---CODE---
```

#### flag-qa

`.opencode/agents/flag-qa.md`:

```markdown
---
description: Verifies plan vs code across all dimensions
mode: subagent
hidden: true
model: opencode-go/deepseek-v4-pro
temperature: 0.2
reasoningEffort: max
max_tokens: 16384
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
---

Compare plan and code. Do not output code. When rejecting, point to the specific issue.

On failure → retry once immediately
  → retry succeeds → return normally
  → retry fails → stuck → STUCK: explain the cause

Pass / Conditional pass / Reject
```

#### fe-restore

`.opencode/agents/fe-restore.md`:

```markdown
---
description: Pixel-perfect UI mockup reproduction
mode: subagent
model: opencode-go/mimo-v2.5
temperature: 0.3
reasoningEffort: medium
max_tokens: 16384
hidden: true
permission:
  edit: allow
  bash: allow
---

Faithfully reproduce the UI exactly by layout, color, and text. Component-based, responsive. Output complete code.
```

#### fe-logic

`.opencode/agents/fe-logic.md`:

```markdown
---
description: Frontend component architecture & state plan
mode: subagent
model: opencode-go/qwen3.7-plus
temperature: 0.4
reasoningEffort: medium
max_tokens: 16384
hidden: true
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
  task:
    "tool-handler": allow
    "vision-translator": allow
---

You are one of the frontend MoA's three opinion agents (logic). Component architecture, TS types, state management, API layer.

When directly @-called with no context: ask the user whether to gather material first.
yes → task(@tool-handler) gathers material → produce plan
no → produce plan directly

When called without material (tool layer failed):
  → ask user: "No material received. Produce a plan directly, or wait for the tool layer to recover?"
  → user picks direct → produce a plan from the requirement description (no code read, no MCP, pure logical reasoning)
  → user picks wait → output "WAITING: waiting for tool layer to recover"

---LOGIC PLAN---
Component tree + responsibilities | Type definitions | State layer | API interface layer
```

#### fe-motion

`.opencode/agents/fe-motion.md`:

```markdown
---
description: Frontend interaction & motion plan
mode: subagent
model: opencode-go/mimo-v2.5-pro
temperature: 0.5
reasoningEffort: max
max_tokens: 16384
hidden: true
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
  task:
    "tool-handler": allow
    "vision-translator": allow
---

You are one of the frontend MoA's three opinion agents (motion). Add transition animations and micro-interactions on top of the reproduction. Component split differs from restore/logic.

When directly @-called with no context: ask the user whether to gather material first.
yes → task(@tool-handler) gathers material → produce plan
no → produce plan directly

When called without material (tool layer failed):
  → ask user: "No material received. Produce a plan directly, or wait for the tool layer to recover?"
  → user picks direct → produce a plan from the requirement description (no code read, no MCP, pure logical reasoning)
  → user picks wait → output "WAITING: waiting for tool layer to recover"
```

#### fe-lead

`.opencode/agents/fe-lead.md`:

```markdown
---
description: Picks / fuses the best of three frontend plans
mode: subagent
hidden: true
model: opencode-go/glm-5.2
temperature: 0.3
reasoningEffort: high
max_tokens: 16384
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
---

Compare the restore, logic, and motion code. Pick the best or fuse. No ambiguity allowed. If all three are flawed, produce a corrected version.

Scores (layout/code quality/interaction/visual/TS) | Comparison verdict | ---FINAL CODE---
```

---



#### residual-extractor

`.opencode/agents/residual-extractor.md`：

```markdown
---
description: Extract residual information across multiple plans; identify consensus and divergence
mode: subagent
model: opencode-go/deepseek-v4-flash
temperature: 0.3
reasoningEffort: medium
max_tokens: 4096
hidden: true
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
---

You are the residual-extraction specialist. Your only job is to analyze the differences between multiple input plans and surface the incremental information beyond consensus.

## Workflow

1. **Consensus identification** — find the core decisions all plans agree on.
2. **Divergence extraction** — identify contradictions and differences between plans.
3. **Difference classification**:
   - Complementary: plans focus on different aspects, mergeable.
   - Contradictory: fundamental conflict between plans, pick one.
   - Redundant: plans express the same idea, keep the best wording.
4. **Hallucination flagging** — flag suspicious tech choices, non-existent APIs, fabricated libraries.

## Output format

---residual report---
[consensus coverage] XX%

[consensus]
- decision 1: ...

[divergence handling]
divergence 1:
  - plan A: ...
  - plan B: ...
  - type: complementary / contradictory / redundant
  - handling: merge / pick-one / discard

[suspected hallucinations]
- location: plan X
- issue: description
- confidence: high / medium / low

[residual compensation suggestions]
(incremental info beyond consensus; what to add)
```

#### confidence-assessor

`.opencode/agents/confidence-assessor.md`：

```markdown
---
description: Assess the confidence and compliance of MoA fusion results
mode: subagent
model: opencode-go/deepseek-v4-pro
temperature: 0.2
reasoningEffort: max
max_tokens: 4096
hidden: true
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
---

You are the confidence assessor. Review the credibility of MoA fusion output.

## Scoring (0-100, shares dimensions with concierge-router / flag-qa)

| Dimension | Weight | What to score |
| --- | --- | --- |
| Requirement clarity | 0.25 | Does output answer the user's concrete constraints |
| Model fit | 0.20 | Does the chosen approach match model capability |
| Task complexity | 0.15 | Does the plan cover the task's complexity |
| Familiarity | 0.10 | Uses mature tech the team knows |
| Context sufficiency | 0.10 | Uses available material/context |
| Risk level | 0.10 | Identifies potential risks |

Overall confidence = 100 * Sum(dimension score * weight)

## Review dimensions

1. **Hallucination detection** — fabricated tech, non-existent APIs, invented libraries.
2. **Requirement alignment** — meets all constraints of the original request.
3. **Spec conflict** — conflicts with existing project specs / official docs.
4. **Feasibility** — can it actually land in the current project context.

## Output format

---confidence report---
overall confidence: X/100

hallucination risk: high / medium / low
  - [details]

requirement alignment: X%
  - unmet constraints: [...]

spec conflict: yes / no
  - [if any, list conflicts]

feasibility: high / medium / low
  - [reason]

---disposition---
confidence >= 85: adopt directly
confidence 60-84: adopt with conditions — [what to fix]
confidence < 60: redo — [main reason]
```

#### fusion-fallback

`.opencode/agents/fusion-fallback.md`：

```markdown
---
description: Fusion-layer fallback; compare three inputs and output one (inherits residual-enhanced fusion)
mode: subagent
model: opencode-go/deepseek-v4-pro
temperature: 0.3
reasoningEffort: max
max_tokens: 16384
hidden: true
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
---

You are the fusion fallback. When any primary fusion agent fails (STUCK / ERROR_PROVIDER / timeout / empty result), the concierge-router routes the three plans to you.

Compare the three plans, keep consensus, take the best on divergence using the residual-enhanced flow, and output a single fused plan. Do not sit on the fence. If all three are flawed, emit a corrected version.

[consensus coverage] | comparison conclusion | ---final plan---
```
### Block 3: 5 `/moa-*` commands

One file per command in `.opencode/commands/`. File names share the `moa-` prefix.

**Self-check**: `Get-ChildItem .opencode/commands/*.md` count should be 5, all starting with `moa-`.

```markdown
# moa-quick.md
---
description: One-shot for simple, small tasks
---
@swift handle the following request:
$ARGUMENTS
```

```markdown
# moa-frontend.md
---
description: Frontend triple MoA — restore + logic + motion → lead picks best
---
Run the frontend triple MoA on the following request:
$ARGUMENTS
Flow:
1. if a screenshot is involved, first @vision-translator
2. @fe-restore + @fe-logic + @fe-motion produce plans in parallel
3. @fe-lead picks the best / fuses
```

```markdown
# moa-medium.md
---
description: Mid-tier triple MoA — 3 opinions in parallel + 1 fuse
---
Run the mid-tier triple MoA on the following request:
$ARGUMENTS
Flow:
1. @tool-handler + @vision-translator gather material
2. @mid-eng + @mid-creative + @mid-coder produce plans in parallel
3. @mid-fuse fuses
4. @residual-extractor surfaces consensus + divergence across the plans
```

```markdown
# moa-flagship.md
---
description: Flagship triple MoA — 3 architecture opinions + fuse + implement + QA
---
Run the flagship triple MoA on the following request:
$ARGUMENTS
Flow:
1. @tool-handler + @vision-translator gather material
2. @flag-arch + @flag-plan + @flag-eng produce architecture plans in parallel
3. @flag-fuse fuses
4. @residual-extractor surfaces consensus + divergence across the plans
5. (if needed) @flag-impl codes
6. @flag-qa verifies, then @confidence-assessor scores the fused result
```

```markdown
# moa-describe.md
---
description: Screenshot/image to text description
---
@vision-translator analyze the following:
$ARGUMENTS
```

---

### Block 4: 3 Skills

One directory per skill, with a `SKILL.md` inside.

**Self-check**: `Get-ChildItem .opencode/skills/*/SKILL.md` count should be 3.

```markdown
# code-review-moa
---
description: Mid-tier MoA code review — two opinions + fuse
---
<flow>
1. task(@tool-handler) reads code
2. task(@mid-eng) + task(@mid-creative) produce review opinions in parallel
3. task(@mid-fuse) fuses
</flow>
<rules>
- single-module / function level
- output: fusion rationale + complete code
</rules>
```

```markdown
# architecture-moa
---
description: Flagship MoA — three architecture opinions → fuse → implement → QA
---
<flow>
1. task(@tool-handler) + task(@vision-translator) gather material
2. task(@flag-arch) + task(@flag-plan) + task(@flag-eng) in parallel
3. task(@flag-fuse) fuses
4. task(@residual-extractor) surfaces consensus + divergence
5. task(@flag-impl) codes
6. task(@flag-qa) verifies, then task(@confidence-assessor) scores the fused result
</flow>
<rules>
- system architecture or multi-module design
- output: QA report
</rules>
```

```markdown
# frontend-moa
---
description: Frontend triple MoA — restore + logic + motion → lead picks best
---
<flow>
1. if screenshot, task(@vision-translator)
2. task(@fe-restore) + task(@fe-logic) + task(@fe-motion) in parallel
3. task(@fe-lead) picks the best / fuses
</flow>
<rules>
- UI implementation, screenshot reproduction, CSS fix
- output: comparison verdict + final code
</rules>
```

---

### Block 5: opencode.json

> ⚠️ The provider config block was already added to `opencode.json` by the AI in the Provider section (`apiKey` references an external file via `{file:}`), **do not write it again**.

First read the existing `opencode.json`, merge `permissions.task` rather than overwrite.

> ✅ **Don't hardcode `instructions`**: the `instructions` in the JSON below is **optional**, commented out by default. OpenCode reports a startup warning if it references a non-existent `AGENTS.md`.
>
> - Only uncomment and enable `"instructions": ["AGENTS.md"]` when an `AGENTS.md` **already exists** at the project root.
> - If the project has no `AGENTS.md`, keep it commented/omitted — MoA does not impose a convention file on the project.
> - To use custom project guidance: create your own `AGENTS.md` then uncomment; no agent change needed.

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "default_agent": "concierge-router",
  "permission": {
    "*": "ask",
    "bash": {
      "*": "ask",
      "git *": "allow",
      "git status *": "allow",
      "git diff *": "allow",
      "git log *": "allow",
      "grep *": "allow",
      "ls *": "allow",
      "cat *": "allow",
      "cd *": "allow",
      "npm run *": "allow",
      "rm *": "deny",
      "del *": "deny"
    },
    "task": {
      "*": "deny",
      "tool-handler": "allow",
      "tool-handler-mimo": "allow",
      "swift": "allow",
      "vision-translator": "allow",
      "mid-eng": "allow",
      "mid-creative": "allow",
      "mid-coder": "allow",
      "mid-fuse": "allow",
      "flag-arch": "allow",
      "flag-plan": "allow",
      "flag-eng": "allow",
      "flag-fuse": "allow",
      "flag-impl": "allow",
      "flag-qa": "allow",
      "fe-restore": "allow",
      "fe-logic": "allow",
      "fe-motion": "allow",
      "fe-lead": "allow",
      "fusion-fallback": "allow",
      "residual-extractor": "allow",
      "confidence-assessor": "allow"
    },
    "webfetch": "allow",
    "read": {
      "*": "allow",
      "*.env": "deny",
      "*.env.*": "deny",
      "*.env.example": "allow"
    }
  },
  "agent": {
    "mid-eng": {
      "permission": {
        "*": "ask",
        "task": "allow",
        "*_*": "deny"
      }
    },
    "mid-creative": {
      "permission": {
        "*": "ask",
        "task": "allow",
        "*_*": "deny"
      }
    },
    "mid-coder": {
      "permission": {
        "*": "ask",
        "task": "allow",
        "*_*": "deny"
      }
    },
    "flag-arch": {
      "permission": {
        "*": "ask",
        "task": "allow",
        "*_*": "deny"
      }
    },
    "flag-plan": {
      "permission": {
        "*": "ask",
        "task": "allow",
        "*_*": "deny"
      }
    },
    "flag-eng": {
      "permission": {
        "*": "ask",
        "task": "allow",
        "*_*": "deny"
      }
    },
    "fe-logic": {
      "permission": {
        "*": "ask",
        "task": "allow",
        "*_*": "deny"
      }
    },
    "fe-motion": {
      "permission": {
        "*": "ask",
        "task": "allow",
        "*_*": "deny"
      }
    }
  },
  // "instructions": ["AGENTS.md"],   // optional: enable only when AGENTS.md already exists at project root, otherwise keep commented to avoid startup warning
  "compaction": {
    "auto": true,
    "reserved": 10000
  },
  "share": "manual",
  "snapshot": true
}
```

### Block 5.5: verification script T0-static-verify.ps1 (generated during deploy)

> Both earlier in this manual and in "How to tell deployment succeeded" reference `pwsh .opencode/tests/T0-static-verify.ps1`. This script **is not distributed with the repo** and must be generated by the deploy process in this step, otherwise other users following the manual won't find the file. Write it to `.opencode/tests/T0-static-verify.ps1`:

```powershell
# T0-static-verify.ps1 — OpenCode MoA static deploy verification
# Usage: pwsh .opencode/tests/T0-static-verify.ps1
$ErrorActionPreference = 'Stop'
$root = if ($PSScriptRoot) { Resolve-Path (Join-Path $PSScriptRoot '..' '..') } else { '.' }
Push-Location $root

$pass = 0; $fail = 0; $warn = 0
function Check($name, $ok, $warnOnly = $false) {
    if ($ok) { Write-Host "PASS  $name"; $script:pass++ }
    elseif ($warnOnly) { Write-Host "WARN  $name"; $script:warn++ }
    else { Write-Host "FAIL  $name"; $script:fail++ }
}

$agents = @(Get-ChildItem .opencode/agents/*.md -ErrorAction SilentlyContinue)
Check "agents == 22 (got $($agents.Count))" ($agents.Count -eq 22)

$cmds = @(Get-ChildItem .opencode/commands/moa-*.md -ErrorAction SilentlyContinue)
Check "commands == 5 (got $($cmds.Count))" ($cmds.Count -eq 5)

$needSkills = 'code-review-moa','architecture-moa','frontend-moa'
$missing = $needSkills | Where-Object { -not (Test-Path ".opencode/skills/$_/SKILL.md") }
Check "3 required skills exist (missing: $($missing -join ','))" ($missing.Count -eq 0)

Check "opencode.json exists" (Test-Path opencode.json)

# provider hard gate: project or system-level (.json/.jsonc) must register opencode-go with a real apiKey (not placeholder/empty)
$sysDir = "$env:USERPROFILE/.config/opencode"
$cfgFiles = @()
if (Test-Path opencode.json)            { $cfgFiles += 'opencode.json' }
if (Test-Path "$sysDir\opencode.json")  { $cfgFiles += "$sysDir\opencode.json" }
if (Test-Path "$sysDir\opencode.jsonc") { $cfgFiles += "$sysDir\opencode.jsonc" }
$provRaw = ($cfgFiles | ForEach-Object { Get-Content $_ -Raw -ErrorAction SilentlyContinue }) -join "`n"
$hasProv = $provRaw -match '"opencode-go"'
$hasRealKey = ($provRaw -match '"apiKey"\s*:\s*"(sk-[^"]+)"') -or ($provRaw -match '"apiKey"\s*:\s*"\{file:[^"]+\}"')
$hasPlaceholder = ($provRaw -match '"apiKey"\s*:\s*"<YOUR_GO_API_KEY>"') -or ($provRaw -match '"apiKey"\s*:\s*""')
Check "provider.opencode-go registered and apiKey real (not placeholder/empty)" ($hasProv -and $hasRealKey -and -not $hasPlaceholder)

$re = (Select-String -Path .opencode/agents/*.md -Pattern 'reasoningEffort:' -ErrorAction SilentlyContinue).Count
Check "reasoningEffort x22 (got $re)" ($re -eq 22)

$task = (Select-String -Path .opencode/agents/*.md -Pattern 'task:' -ErrorAction SilentlyContinue).Count
Check "task: x9 (got $task)" ($task -eq 9)

Write-Host "`n== Result: PASS=$pass FAIL=$fail WARN=$warn =="
if ($fail -gt 0) { exit 1 } else { exit 0 }
```

Expected output: all `PASS` (with a system-level key, `WARN` also counts as pass), `FAIL=0` means deployment succeeded.

---

### Block 6: Verification

> ⚠️ The `bash` verification script below uses `ls` / `wc` / `grep` / `find`, which **only run on Linux / macOS / WSL / Git Bash**. Windows native CMD / PowerShell lacks these commands and will error out. On Windows use the PowerShell version below.

**Linux / macOS / WSL / Git Bash:**

```bash
echo "=== count check ==="
ls .opencode/agents/*.md 2>/dev/null | wc -l
ls .opencode/commands/*.md 2>/dev/null | wc -l
find .opencode/skills -name "SKILL.md" 2>/dev/null | wc -l
test -f opencode.json && echo "Config ok" || echo "Config missing"
test -f .opencode/local/opencode-go.key && echo "Key file ok" || echo "Key file MISSING"
```

Expected: Agents 22, Commands 5, Skills 3, Config ok. Key file line: shows `Key file ok` when the key is project-level; **when using the system-level `~/.config/opencode/` this shows `Key file MISSING` — that's normal**, as long as the system-level provider has a real key (or use the T0 script below, which judges a system-level key as PASS).

```bash
echo "=== content check ==="
grep "reasoningEffort:" .opencode/agents/*.md 2>/dev/null | wc -l
grep "task:" .opencode/agents/*.md 2>/dev/null | wc -l
ls .opencode/commands/moa-*.md 2>/dev/null | wc -l
```

Expected: `reasoningEffort` appears 22 times (all agents), `task:` appears 9 times (concierge-router + 8 opinion layers), `moa-` command filenames match 5.

**Windows (PowerShell, native):**

```powershell
Write-Host "=== count check ==="
(Get-ChildItem .opencode/agents/*.md -ErrorAction SilentlyContinue).Count
(Get-ChildItem .opencode/commands/*.md -ErrorAction SilentlyContinue).Count
(Get-ChildItem .opencode/skills/*/SKILL.md -ErrorAction SilentlyContinue).Count
if (Test-Path opencode.json) { "Config ok" } else { "Config missing" }
if (Test-Path .opencode/local/opencode-go.key) { "Key file ok" } else { "Key file MISSING" }

Write-Host "=== content check ==="
(Select-String -Path .opencode/agents/*.md -Pattern "reasoningEffort:" -ErrorAction SilentlyContinue).Count
(Select-String -Path .opencode/agents/*.md -Pattern "task:" -ErrorAction SilentlyContinue).Count
(Get-ChildItem .opencode/commands/moa-*.md -ErrorAction SilentlyContinue).Count
```

Expected same as above. If `Select-String` count is high, it's because `task:` appears in both the concierge-router and opinion-layer frontmatter — normal, total is 9 (concierge-router 1 + 8 opinion layers each 1).

> **Deployment complete**: after all the above verifications pass, **restart opencode to apply all config**.

### How to tell deployment succeeded

1. After restarting OpenCode, press `Tab` to cycle agents (Windows desktop client: `Ctrl+.` also works) and see "concierge-router"
2. Type `@tool-handler` and it responds (if no response, check whether the key in `.opencode/local/opencode-go.key` is correct)
3. Run the verification script: `pwsh .opencode/tests/T0-static-verify.ps1`, expected all PASS (FAIL=0)

### One-click rollback

```bash
rm -rf your-project/.opencode/
# manually restore your opencode.json (the install script auto-backups a .bak file)
```

## FAQ

### Installation

**Q: I already have an opencode.json, will it be overwritten?**
A: No. The install script only merges MoA's `permission`, `agent`, `default_agent` config, keeping your existing `provider`, `model`, etc. The original file is auto-backed up as `.bak.timestamp`.

**Q: Windows has no `cp` command, what do I do?**
A: Use `Copy-Item` or `xcopy`:

```powershell
# PowerShell
Copy-Item -Recurse -Force opencode-moa\.opencode .\.opencode
# CMD
xcopy opencode-moa\.opencode .\.opencode /E /I /Y
```

**Q: Can I install without pwsh/jq?**
A: Yes. Use Method 1 (AI auto-deploy) or Method 3 (manual config merge).

**Q: How do I install on the desktop app?**
A: Method 1 is most convenient — drag this file into the chat box and let the AI auto-deploy. Methods 2/3 require operating in a terminal (CMD/PowerShell/Terminal) first.

### Usage

**Q: Can't see "concierge-router"?**
A: Check three points:

1. Is `opencode.json` at the project root (not a subfolder)?
2. Are there 22 .md files under `.opencode/agents/`?
3. After restarting OpenCode, press `Tab` to cycle agents (Windows desktop client: `Ctrl+.` also works).

**Q: `@tool-handler` not responding?**
A: Confirm `.opencode/agents/tool-handler.md` exists and the frontmatter format is correct.

**Q: Error "model not found"?**
A: Wrong model ID or no OpenCode Go subscription. Run `/models` to check the model list.

**Q: MCP tools blocked?**
A: Normal behavior. The opinion layer is restricted by `*_*:deny` to prevent bypassing the tool layer to fetch material itself. The tool layer works normally.

**Q: Tool agent reports Upstream request failed?**
A: Transient provider jitter; MoA auto-retries once. Continued failure asks the user to choose wait / skip / free model.

**Q: How do I switch back to the original build/plan agent?**
A: Press `Tab` to switch (Windows desktop client: `Ctrl+.` also works), or type `/build`, `/plan`. MoA does not affect built-in agents.

**Q: I want to use my own model, not the Go plan?**
A: Just change the agent's `model` field:

```yaml
# .opencode/agents/mid-eng.md
model: anthropic/claude-sonnet-4-20250514
```

**Q: Can I delete the repo after deploying?**
A: Yes. MoA is already copied to your project's `.opencode/` directory; the original repo can be deleted.

**Q: How do I deploy across multiple projects?**
A: Deploy each project separately. `.opencode/` is project-level config and does not affect other projects.

### Fallback

**Q: The whole tool layer is down, what now?**
A: MoA asks the user:

- A. Wait a few minutes and retry
- B. Skip the tool layer and call the opinion layer directly (higher cost)
- C. Switch to a free model (manual operation required)

**Q: Where are the free models?**
A: Use `/models` to open the model list and pick a free model (Windows desktop client: `Ctrl+'` also works) (DeepSeek V4 Flash Free, etc.). Free models have limited context, may be slower, and data may be used for training.

---

## Deployment failure quick reference

Divided into two categories by "can it run after deploy". **Most cases are "files deployed successfully, but all agents unavailable at runtime"** — don't be fooled by "all files generated"; you must reach the verification step to count.

### A. Failure during deployment (files not generated / config error)

| Symptom                              | Root cause                                                         | Troubleshoot                                                                                       |
| ------------------------------------ | ------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------- |
| `opencode --version` errors / not installed | Not installed or PATH not set (desktop sub-shell often **falsely reports** due to different PATH) | Files can still be deployed; verify/run needs opencode installed: <https://opencode.ai/install>, restart desktop app |
| Startup reports `JSON parse error`   | `opencode.json` has an extra comma / comment in `.json` not `.jsonc` | Rename to `.jsonc`, or validate at [jsonlint](https://jsonlint.com)                                |
| 22 agent file count wrong            | Block 2 missed or overwrote                                        | Count per Block 6: agents=22                                                                       |
| Version < 1.1.1                      | `hidden` / `task` / agent-level `reasoningEffort` not supported    | Upgrade opencode to >= 1.3.4 (`@ai-sdk/openai-compatible` transparently passes reasoning, no `forceReasoning` needed) |

### B. Runtime failure (files complete, but agent errors)

| Symptom                                                       | Root cause                                                                                                          | Fix                                                                                              |
| ------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| All 22 agents `Upstream request failed` / silent failure      | **Neither system-level nor project-level has `opencode-go` provider, or key invalid**                                              | Go back to Provider section to set key, restart                                                 |
| System-level `opencode.json` deleted / dir empty, and project has no provider | Provider only in the deleted file → no provider resolvable anywhere                                                | Rebuild provider (default write project `opencode.json`, or system-level), restart; T0 now `FAIL`s |
| Same dir has both `opencode.json` and `opencode.jsonc`        | Official priority undefined for dual files, contents may conflict                                                  | **Keep only one** per dir, and make the kept one contain a valid `opencode-go` provider + real key |
| `apiKey` is `<YOUR_GO_API_KEY>` placeholder / empty           | Looks configured but actually 401/403                                                                               | Replace with real key; T0 now `FAIL`s                                                            |
| `@tool-handler` no response, log 401/403                             | Key file path wrong / placeholder not replaced / key expired                                                       | Check `.opencode/local/opencode-go.key` actually exists and content correct                      |
| An agent suddenly `Upstream request failed` + log has `400`   | `reasoningEffort` value illegal (uppercase / `max` on unsupported model / `extreme` etc.)                          | Fix to lowercase valid value per matrix below                                                    |
| Reasoning strength "feels unchanged" (always default)         | ①`reasoningEffort` uppercase/invalid value 400-downgraded to default; ②model doesn't support chosen tier 400; ③`npm` changed to `@ai-sdk/openai` without `forceReasoning` (only this case needs it, and >=1.3.4); ④opencode too old to support agent-level `reasoningEffort`; ⑤manually switched "variant/reasoning tier" in the TUI, the `model.json` cache's variant overrides the agent's `reasoningEffort` (cross-platform; WSL uses the Linux path; clear cache or edit agent field and restart to recover) | Fix to lowercase valid value per matrix; only if truly using `@ai-sdk/openai` add `forceReasoning: true` and restart (this project defaults to `openai-compatible`, not needed); if ⑤: delete the model selection cache (`~/.local/state/opencode/model.json` on Linux/macOS/WSL, `%USERPROFILE%\.local\state\opencode\model.json` on Windows; on Unix governed by `XDG_STATE_HOME`, can be redirected) or edit the agent's `reasoningEffort` field and restart |
| concierge-router orchestration `task` call rejected          | `opencode.json`'s `permission.task` whitelist missing agent name                                                    | Complete whitelist per Block 5                                                                   |
| Opinion layer wants MCP but blocked                          | By design (`*_*: deny`)                                                                                             | Normal; material must go through tool layer                                                      |
| Free model context insufficient, loses info                  | Free model window small                                                                                             | Be mentally prepared when choosing C downgrade                                                   |

### Cross-platform notes

- **CLI / desktop GUI**: same engine, same config path, both usable. Only difference: desktop has no TUI, so `/connect` (Method B) can't be used — only Method A (config file) works.
- **Linux / macOS**: `install.sh` + Block 6's bash verification script run natively, needs `jq` (optional).
- **Windows**:
  - System-level path is `C:\Users\<you>\.config\opencode\opencode.json` (**not** `%APPDATA%\opencode`, that's another tool, don't mix).
  - No native `cp` / `ls` / `wc` / `grep` / `find`. Copy with `Copy-Item`/`xcopy` (see Q above), verify with the **PowerShell version of Block 6** above.
  - `pwsh` (PowerShell Core) is not default; you can still deploy with Method 1/3 without it; use native PowerShell for the verification script.
- **headless / CI / WSL**: pure config-file method (Method A) works fully, no TUI, no interaction needed.
- **Model behavior (reasoningEffort matrix, quota) is platform-independent**, only depends on the OpenCode Go gateway, identical across the three platforms.

---

## Appendix A: Local model integration

Optional. Does not affect remote models. Multiple local models can be enabled at once.

### Ollama

```jsonc
{
  "provider": {
    "opencode-go": { /* original config */ },
    "ollama-local": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama (local)",
      "options": { "baseURL": "http://localhost:11434/v1" },
      "models": {
        "qwen3-coder": { "name": "Qwen3-Coder (local)" }
      }
    }
  }
}
```

### LM Studio

```jsonc
{
  "provider": {
    "opencode-go": { /* original config */ },
    "lmstudio-local": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "LM Studio (local)",
      "options": { "baseURL": "http://127.0.0.1:1234/v1" },
      "models": {
        "google/gemma-3n-e4b": { "name": "Gemma 3n (local)" }
      }
    }
  }
}
```

### Mixed use

```yaml
# .opencode/agents/mid-coder.md
model: ollama-local/qwen3-coder
```

---

## Appendix B: Security boundary explanation

| Protection layer     | Location                                 | Effect                                  |
| -------------------- | ---------------------------------------- | --------------------------------------- |
| Global catch-all     | opencode.json                            | Unexplicitly declared tool → "ask" popup |
| Agent permission     | Each agent file frontmatter              | Tool-level allow/deny hard limit        |
| MCP permission isolation | opencode.json agent.*.permission     | `*_*: deny` disables opinion-layer MCP  |
| Task permission whitelist | opencode.json + concierge-router frontmatter  | Can only task specified agents          |
| Fallback chain       | Tool agent / concierge-router prompt              | Quick retry → ask user → downgrade      |

---

> **Doc version**: v0.0.9 | **Corresponding opencode**: >= 1.3.4 (agent-level reasoningEffort/hidden/task support; `@ai-sdk/openai-compatible` transparently passes reasoning, no `forceReasoning` needed)
