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
| deepseek-v4-flash  | 400 | 400    | OK   | OK   | 400   | 400  | 400     | only high/max supported, others 400 (since 0731) |
| mimo-v2.5          | OK  | OK     | OK   | 500* | 500*  | 500* | 500*    | max/xhigh occasionally 500, use high   |
| mimo-v2.5-pro      | OK  | OK     | OK   | OK   | OK    | OK   | OK      | all tiers supported                    |
| minimax-m3         | OK  | OK     | OK   | OK   | OK    | OK   | OK      | all tiers supported                    |
| glm-5.2            | OK  | OK     | OK   | OK   | OK    | OK   | 400     | retired, replaced by deepseek-v4-flash |
| qwen3.7-max        | OK  | OK     | OK   | 400  | OK    | OK   | OK      | `max` is 400, use `xhigh` for max      |
| qwen3.7-plus       | OK  | OK     | OK   | 400  | OK    | OK   | OK      | `max` is 400, use `xhigh` for max      |
| kimi-k2.7-code     | OK  | OK     | OK   | 400  | 400   | 400  | OK      | max only up to `high`                  |
| deepseek-v4-pro    | OK  | OK     | OK   | OK   | OK    | 400  | 400     | all tiers supported                    |

**Rules:**

1. Values must be lowercase: `low` / `medium` / `high` / `max` / `xhigh` / `none` / `minimal`. Uppercase `Medium`/`High` always 400.
2. `extreme` / `extended` / `xmedium` / `adaptive` / `auto` are 400 on all models, unusable.
3. An unsupported value for a model → that agent gets 400 (`Upstream request failed`) directly, **no fallback to default strength**. The default only applies when `reasoningEffort` is entirely omitted.
4. This package's parameters: tool/quick-task layer uses `high` (flash family only supports high/max, high call volume, cost control); fallback/special tool slots may keep `medium`; opinion/fusion layer bumps to the model's highest supported tier (minimax/pro/mimo-pro→`max`, qwen-max→`xhigh`, kimi→`high`) to maximize reasoning quality.

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

#### Agent roster (22 agents)

All files live in `.opencode/agents/`. **Copy them from the repo during deployment — do not rewrite them.** The frontmatter and prompts in the repo are the source of truth.

| Agent | File | model | hidden | Description |
|-------|------|-------|--------|-------------|
| residual-extractor | 残差提取.md | model: opencode-go/deepseek-v4-flash | hidden | 提取多方案间的残差信息，识别共识与分歧 |
| tool-handler-mimo | 工具人-mimo.md | model: opencode-go/mimo-v2.5 | hidden | 工具人，MiMo模型保底 |
| tool-handler | 工具人.md | model: opencode-go/deepseek-v4-flash |  | 读代码搜文件调MCP，不给意见 |
| concierge-router | 门童.md | model: opencode-go/deepseek-v4-flash |  | 智能路由引擎，负责任务理解、条件激活与流水线编排 |
| flag-eng | 旗舰·工程.md | model: opencode-go/deepseek-v4-flash | hidden | 大规模实现视角方案 |
| flag-plan | 旗舰·规划.md | model: opencode-go/deepseek-v4-flash | hidden | 结构化方案设计 |
| flag-arch | 旗舰·架构.md | model: opencode-go/qwen3.7-max | hidden | 顶层架构设计 |
| flag-fuse | 旗舰·融合.md | model: opencode-go/kimi-k3 | hidden | 三份架构方案取长补短（残差增强融合） |
| flag-impl | 旗舰·执行.md | model: opencode-go/deepseek-v4-flash | hidden | 按融合方案编码落地 |
| flag-qa | 旗舰·质检.md | model: opencode-go/deepseek-v4-pro | hidden | 对比方案和代码全维度验收（含方案审查 + 学习记录） |
| fe-motion | 前端·动效.md | model: opencode-go/mimo-v2.5-pro | hidden | 前端交互体验与动效方案 |
| fe-restore | 前端·还原.md | model: opencode-go/qwen3.7-plus | hidden | 像素级还原UI设计稿 |
| fe-logic | 前端·逻辑.md | model: opencode-go/qwen3.7-plus | hidden | 前端组件架构与状态管理方案 |
| fe-lead | 前端·总工.md | model: opencode-go/deepseek-v4-flash | hidden | 三份前端方案择优融合（含置信度评分） |
| fusion-fallback | 融合·保底.md | model: opencode-go/deepseek-v4-pro | hidden | 融合层失败保底，对比多份输入输出一份（继承残差融合流程，支持部分输入降级） |
| swift | 闪电侠.md | model: opencode-go/deepseek-v4-flash |  | 快速处理简单零碎任务 |
| vision-translator | 视觉翻译.md | model: opencode-go/qwen3.7-plus |  | 截图/UI图/报错图转文字描述；无截图时降级为复杂内容解构 |
| confidence-assessor | 置信度评估.md | model: opencode-go/deepseek-v4-flash | hidden | 评估 MoA 融合结果的置信度和合规性 |
| mid-creative | 中级·创意.md | model: opencode-go/qwen3.7-plus | hidden | 创意视角方案 |
| mid-eng | 中级·工程.md | model: opencode-go/kimi-k2.6 | hidden | 工程视角方案 |
| mid-coder | 中级·码农.md | model: opencode-go/deepseek-v4-flash | hidden | 实战视角方案 |
| mid-fuse | 中级·融合.md | model: opencode-go/kimi-k2.7-code | hidden | 三份中级方案取长补短（残差增强融合） |

