---
name: opencode-moa
description: 19-agent Cost-Optimal MoA configuration. Cost-efficient models act as tool agents, mid-tier models give opinions, flagship models fuse. One-shot deploy, can be deleted afterward.
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

All 19 agents use **`opencode-go/<model-id>`** (the official Go model ID format). Sub-agents resolve this prefix through the provider registry. **You must have an `opencode-go` provider with credentials** (otherwise the built-in `opencode` provider has no key and silently downgrades to `public`, Go paid models get disabled → `OpenCode Go provider error` / `Upstream request failed`).

Two authentication methods, choose one:

> **AI deployment instruction (choose one required)**
>
> **Method A (recommended, AI writes directly):**
>
> 1. Ask the user: "Please enter your OpenCode Go API Key (created at opencode.ai/auth)."
> 2. Add the provider config block below to the project `opencode.json`, filling the key directly into the `apiKey` field.
> 3. Confirm completion and tell the user to restart OpenCode.
>
> **Method B (placeholder, no key over chat):**
>
> 1. Add the provider config block below to the project `opencode.json`, with the `apiKey` field set to `<YOUR_GO_API_KEY>` (placeholder).
> 2. Tell the user: open `opencode.json`, replace `<YOUR_GO_API_KEY>` with your real key created at opencode.ai/auth, save and restart OpenCode.
> 3. The key never goes through chat; the user does it locally.
>
> **This step cannot be skipped.** Otherwise all 19 agents fail silently.

---

**Method A (recommended, project-level by default): write the key directly in the config**

**Written to the project `opencode.json` by default** — a self-contained deployment: provider + key both live inside the project, so even if the system-level directory is deleted/empty it has no effect; `apiKey` references a separate key file via `{file:}` (`.opencode/local/opencode-go.key`, excluded by `.gitignore`, not committed). Only switch to the system-level config (outside the repo; real paths per platform below under "System-level paths") when you want to **share one key across multiple projects**.