### Block 3: 5 `/moa-*` commands

One file per command in `.opencode/commands/`; copy from the repo during deployment. File names use the `moa-` prefix.

**Self-check**: `Get-ChildItem .opencode/commands/*.md` should count 5, all starting with `moa-`.

| Command | Purpose |
|---------|---------|
| `/moa-quick` | Swift for simple tasks |
| `/moa-frontend` | Frontend chain (restore → logic → motion → lead fusion) |
| `/moa-medium` | Medium chain (3 perspectives → fusion → impl → QA) |
| `/moa-flagship` | Flagship chain (3 perspectives → residual fusion → impl → QA) |
| `/moa-describe` | Explain the MoA configuration and roles |

### Block 4: 3 Skills

3 skills live in `.opencode/skills/`; copy from the repo during deployment.

| Skill | Purpose |
|-------|---------|
| `code-review-moa` | MoA-specific code review |
| `architecture-moa` | MoA architecture review |
| `frontend-moa` | Frontend plan review |
### Block 5: opencode.json

> ⚠️ The provider config block was already added to `opencode.json` by the AI in the Provider section (`apiKey` references an external file via `{file:}`), **do not write it again**.

First read the existing `opencode.json`, merge `permissions.task` rather than overwrite.

> ✅ **`instructions` is omitted**: the JSON below is an exact mirror of the actual `opencode.json` and does not include `instructions`. OpenCode reports a startup warning if it references a non-existent `AGENTS.md`.
>
> - Only add `"instructions": ["AGENTS.md"]` yourself when an `AGENTS.md` **already exists** at the project root.
> - If the project has no `AGENTS.md`, keep it omitted — MoA does not impose a convention file on the project.
> - To use custom project guidance: create your own `AGENTS.md` then add it yourself; no agent change needed.

```jsonc
<!-- SYNC:BLOCK5 start -->
{
  "$schema": "https://opencode.ai/config.json",
  "default_agent": "concierge-router",
  "subagent_depth": 2,
  "permission": {
    "*": "ask",
    "moa-loop_*": "allow",
    "grep": "allow",
    "glob": "allow",
    "list": "allow",
    "bash": {
      "*": "ask",
      "git status *": "allow",
      "git diff *": "allow",
      "git log *": "allow",
      "grep *": "allow",
      "ls *": "allow",
      "cd *": "allow",
      "npm run *": "allow",
      "rg *": "allow",
      "Select-String *": "allow",
      "Get-ChildItem *": "allow",
      "Get-Content *": "allow",
      "pwsh .opencode/tests/*": "allow",
      "rm *": "ask",
      "del *": "ask",
      "Remove-Item *": "ask",
      "rd *": "ask",
      "rmdir *": "ask"
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
    },
    "todowrite": "allow"
  },
  "agent": {
    "mid-eng": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    },
    "mid-creative": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    },
    "mid-coder": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    },
    "mid-fuse": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    },
    "flag-arch": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    },
    "flag-plan": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    },
    "flag-eng": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    },
    "flag-fuse": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    },
    "flag-impl": {
      "permission": {
        "*_*": "deny",
        "moa-loop_*": "allow"
      }
    },
    "flag-qa": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    },
    "fe-logic": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    },
    "fe-motion": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    },
    "fe-lead": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    },
    "fusion-fallback": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    },
    "residual-extractor": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    },
    "confidence-assessor": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    }
  },
  "compaction": {
    "auto": true,
    "reserved": 15000
  },
  "mcp": {
    "moa-loop": {
      "type": "local",
      "command": ["node","longloop/server.js"],
      "enabled": true
    }
  },
  "share": "manual",
  "snapshot": true
}
<!-- SYNC:BLOCK5 end -->
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
Check "task: x11 (got $task)" ($task -eq 11)

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

Expected: `reasoningEffort` appears 22 times (all agents), `task:` appears 11 times (concierge-router + 2 tool-handlers + 8 opinion layers), `moa-` command filenames match 5.

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

Expected same as above. If `Select-String` count is high, it's because `task:` appears in both the concierge-router, tool-handlers and opinion-layer frontmatter — normal, total is 11 (concierge-router 1 + 2 tool-handlers + 8 opinion layers each 1).

### Block 7: .moa/界线.json

> When auto-deploying with AI, skip if the file already exists. Content below is synced by `scripts/sync-docs.ps1` from `.moa/界线.json` — do not edit by hand.

`.moa/界线.json`:

```json
<!-- SYNC:MOA_BOUNDARIES start -->
{
  "$schema": "acceptance-criteria",
  "_description": "界线：融合层输出后写入此文件，后续只能追加 bonus 项。",
  "_usage": "旗舰·融合/中级·融合/融合·保底 输出时，将 ---验收标准--- 节内容写入此文件；执行层将进度写入 .moa/足迹.md，未决事项写入 .moa/拦路虎.md",
  "_rules": [
    "输出后冻结，不可修改基础条件",
    "只能追加bonus项",
    "旗舰·质检经 task(工具人) 独立复跑验证——执行者贴的输出不算数",
    "基线值必须标注",
    "暗卷项执行者不可见",
    "完成条件必须含至少 1 条 result 型（度量结果）+ 1 条 constraint 型（守约束）",
    "探索型任务的结论每条须带来源与日期，或可复跑的步骤"
  ],
  "taskId": "",
  "frozenAt": "",
  "pipeline": "旗舰链|中级链|前端链",
  "taskType": "执行型|探索型",

  "priorityOrder": "要求冲突时的让步顺序，如「算得对 > 做得全 > 做得快」",

  "whitelist": [
    "只允许修改的路径（白名单为主，红线兜底）"
  ],

  "decisionLog": [
    {
      "_description": "分歧裁决记录：残差报告的未决分歧",
      "issue": "分歧点",
      "default": "默认值（猜的）",
      "costIfWrong": "猜错的代价",
      "askUser": false
    }
  ],

  "criteria": [
    {
      "name": "验收项名称",
      "command": "可机器判定的验收命令",
      "baseline": "基线值（如 all pass / ≥80% / =3）",
      "type": "test|lint|build|custom",
      "metricType": "result|constraint"
    }
  ],

  "bonuses": [],

  "hiddenCriteria": [
    {
      "_description": "暗卷：执行者不可见的抽查项，管理者自留",
      "name": "抽查项名称",
      "command": "抽查命令",
      "baseline": "基线值",
      "visible": false
    }
  ],

  "notList": [
    "明确排除的范围（不改X、不碰Y、不加Z）"
  ],

  "exploreMode": {
    "_description": "探索型任务专属规格：taskType=探索型 时启用，执行型忽略",
    "conclusionLimit": "结论条数上限，宁收2条实的，不收10条凑的",
    "budget": "可承受损失（时间/来源数上限），烧完即交卷",
    "sourceRequired": "每条结论附来源+日期，或可复跑步骤",
    "deadEndIsPass": "此路不通=合格交付（带死因证据+原始输出）"
  },

  "antiCheating": {
    "_description": "红线·防作弊：反作弊机制，防止执行者作弊达标",
    "baselineNonRegression": {
      "testCount": "≥基线",
      "coverage": "≥基线",
      "skipped": 0
    },
    "forbiddenActions": [
      "skip/todo 跳过测试",
      "放松断言条件",
      "mock 被测对象",
      "删除测试",
      "|| true 吞失败",
      "改阈值或验收脚本"
    ],
    "mutationTest": {
      "_description": "验真试验（变异测试）：故意弄坏一次证明检查真的会报警。凡「坏了没人会知道」的检查都要这一步——贴变红输出，还原后贴全绿。检查失灵=验收全假，比 TDD 更关键（TDD 保证测试先于实现，验真保证检查不是摆设）",
      "required": true,
      "steps": [
        "挑一个验收命令，故意破坏对应实现（如删函数/改常量/跳过分支）",
        "重跑验收命令，必须变红（报警）",
        "还原破坏，重跑必须全绿",
        "把两次输出贴进足迹.md 的验证节"
      ]
    },
    "implementationDiffCheck": {
      "_description": "补测试类任务专用：实现目录 git diff 为空",
      "enabled": false,
      "path": "实现目录"
    }
  },

  "stopLoss": {
    "_description": "止损机制：连败换项，基线退化回滚",
    "maxRetriesPerItem": 3,
    "rollbackOnRegression": true,
    "maxTotalRounds": 10,
    "reportOnStop": "如实汇报卡在哪、还差什么"
  },

  "progressTracking": {
    "_description": "足迹机制：执行层开工前写 ≤10 行开工回执（理解的目标/顺序/最大风险），每完成一项立即更新 .moa/足迹.md；拿不准/受阻写 .moa/拦路虎.md 后跳过继续；收不回的操作停下写 .moa/拦路虎.md 做别的；交付时待裁决随交付提交（空则写「无」）"
  },

  "deliveryRequirements": {
    "_description": "交付要求：必须贴实际输出，只说做完了不算",
    "mustPasteCommandOutput": true,
    "mustIncludeReverseVerification": true
  },

  "status": "frozen|passed|failed",
  "verificationLog": []
}
<!-- SYNC:MOA_BOUNDARIES end -->
```

### Block 7.1: .moa/足迹模板.md (runtime file template)

> When auto-deploying with AI, skip if the file already exists. Content below is synced by `scripts/sync-docs.ps1` from `.moa/足迹模板.md` — do not edit by hand.

`.moa/足迹模板.md`:

```markdown
<!-- SYNC:MOA_FOOTPRINT start -->
# 足迹