> ⚠️ **`forceReasoning` is only needed for `@ai-sdk/openai` — this project defaults to `@ai-sdk/openai-compatible`, do not add it**: the reasoning passthrough regression in opencode >= 1.3.4 ([issue #20815](https://github.com/anomalyco/opencode/issues/20815)) **only affects custom providers with `"npm": "@ai-sdk/openai"`** (AI SDK v6 validates against a "known reasoning model list", and silently drops `reasoningEffort` if not in it). This issue is confirmed to **not affect `@ai-sdk/openai-compatible`** — `reasoningEffort` passes through correctly as `reasoning_effort`. This project's provider uses `openai-compatible`, so **no `forceReasoning` is needed or should be added** (adding it is a no-op and misleads later readers into thinking it's required). Only when you change `npm` to `@ai-sdk/openai` (e.g. to use the responses API) must you add `forceReasoning: true` in `options` (only needed at >=1.3.4; lower versions ignore the field).

**System-level paths (recognized on all platforms, but the spelling differs):**

| Platform        | Real path                                          | Equivalent `~` spelling                              |
| --------------- | -------------------------------------------------- | ---------------------------------------------------- |
| Linux / macOS   | `~/.config/opencode/opencode.json`                 | same as left                                         |
| Windows         | `C:\Users\<you>\.config\opencode\opencode.json`    | `%USERPROFILE%\.config\opencode\opencode.json`       |

> 🔴 **Debunking:** many third-party docs write the Windows path as `%APPDATA%\opencode\` (e.g. some MCP plugin READMEs). **That is wrong** — OpenCode on Windows uses `%USERPROFILE%\.config\opencode`, not `%APPDATA%\opencode`. Putting the config at the wrong path leads to "deployment succeeds but all agents can't connect" with no obvious error.

> 🔴 **Same-directory dual-file warning**: OpenCode officially supports **both `.json` and `.jsonc`** formats, but **leaving both `opencode.json` and `opencode.jsonc` in the same directory has undefined priority** — the official config docs only say "both formats supported" and list the global path as `opencode.json`, without specifying which wins in a same-directory dual-file situation. The two files may also conflict (e.g. one enables a provider, the other disables it). **Safe practice: keep only one file per directory**, and make the kept one contain a valid `opencode-go` provider + real key; don't rely on "both present" as a fallback.

> 🔴 **`apiKey` cannot be a placeholder / empty**: writing `<YOUR_GO_API_KEY>`, an empty string, or omitting it makes deployment look complete but at runtime all 19 agents return 401/403 `Upstream request failed`. Both this project's hard gate and T0 will block this.

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
- `@工具人` responds normally.
- `pwsh .opencode/tests/T0-static-verify.ps1` → all PASS (with system-level key, WARN also counts as pass, FAIL=0).

> ⚠️ The file containing the real key (`.opencode/local/opencode-go.key`) is not tracked by git (`*.key` and `.opencode/local/` are excluded by `.gitignore`). The system-level `~/.config/opencode/` is outside the repo.

---

### Error fallback

If neither `/connect` nor the config file set up the `opencode-go` provider, tool-layer calls will report `Upstream request failed`:

```
工具人 (opencode-go/deepseek-v4-flash) failed
  → auto retry once
  → still fails → ask user:
    A. configure provider then retry
    B. skip tool layer, give solution directly (higher cost, no code material)
    C. switch to free model (/models, pick a Free model)
```

This fallback chain is already implemented in the doorman router's prompt. Execution continues only after the user chooses — it never silently routes past the ask.

---

By default opencode uses a single model from start to finish. Changing one character and designing a system architecture use the same prompt, same temperature, same context. No division of labor.

This package deploys a **doorman + 18 specialized agents** Cost-Optimal MoA architecture. The core design principle is just one line:

> **Use flash and MiMo for grunt work, mid-tier for opinions, flagship for fusion.** Each model only does what it does best; never waste a single call.

### Cost tiers

```
Monthly quota comparison (OpenCode Go plan $10/month):
  DeepSeek V4 Flash   158,000 calls → tool layer (use freely)
  MiMo-V2.5           150,400 calls → tool layer (use freely)
  ─── above are the tool agents, ~80% of call volume ───
  MiniMax M3           16,000 calls
  DeepSeek V4 Pro      17,150 calls
  Qwen3.7 Plus         21,600 calls
  ─── above are mid-tier opinion models, ~18% ───
  Kimi K2.7 Code        9,250 calls
  Qwen3.7 Max           4,770 calls
  GLM-5.2               4,300 calls
  ─── above are flagship fusion models, ~2% ───
```

### How to use

**Method 1: just state the need (recommended)**

> Help me write a Markdown-to-HTML function

The doorman automatically: judges complexity → dispatches the tool agent to gather context → 3 mid-tier opinions in parallel → flagship fusion → flash implementation → pro QA. No agent switching, no model selection needed.

**Method 2: command-specified flow**

| Command            | Scenario                          | Who does the work                |
| ------------------ | --------------------------------- | -------------------------------- |
| `/moa-quick`       | config change, translation, simple query | @闪电侠                       |
| `/moa-medium`      | function module, bug fix, single-file refactor | 工程 + 创意 + 码农 → 融合  |
| `/moa-flagship`    | system architecture, large refactor | 3 flagship opinions → fuse → implement → QA |
| `/moa-frontend`    | UI restore, CSS, screenshot fix   | 还原 + 逻辑 + 动效 → 总工        |
| `/moa-describe`    | screenshot/image to text          | 视觉翻译官                        |

**Method 3: `@` invoke (usable independently)**

Type `@` and pick an agent to talk directly. Each agent can be used independently:

- `@工具人` / `@视觉翻译官` → read files / screenshots directly
- `@中级·工程` → asks whether to gather material first; if you say "yes" it auto-calls the tool agent
- `@中级·融合` → you give it the three solutions directly, it fuses and outputs (if you don't have three, it prompts you to use the doorman)

### Fallback chain

```
工具人 (Flash) failed → immediate retry once
  → retry succeeds → return normally
  → retry fails → 工具人-mimo (MiMo) failed → immediate retry once
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

> ⚠️ **Pre-check**: before starting deployment, confirm you have completed the key setup in the **"Provider configuration"** section above (the system-level `~/.config/opencode/opencode.json` has registered `provider.opencode-go` with a valid key). OpenCode only loads the project-level `opencode.json` and the system-level `~/.config/opencode/opencode.json`, **not `user_config.json`**. If you haven't configured it, go back and do it first, otherwise the 19 agents will all fail to connect after deployment.

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

> 🔴 **Provider hard gate (must check after deploy)**: after file deployment, you must assert that **either the project `opencode.json` or the system-level `~/.config/opencode/opencode.json` (one per directory, keep only one)** contains `provider.opencode-go` and `apiKey` is a **real key** (neither the `<YOUR_GO_API_KEY>` placeholder, nor empty/missing). If not satisfied, the AI **must re-run the Provider step above to rebuild the provider** and must not announce "deployment successful" — otherwise it produces an empty shell of "complete files but all 19 agents can't connect".

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

Mitigation: set `hidden: true` for agents that **are only orchestrated by the doorman via the Task tool and the user almost never types `@` to call**. This field **only hides the `@` menu item, it does not block Task calls** (the doorman calls them via Task), so the fusion chain behavior is unaffected.

**The 9 orchestration-layer agents set to `hidden: true`:**

- 旗舰·架构 / 旗舰·规划 / 旗舰·工程 / 旗舰·融合 / 旗舰·实现 / 旗舰·质检 (flagship fusion chain, all doorman-driven)
- 中级·融合, 前端·总工 (fusion layer, doorman-driven)
- 工具人-mimo (tool agent fallback, doorman retry-chain driven)

**Kept visible (users often `@` them):** 工具人, 视觉翻译官, 闪电侠, 中级·创意, 中级·工程, 中级·码农, 前端·还原, 前端·逻辑, 前端·动效, plus built-in explore / general. If still slightly over the cap, you can also hide 中级·融合 / 前端·总工 (they go through the doorman anyway).

> `hidden` only takes effect on `mode: subagent`; the primary agent (doorman router) is not in the `@` menu and needs no setting.

### Block 2: 19 Agent files

All agents are written to `.opencode/agents/`. Check existing files in the directory before writing to avoid overwriting same-named files.

Write order:

1. 门童路由员 (primary)
2. 工具人 → 工具人-mimo → 闪电侠 → 视觉翻译官
3. 中级·工程 → 中级·创意 → 中级·码农 → 中级·融合
4. 旗舰·架构 → 旗舰·规划 → 旗舰·工程 → 旗舰·融合 → 旗舰·实现 → 旗舰·质检
5. 前端·还原 → 前端·逻辑 → 前端·动效 → 前端·总工

**Self-check**: `Get-ChildItem .opencode/agents/*.md` count should be 19.

#### 门童路由员

`.opencode/agents/门童路由员.md`:

```markdown
---
description: 路由分发入口，不产生任何代码/方案
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
    "工具人": allow
    "工具人-mimo": allow
    "闪电侠": allow
    "视觉翻译官": allow
    "中级·工程": allow
    "中级·创意": allow
    "中级·码农": allow
    "中级·融合": allow
    "旗舰·架构": allow
    "旗舰·规划": allow
    "旗舰·工程": allow
    "旗舰·融合": allow
    "旗舰·实现": allow
    "旗舰·质检": allow
    "前端·还原": allow
    "前端·逻辑": allow
    "前端·动效": allow
    "前端·总工": allow
---

接收请求 → task(@工具人) 探测工具层可用性
  → 成功 → 继续执行正常路由流程
  → 失败 → task(@工具人-mimo)
    → 成功 → 继续执行正常路由流程
    → 失败 → 停止执行，ask 用户：

      "工具层暂时不可用（flash和MiMo都连不上）。

       A. 等几分钟再试
       B. 跳过工具层，直接调意见层（成本较高，约提高3到10倍）
       C. 切换到免费模型处理

       ⚠️ 免费模型限制：
       - 上下文窗口较小，复杂项目可能丢失信息
       - 响应可能较慢，可能需要重试
       - 限时免费，后续可能收费

        提示：选 C 需要手动操作——用 `/models` 打开模型列表选免费模型（Win 桌面端亦可用 `Ctrl+'`），然后直接输入需求。"

      → 用户选 A → 30秒后重试工具人
      → 用户选 B → 调用意见层（不传材料，意见层出方案）
      → 用户选 C → 门童输出操作指引

      ⚠️ 重要：当工具层失败时，必须停止执行后续流程，等待用户选择后再继续。不要跳过ask直接执行正常路由流程。

正常路由流程：
小 → @闪电侠
上下文 → @工具人，量大并行 @工具人-mimo
截图 → +@视觉翻译官
中 → @工具人 → 并行 @中级·工程 @中级·创意 @中级·码农 → @中级·融合
大 → @工具人 → 并行 @旗舰·架构 @旗舰·规划 @旗舰·工程 → @旗舰·融合 → @旗舰·实现 → @旗舰·质检
界面 → 并行 @前端·还原 @前端·逻辑 @前端·动效 → @前端·总工

最终结果（融合层输出）转发给用户。中间结果不暴露。
某 agent 失败/超时 → 跳过，用已返回的结果继续。全部失败 → STUCK: 无法路由
STUCK → 提示用户按 `Tab` 切换 plan agent（Win 桌面端亦可用 `Ctrl+.`）
```

#### 工具人

`.opencode/agents/工具人.md`:

```markdown
---
description: 读代码搜文件调MCP，不给意见
mode: subagent
model: opencode-go/deepseek-v4-flash
temperature: 0.1
reasoningEffort: medium
max_tokens: 2048
permission:
  edit: deny
  bash: deny
---

只执行读取/搜索任务。返回文件路径+原文或摘要。不做分析不给方案。

失败 → 立即重试1次
  → 重试成功 → 正常返回结果
  → 重试失败 → 输出 ERROR类别: 原因，然后终止
    ERROR_PROVIDER: provider返回502/503/timeout（连接瞬断）
    ERROR_AUTH: 认证失败
    ERROR_UNKNOWN: 其他错误
```

#### 工具人-mimo

`.opencode/agents/工具人-mimo.md`:

```markdown
---
description: 工具人，MiMo模型保底
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

只执行读取/搜索任务。返回文件路径+原文或摘要。不做分析不给方案。

失败 → 立即重试1次
  → 重试成功 → 正常返回结果
  → 重试失败 → 输出 ERROR类别: 原因，然后终止
    ERROR_PROVIDER: provider返回502/503/timeout（连接瞬断）
    ERROR_AUTH: 认证失败
    ERROR_UNKNOWN: 其他错误
```

#### 闪电侠

`.opencode/agents/闪电侠.md`:

```markdown
---
description: 快速处理简单零碎任务
mode: subagent
model: opencode-go/deepseek-v4-flash
temperature: 0.2
reasoningEffort: medium
max_tokens: 2048
permission:
  edit: allow
  bash: allow
---

专攻简单明确的小任务。直接出结果，不加开场白不改废话。

超能力范围 → ESCALATE:
失败 → 立即重试1次
  → 重试成功 → 正常返回
  → 重试失败 → 卡住 → STUCK: 说明原因
```

#### 视觉翻译官

`.opencode/agents/视觉翻译官.md`:

```markdown
---
description: 截图/UI图/报错图转文字描述
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

截图转精确文字描述：
1. 整体布局
2. 各区域内容
3. 颜色风格、间距
4. 报错：完整错误+堆栈
5. 代码截图：逐行还原

失败 → 立即重试1次
  → 重试成功 → 正常返回
  → 重试失败 → 卡住 → STUCK: 说明原因
```

#### 中级·工程

`.opencode/agents/中级·工程.md`:

```markdown
---
description: 工程视角方案
mode: subagent
model: opencode-go/minimax-m3
temperature: 0.4
reasoningEffort: max
max_tokens: 8192
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
  task:
    "工具人": allow
    "视觉翻译官": allow
---

你是 MoA 三意见之一（工程视角）。基于材料出方案。工程化、可维护、防御式编程。

被 @ 直接调用且无上下文时：ask 用户是否先搜集材料。
是 → task(@工具人) 获取材料 → 出方案
否 → 直接出方案

被调用时如果没有材料（工具层失败的情况）：
  → ask 用户："没有收到材料，要我直接出方案还是等工具层恢复？"
  → 用户选直接出 → 基于需求描述出方案（不读代码，不调MCP，纯逻辑推演）
  → 用户选等待 → 输出 "WAITING: 等待工具层恢复"

---记忆层---
（核心思路+关键决策）
---方案---
```

#### 中级·创意

`.opencode/agents/中级·创意.md`:

```markdown
---
description: 创意视角方案
mode: subagent
model: opencode-go/deepseek-v4-pro
temperature: 0.5
reasoningEffort: medium
max_tokens: 8192
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
  task:
    "工具人": allow
    "视觉翻译官": allow
---

你是 MoA 三意见之一（创意视角）。故意和工程视角不同。思路新颖、差异化设计。

被 @ 直接调用且无上下文时：ask 用户是否先搜集材料。
是 → task(@工具人) 获取材料 → 出方案
否 → 直接出方案

被调用时如果没有材料（工具层失败的情况）：
  → ask 用户："没有收到材料，要我直接出方案还是等工具层恢复？"
  → 用户选直接出 → 基于需求描述出方案（不读代码，不调MCP，纯逻辑推演）
  → 用户选等待 → 输出 "WAITING: 等待工具层恢复"

---记忆层---
（与工程方案的差异+独特优势）
---方案---
```

#### 中级·码农

`.opencode/agents/中级·码农.md`:

```markdown
---
description: 实战视角方案
mode: subagent
model: opencode-go/deepseek-v4-flash
temperature: 0.3
reasoningEffort: medium
max_tokens: 8192
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
  task:
    "工具人": allow
    "视觉翻译官": allow
---

你是 MoA 三意见之一（码农视角）。最快最直接。工程/创意过度设计时给出更简替代方案。

被 @ 直接调用且无上下文时：ask 用户是否先搜集材料。
是 → task(@工具人) 获取材料 → 出方案
否 → 直接出方案

---记忆层---
（与另两方案的核心差异）
---方案---
```

#### 中级·融合

`.opencode/agents/中级·融合.md`:

```markdown
---
description: 三份方案取长补短输出一份
mode: subagent
hidden: true
model: opencode-go/kimi-k2.7-code
temperature: 0.3
reasoningEffort: high
max_tokens: 8192
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
---

对比工程、创意、码农三份方案。共识保留、分歧取优、差异融合。只交一份。

简述融合决策
---方案---
融合后完整代码
```

#### 旗舰·架构

`.opencode/agents/旗舰·架构.md`:

```markdown
---
description: 顶层架构设计
mode: subagent
hidden: true
model: opencode-go/qwen3.7-max
temperature: 0.4
reasoningEffort: xhigh
max_tokens: 8192
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
  task:
    "工具人": allow
    "视觉翻译官": allow
---

你是旗舰三重意见之一（架构）。只出方案不改文件。

被 @ 直接调用且无上下文时：ask 用户是否先搜集材料。
是 → task(@工具人) 获取材料 → 出方案
否 → 直接出方案

被调用时如果没有材料（工具层失败的情况）：
  → ask 用户："没有收到材料，要我直接出方案还是等工具层恢复？"
  → 用户选直接出 → 基于需求描述出方案（不读代码，不调MCP，纯逻辑推演）
  → 用户选等待 → 输出 "WAITING: 等待工具层恢复"

---架构设计---
核心决策(≤5) | 技术选型+理由 | 模块划分+数据流 | 接口定义 | 风险+mitigation
```

#### 旗舰·规划

`.opencode/agents/旗舰·规划.md`:

```markdown
---
description: 结构化方案设计
mode: subagent
hidden: true
model: opencode-go/glm-5.2
temperature: 0.4
reasoningEffort: max
max_tokens: 8192
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
  task:
    "工具人": allow
    "视觉翻译官": allow
---

你是旗舰三重意见之一（规划）。配额有限仅用于极复杂场景。

被 @ 直接调用且无上下文时：ask 用户是否先搜集材料。
是 → task(@工具人) 获取材料 → 出方案
否 → 直接出方案

被调用时如果没有材料（工具层失败的情况）：
  → ask 用户："没有收到材料，要我直接出方案还是等工具层恢复？"
  → 用户选直接出 → 基于需求描述出方案（不读代码，不调MCP，纯逻辑推演）
  → 用户选等待 → 输出 "WAITING: 等待工具层恢复"

---规划方案---
问题域分析 | 方案结构 | 实施路径 | 风险与应对
```

#### 旗舰·工程

`.opencode/agents/旗舰·工程.md`:

```markdown
---
description: 大规模实现视角方案
mode: subagent
hidden: true
model: opencode-go/minimax-m3
temperature: 0.5
reasoningEffort: max
max_tokens: 8192
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
  task:
    "工具人": allow
    "视觉翻译官": allow
---

你是旗舰三重意见之一（工程）。多模块接口一致性、性能与开销、可观测性。

被 @ 直接调用且无上下文时：ask 用户是否先搜集材料。
是 → task(@工具人) 获取材料 → 出方案
否 → 直接出方案

被调用时如果没有材料（工具层失败的情况）：
  → ask 用户："没有收到材料，要我直接出方案还是等工具层恢复？"
  → 用户选直接出 → 基于需求描述出方案（不读代码，不调MCP，纯逻辑推演）
  → 用户选等待 → 输出 "WAITING: 等待工具层恢复"

---工程方案---
实现要点 | 模块划分+接口 | 性能与容量 | 可观测性
```

#### 旗舰·融合

`.opencode/agents/旗舰·融合.md`:

```markdown
---
description: 三份架构方案取长补短
mode: subagent
hidden: true
model: opencode-go/kimi-k2.7-code
temperature: 0.3
reasoningEffort: high
max_tokens: 8192
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
---

对比架构、规划、工程三份方案。共识保留、分歧注明、差异融合。只交一份。

简述融合决策理由
---融合方案---
```

#### 旗舰·实现

`.opencode/agents/旗舰·实现.md`:

```markdown
---
description: 按融合方案编码落地
mode: subagent
hidden: true
model: opencode-go/deepseek-v4-flash
temperature: 0.2
reasoningEffort: medium
max_tokens: 8192
permission:
  edit: allow
  bash: allow
---

按融合方案编码。不改接口签名。方案歧义时汇报，不自作主张。

失败 → 立即重试1次
  → 重试成功 → 正常返回
  → 重试失败 → 卡住 → STUCK: 说明原因

---实现说明---
（范围+关键决策）
---代码---
```

#### 旗舰·质检

`.opencode/agents/旗舰·质检.md`:

```markdown
---
description: 对比方案和代码全维度验收
mode: subagent
hidden: true
model: opencode-go/deepseek-v4-pro
temperature: 0.2
reasoningEffort: max
max_tokens: 8192
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
---

对比方案和代码。不输出代码。打回时指明具体问题。

失败 → 立即重试1次
  → 重试成功 → 正常返回
  → 重试失败 → 卡住 → STUCK: 说明原因

通过 / 有条件通过 / 打回
```

#### 前端·还原

`.opencode/agents/前端·还原.md`:

```markdown
---
description: 像素级还原UI设计稿
mode: subagent
model: opencode-go/mimo-v2.5
temperature: 0.3
reasoningEffort: medium
max_tokens: 8192
permission:
  edit: allow
  bash: allow
---

严格按布局、颜色、文字精确还原UI。组件化、响应式。输出完整代码。
```

#### 前端·逻辑

`.opencode/agents/前端·逻辑.md`:

```markdown
---
description: 前端组件架构与状态管理方案
mode: subagent
model: opencode-go/qwen3.7-plus
temperature: 0.4
reasoningEffort: medium
max_tokens: 8192
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
  task:
    "工具人": allow
    "视觉翻译官": allow
---

你是前端 MoA 三意见之一（逻辑）。组件架构、TS类型、状态管理、API接口。

被 @ 直接调用且无上下文时：ask 用户是否先搜集材料。
是 → task(@工具人) 获取材料 → 出方案
否 → 直接出方案

被调用时如果没有材料（工具层失败的情况）：
  → ask 用户："没有收到材料，要我直接出方案还是等工具层恢复？"
  → 用户选直接出 → 基于需求描述出方案（不读代码，不调MCP，纯逻辑推演）
  → 用户选等待 → 输出 "WAITING: 等待工具层恢复"

---逻辑方案---
组件树+职责 | 类型定义 | 状态管理层 | API接口层
```

#### 前端·动效

`.opencode/agents/前端·动效.md`:

```markdown
---
description: 前端交互体验与动效方案
mode: subagent
model: opencode-go/mimo-v2.5-pro
temperature: 0.5
reasoningEffort: max
max_tokens: 8192
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
  task:
    "工具人": allow
    "视觉翻译官": allow
---

你是前端 MoA 三意见之一（动效）。在还原基础上加过渡动画和微交互。组件划分与还原/逻辑差异化。

被 @ 直接调用且无上下文时：ask 用户是否先搜集材料。
是 → task(@工具人) 获取材料 → 出方案
否 → 直接出方案

被调用时如果没有材料（工具层失败的情况）：
  → ask 用户："没有收到材料，要我直接出方案还是等工具层恢复？"
  → 用户选直接出 → 基于需求描述出方案（不读代码，不调MCP，纯逻辑推演）
  → 用户选等待 → 输出 "WAITING: 等待工具层恢复"
```

#### 前端·总工

`.opencode/agents/前端·总工.md`:

```markdown
---
description: 三份前端方案择优融合
mode: subagent
hidden: true
model: opencode-go/kimi-k2.7-code
temperature: 0.3
reasoningEffort: high
max_tokens: 8192
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
---

对比还原、逻辑、动效三份代码。选最优或融合。不得模棱两可。三份都有缺陷→出修正版。

评分(布局/代码质量/交互/视觉/TS) | 对比结论 | ---最终代码---
```

---

### Block 3: 5 `/moa-*` commands

One file per command in `.opencode/commands/`. File names share the `moa-` prefix.

**Self-check**: `Get-ChildItem .opencode/commands/*.md` count should be 5, all starting with `moa-`.

```markdown
# moa-quick.md
---
description: 简单零碎任务一步到位
---
@闪电侠 处理以下需求：
$ARGUMENTS
```

```markdown
# moa-frontend.md
---
description: 前端三重 MoA——还原 + 逻辑 + 动效 → 总工择优
---
执行前端三重 MoA 处理以下需求：
$ARGUMENTS
流程：
1. 涉及截图则先 @视觉翻译官
2. @前端·还原 + @前端·逻辑 + @前端·动效 并行出方案
3. @前端·总工 择优融合
```

```markdown
# moa-Medium.md
---
description: 中级三重 MoA——3 意见并行 + 1 融合
---
执行中级三重 MoA 处理以下需求：
$ARGUMENTS
流程：
1. @工具人 + @视觉翻译官 搜集材料
2. @中级·工程 + @中级·创意 + @中级·码农 并行出方案
3. @中级·融合 融合输出
```

```markdown
# moa-flagship.md
---
description: 旗舰三重 MoA——3 架构意见 + 融合 + 实现 + 质检
---
执行旗舰三重 MoA 处理以下需求：
$ARGUMENTS
流程：
1. @工具人 + @视觉翻译官 搜集材料
2. @旗舰·架构 + @旗舰·规划 + @旗舰·工程 并行出架构方案
3. @旗舰·融合 融合
4. （按需求）@旗舰·实现 编码
5. @旗舰·质检 验收
```

```markdown
# moa-describe.md
---
description: 截图/图片转文字描述
---
@视觉翻译官 分析以下内容：
$ARGUMENTS
```

---

### Block 4: 3 Skills

One directory per skill, with a `SKILL.md` inside.

**Self-check**: `Get-ChildItem .opencode/skills/*/SKILL.md` count should be 3.

```markdown
# code-review-moa
---
description: 中级 MoA 代码评审——双意见 + 融合
---
<flow>
1. task(@工具人) 读代码
2. task(@中级·工程) + task(@中级·创意) 并行出评审意见
3. task(@中级·融合) 融合
</flow>
<rules>
- 单模块/函数级别
- 输出：融合理由 + 完整代码
</rules>
```

```markdown
# architecture-moa
---
description: 旗舰 MoA——三重架构意见 → 融合 → 实现 → 质检
---
<flow>
1. task(@工具人) + task(@视觉翻译官) 搜集材料
2. task(@旗舰·架构) + task(@旗舰·规划) + task(@旗舰·工程) 并行
3. task(@旗舰·融合) 融合
4. task(@旗舰·实现) 编码
5. task(@旗舰·质检) 验收
</flow>
<rules>
- 系统架构或多模块设计
- 输出：质检报告
</rules>
```

```markdown
# frontend-moa
---
description: 前端三重 MoA——还原 + 逻辑 + 动效 → 总工择优
---
<flow>
1. 有截图则 task(@视觉翻译官)
2. task(@前端·还原) + task(@前端·逻辑) + task(@前端·动效) 并行
3. task(@前端·总工) 择优融合
</flow>
<rules>
- UI 实现、截图还原、CSS 修复
- 输出：对比结论 + 最终代码
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
  "default_agent": "门童路由员",
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
      "工具人": "allow",
      "工具人-mimo": "allow",
      "闪电侠": "allow",
      "视觉翻译官": "allow",
      "中级·工程": "allow",
      "中级·创意": "allow",
      "中级·码农": "allow",
      "中级·融合": "allow",
      "旗舰·架构": "allow",
      "旗舰·规划": "allow",
      "旗舰·工程": "allow",
      "旗舰·融合": "allow",
      "旗舰·实现": "allow",
      "旗舰·质检": "allow",
      "前端·还原": "allow",
      "前端·逻辑": "allow",
      "前端·动效": "allow",
      "前端·总工": "allow"
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
    "中级·工程": {
      "permission": {
        "*": "ask",
        "task": "allow",
        "*_*": "deny"
      }
    },
    "中级·创意": {
      "permission": {
        "*": "ask",
        "task": "allow",
        "*_*": "deny"
      }
    },
    "中级·码农": {
      "permission": {
        "*": "ask",
        "task": "allow",
        "*_*": "deny"
      }
    },
    "旗舰·架构": {
      "permission": {
        "*": "ask",
        "task": "allow",
        "*_*": "deny"
      }
    },
    "旗舰·规划": {
      "permission": {
        "*": "ask",
        "task": "allow",
        "*_*": "deny"
      }
    },
    "旗舰·工程": {
      "permission": {
        "*": "ask",
        "task": "allow",
        "*_*": "deny"
      }
    },
    "前端·逻辑": {
      "permission": {
        "*": "ask",
        "task": "allow",
        "*_*": "deny"
      }
    },
    "前端·动效": {
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
Check "agents == 19 (got $($agents.Count))" ($agents.Count -eq 19)

$cmds = @(Get-ChildItem .opencode/commands/moa-*.md -ErrorAction SilentlyContinue)
Check "commands == 5 (got $($cmds.Count))" ($cmds.Count -eq 5)

$needSkills = 'code-review-moa','architecture-moa','frontend-moa'
$missing = $needSkills | Where-Object { -not (Test-Path ".opencode/skills/$_/SKILL.md") }
Check "3 个指定 skill 存在(缺: $($missing -join ','))" ($missing.Count -eq 0)

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
Check "provider.opencode-go 已注册且 apiKey 真实(非占位符/空)" ($hasProv -and $hasRealKey -and -not $hasPlaceholder)

$re = (Select-String -Path .opencode/agents/*.md -Pattern 'reasoningEffort:' -ErrorAction SilentlyContinue).Count
Check "reasoningEffort x19 (got $re)" ($re -eq 19)

$task = (Select-String -Path .opencode/agents/*.md -Pattern 'task:' -ErrorAction SilentlyContinue).Count
Check "task: x9 (got $task)" ($task -eq 9)

Write-Host "`n== 结果：PASS=$pass FAIL=$fail WARN=$warn =="
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

Expected: Agents 19, Commands 5, Skills 3, Config ok. Key file line: shows `Key file ok` when the key is project-level; **when using the system-level `~/.config/opencode/` this shows `Key file MISSING` — that's normal**, as long as the system-level provider has a real key (or use the T0 script below, which judges a system-level key as PASS).

```bash
echo "=== content check ==="
grep "reasoningEffort:" .opencode/agents/*.md 2>/dev/null | wc -l
grep "task:" .opencode/agents/*.md 2>/dev/null | wc -l
ls .opencode/commands/moa-*.md 2>/dev/null | wc -l
```

Expected: `reasoningEffort` appears 19 times (all agents), `task:` appears 9 times (doorman + 8 opinion layers), `moa-` command filenames match 5.

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

Expected same as above. If `Select-String` count is high, it's because `task:` appears in both the doorman and opinion-layer frontmatter — normal, total is 9 (doorman 1 + 8 opinion layers each 1).

> **Deployment complete**: after all the above verifications pass, **restart opencode to apply all config**.

### How to tell deployment succeeded

1. After restarting OpenCode, press `Tab` to cycle agents (Windows desktop client: `Ctrl+.` also works) and see "门童路由员"
2. Type `@工具人` and it responds (if no response, check whether the key in `.opencode/local/opencode-go.key` is correct)
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

**Q: Can't see "门童路由员"?**
A: Check three points:

1. Is `opencode.json` at the project root (not a subfolder)?
2. Are there 19 .md files under `.opencode/agents/`?
3. After restarting OpenCode, press `Tab` to cycle agents (Windows desktop client: `Ctrl+.` also works).

**Q: `@工具人` not responding?**
A: Confirm `.opencode/agents/工具人.md` exists and the frontmatter format is correct.

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
# .opencode/agents/中级·工程.md
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
| 19 agent file count wrong            | Block 2 missed or overwrote                                        | Count per Block 6: agents=19                                                                       |
| Version < 1.1.1                      | `hidden` / `task` / agent-level `reasoningEffort` not supported    | Upgrade opencode to >= 1.3.4 (`@ai-sdk/openai-compatible` transparently passes reasoning, no `forceReasoning` needed) |

### B. Runtime failure (files complete, but agent errors)

| Symptom                                                       | Root cause                                                                                                          | Fix                                                                                              |
| ------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| All 19 agents `Upstream request failed` / silent failure      | **Neither system-level nor project-level has `opencode-go` provider, or key invalid**                                              | Go back to Provider section to set key, restart                                                 |
| System-level `opencode.json` deleted / dir empty, and project has no provider | Provider only in the deleted file → no provider resolvable anywhere                                                | Rebuild provider (default write project `opencode.json`, or system-level), restart; T0 now `FAIL`s |
| Same dir has both `opencode.json` and `opencode.jsonc`        | Official priority undefined for dual files, contents may conflict                                                  | **Keep only one** per dir, and make the kept one contain a valid `opencode-go` provider + real key |
| `apiKey` is `<YOUR_GO_API_KEY>` placeholder / empty           | Looks configured but actually 401/403                                                                               | Replace with real key; T0 now `FAIL`s                                                            |
| `@工具人` no response, log 401/403                             | Key file path wrong / placeholder not replaced / key expired                                                       | Check `.opencode/local/opencode-go.key` actually exists and content correct                      |
| An agent suddenly `Upstream request failed` + log has `400`   | `reasoningEffort` value illegal (uppercase / `max` on unsupported model / `extreme` etc.)                          | Fix to lowercase valid value per matrix below                                                    |
| Reasoning strength "feels unchanged" (always default)         | ①`reasoningEffort` uppercase/invalid value 400-downgraded to default; ②model doesn't support chosen tier 400; ③`npm` changed to `@ai-sdk/openai` without `forceReasoning` (only this case needs it, and >=1.3.4); ④opencode too old to support agent-level `reasoningEffort`; ⑤manually switched "variant/reasoning tier" in the TUI, the `model.json` cache's variant overrides the agent's `reasoningEffort` (cross-platform; WSL uses the Linux path; clear cache or edit agent field and restart to recover) | Fix to lowercase valid value per matrix; only if truly using `@ai-sdk/openai` add `forceReasoning: true` and restart (this project defaults to `openai-compatible`, not needed); if ⑤: delete the model selection cache (`~/.local/state/opencode/model.json` on Linux/macOS/WSL, `%USERPROFILE%\.local\state\opencode\model.json` on Windows; on Unix governed by `XDG_STATE_HOME`, can be redirected) or edit the agent's `reasoningEffort` field and restart |
| Doorman orchestration `task` call rejected                   | `opencode.json`'s `permission.task` whitelist missing agent name / Chinese name/· mismatch                          | Complete whitelist per Block 5                                                                   |
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
      "name": "Ollama (本地)",
      "options": { "baseURL": "http://localhost:11434/v1" },
      "models": {
        "qwen3-coder": { "name": "Qwen3-Coder (本地)" }
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
      "name": "LM Studio (本地)",
      "options": { "baseURL": "http://127.0.0.1:1234/v1" },
      "models": {
        "google/gemma-3n-e4b": { "name": "Gemma 3n (本地)" }
      }
    }
  }
}
```

### Mixed use

```yaml
# .opencode/agents/中级·码农.md
model: ollama-local/qwen3-coder
```

---

## Appendix B: Security boundary explanation

| Protection layer     | Location                                 | Effect                                  |
| -------------------- | ---------------------------------------- | --------------------------------------- |
| Global catch-all     | opencode.json                            | Unexplicitly declared tool → "ask" popup |
| Agent permission     | Each agent file frontmatter              | Tool-level allow/deny hard limit        |
| MCP permission isolation | opencode.json agent.*.permission     | `*_*: deny` disables opinion-layer MCP  |
| Task permission whitelist | opencode.json + doorman frontmatter  | Can only task specified agents          |
| Fallback chain       | Tool agent / doorman prompt              | Quick retry → ask user → downgrade      |

---

> **Doc version**: v0.0.6 | **Corresponding opencode**: >= 1.3.4 (agent-level reasoningEffort/hidden/task support; `@ai-sdk/openai-compatible` transparently passes reasoning, no `forceReasoning` needed)