> 运行时文件：旗舰·执行 开工前写开工回执，每完成一项立即更新。
> 格式参考本模板，直接改内容即可。交付时随 .moa/拦路虎.md 一起提交。

## 开工回执（≤10 行）

- 理解的目标：
- 执行顺序：
- 最大风险：

## 进度

| 步骤 | 状态 | 说明 |
|------|------|------|
| 任务0 核验 | 待开始 | 关键命令实测结果： |
| 步骤1 | 待开始 |  |
| 步骤2 | 待开始 |  |

## 记录

（每一步完成后在这里写一句：做了什么 / 结果 / 偏差原因）

## 断点恢复

> 会话中断/续跑时：先读完本文件 + 状态文件再动手，第一句话先复述「做到哪了」，禁止凭记忆续写。

- 上一次做到：
- 下一步动作：
- 未完成的原因：
<!-- SYNC:MOA_FOOTPRINT end -->
```

### Block 7.2: .moa/拦路虎模板.md (runtime file template)

> When auto-deploying with AI, skip if the file already exists. Content below is synced by `scripts/sync-docs.ps1` from `.moa/拦路虎模板.md` — do not edit by hand.

`.moa/拦路虎模板.md`:

```markdown
<!-- SYNC:MOA_BLOCKER start -->
# 拦路虎

> 运行时文件：旗舰·执行 拿不准/受阻/收不回的操作时写入，写完跳过继续做别的。
> 交付时随足迹一起提交；空文件也提交，写「无」。

## 拦路虎清单

- [ ] 问题：默认值（猜的）｜猜错代价
  背景：
  证据：

## 已裁决记录

（质检/用户裁决后移到这里：问题 → 裁决 → 依据）
<!-- SYNC:MOA_BLOCKER end -->
```

> **Deployment complete**: after all the above verifications pass, **restart opencode to apply all config**.

### How to tell deployment succeeded

1. After restarting OpenCode, press `Tab` to cycle agents (Windows desktop client: `Ctrl+.` also works) and see "concierge-router"
2. Type `@tool-handler` and it responds (if no response, check whether the key in `.opencode/local/opencode-go.key` is correct)
3. Run the verification script: `pwsh .opencode/tests/T0-static-verify.ps1`, expected all PASS (FAIL=0)

### One-click rollback

```bash
rm -rf your-project/.opencode/
rm -rf your-project/.moa/
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

> **Doc version**: v0.0.17 | **Corresponding opencode**: >= 1.3.4 (agent-level reasoningEffort/hidden/task support; `@ai-sdk/openai-compatible` transparently passes reasoning, no `forceReasoning` needed)


















