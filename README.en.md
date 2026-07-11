# OpenCode MoA

> 🌐 Languages / 语言: [中文](README.md) · English

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![OpenCode](https://img.shields.io/badge/OpenCode-%3E%3D1.3.4-orange.svg)](https://opencode.ai)

> **One conversation entry point, 19 specialized models collaborating automatically. Simple tasks use Flash (cheap), complex tasks call the flagship (expensive). Cost down ~90%, code quality significantly up.**

OpenCode MoA is a Mixture of Agents configuration package for OpenCode. It lets multiple models **think about the same problem simultaneously**, then fuse into an output quality a single model can't reach. You don't need to switch tools, write code, or have an API quota — just drop the files into your project and restart OpenCode.

**19 agents · 5 commands · 3 skills · 30-second deploy**

## Why do you need this?

By default OpenCode uses a single model from start to finish. Changing one character and designing a system architecture use the same prompt, same temperature, same context. No division of labor.

**Three problems:**

1. **Cost out of control** — simple tasks also use the expensive model, monthly bill stays high
2. **Quality bottleneck** — a single model has only one way of thinking, easily stuck in blind spots
3. **No fault tolerance** — if the model dies it freezes, no fallback

**MoA's solution:**

```
You: help me design a message queue solution

    ┌─ 旗舰·架构 (Qwen3.7 Max) ─── plan from the architect's view
    ├─ 旗舰·规划 (GLM)        ─── plan from the PM's view
    ├─ 旗舰·工程 (MiniMax M3) ─── plan from the implementer's view
    └─ 旗舰·融合 (Kimi)       ─── take the best of each, one optimal solution
```

Three independent plans from three different models naturally form a "consensus + divergence" structure. The fusion model identifies what is consensus and keeps it, and takes the best where they diverge — something a single model cannot do.

## Prerequisites

### Required

| Requirement         | Check command                  | Notes                                                                                                                                                                                                 |
| ------------------- | ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| OpenCode installed  | `opencode --version`           | **>= 1.3.4** (agent-level `reasoningEffort`/`hidden`/`task` support; `openai-compatible` provider transparently passes reasoning, no `forceReasoning` needed), [install](https://opencode.ai/install) |
| OpenCode Go plan    | opencode.ai console            | [Subscribe](https://opencode.ai/auth), first month $5, then $10/month                                                                                                                                 |
| Git installed       | `git --version`                | Used to clone the repo                                                                                                                                                                                |
| OpenCode Go API Key | created in opencode.ai console | Created in the Zen console (opencode.ai)                                                                                                                                                              |

### Optional (needed by install scripts)

| Requirement     | Check command    | Notes                                                                     |
| --------------- | ---------------- | ------------------------------------------------------------------------- |
| PowerShell Core | `pwsh --version` | needed by install.ps1, bundled with Windows or `brew install powershell`  |
| jq              | `jq --version`   | needed by install.sh for JSON merge, `apt install jq` / `brew install jq` |

> No pwsh/jq is fine — you can use Method 1 (AI auto-deploy) or Method 3 (manual merge).

### Desktop vs CLI

- **CLI**: all methods supported
- **Desktop**: Method 1 (AI auto-deploy) is most convenient; Methods 2/3 require terminal operation first

> ⚠️ **System-level key path is easy to place wrong** — correct spelling in "Read before deploy" below. Wrong path leads to "deployment succeeds but all agents can't connect".

> ⚠️ **Read before deploy: don't misplace the key path**
> Put the provider + key in either the **project-level `opencode.json`** (default, self-contained) or the **system-level** shared path — pick **one**.
> If using system-level, the correct path is:
> 
> - Linux/macOS `~/.config/opencode/opencode.json`
> - Windows `%USERPROFILE%\.config\opencode\opencode.json` (**not** `%APPDATA%\opencode`)
>   Wrong system-level path leads to "deployment succeeds but all agents can't connect".

## 30-second deploy

### Method 1: AI auto-deploy (recommended)

1. Download [`docs/opencode-moa.md`](https://github.com/ZenHG/opencode-moa/blob/master/docs/opencode-moa.md)
2. Upload that document in OpenCode and send:

> Deploy all 19 agents, 5 commands, and 3 skills from this manual into the current project

3. The AI creates all files automatically. **Restart OpenCode** when done.

> No need to manually create any file. The deployment manual is itself the installer.

### Method 2: one-click install script (script version · CLI-friendly)

```bash
# clone the repo
git clone https://github.com/ZenHG/opencode-moa.git

# enter your project directory
cd your-project

# copy the .opencode directory from the repo
cp -r ../opencode-moa/.opencode/ .

# run the install script (auto-merge config, keeps your API key)
# Windows:
pwsh ../opencode-moa/install.ps1
# Linux/macOS:
bash ../opencode-moa/install.sh
```

> The install script auto-backs up your original `opencode.json`, only merging MoA config while keeping your provider and API key.

### Method 3: manual install

```bash
# 1. clone the repo
git clone https://github.com/ZenHG/opencode-moa.git

# 2. copy the .opencode directory
cp -r opencode-moa/.opencode/ your-project/

# 3. manually merge opencode.json (do NOT replace directly!)
# open opencode.json, merge MoA's permission.task and agent sections in
# keep your existing provider and model config
```

> ⚠️ **Do not** use `cat >>` to append — it corrupts JSON format. **Do not** replace directly — you'll lose your API key.

### How to tell deployment succeeded?

1. After restarting OpenCode, press `Tab` to cycle agents (Windows desktop client: `Ctrl+.` also works) and see "门童路由员" (doorman router)
2. Type `@工具人` and it responds
3. Run the verification script: `pwsh .opencode/tests/T0-static-verify.ps1` (generated by manual Block 5.5 during deploy), expected all PASS (FAIL=0; with system-level key, WARN also counts as pass)

### One-click rollback

```bash
rm -rf your-project/.opencode/
# manually restore your opencode.json (the install script auto-backs up a .bak file)
```

## How to use?

**Learn nothing — just talk.** The doorman router automatically judges task complexity and dispatches the corresponding agent chain.

| What you say                         | What the doorman does                                            | Agents used                |
| ------------------------------------ | ---------------------------------------------------------------- | -------------------------- |
| "rename this variable"               | judged as a simple task                                          | 闪电侠 (Flash)                |
| "write a user auth module"           | tool layer gathers → 3 mid-tier parallel → fuse                  | 工具人 + mid-tier trio + fuse |
| "design a microservice architecture" | tool layer gathers → 3 flagship parallel → fuse → implement → QA | full-chain 6 agents        |
| "restore this screenshot's UI"       | 3 frontend experts parallel → lead picks best                    | frontend quartet           |
| message with screenshot              | 视觉翻译官 converts to text → normal routing                          | 视觉翻译官                      |

**Direct `@` calls:**

```
@闪电侠 help me write a hello world
@工具人 search all TODOs in the project
@旗舰·架构 design a message queue solution
```

**One-click commands:**

| Command         | Scenario                                       |
| --------------- | ---------------------------------------------- |
| `/moa-quick`    | simple task, translation, config change        |
| `/moa-medium`   | function module, bug fix, single-file refactor |
| `/moa-flagship` | system architecture, large refactor            |
| `/moa-frontend` | UI restore, CSS, screenshot fix                |
| `/moa-describe` | screenshot/image to text                       |

## Architecture

```
                       门童路由员 (Flash)
                              │
                ┌─────────────┼─────────────┐
                ▼             ▼             ▼
             工具层          意见层          融合层
          Flash + MiMo    3 parallel opinions   take the best
          (~80% calls)   (~18% calls)         (~2% calls)
```

**Tool layer** (Flash + MiMo) — read code, search files, screenshot to text. Cheap and fast, call freely.

**Opinion layer** (MiniMax / DeepSeek Pro / Qwen / MiMo-Pro) — plans from different perspectives. Three opinions naturally form a "consensus + divergence" structure.

**Fusion layer** (Kimi / Qwen-Max / GLM) — keep consensus, take the best on divergence. Used only where it matters.

## 19 Agents

```
门童路由员 (Flash)
 │
 ├── Tool layer ──────────────────────────────────────
 │   工具人      (Flash)        read code, search files
 │   工具人-mimo (MiMo)         reliable file read (fallback + parallel)
 │   闪电侠      (Flash)        simple tasks in one shot
 │   视觉翻译官   (MiMo)        screenshot/UI/error image to text
 │
 ├── Mid-tier opinion layer ──────────────────────────
 │   中级·工程    (MiniMax M3)   engineering view
 │   中级·创意    (DeepSeek Pro) creative view
 │   中级·码农    (Flash)        pragmatic view
 │   中级·融合    (Kimi)         fuse three plans
 │
 ├── Flagship opinion layer ──────────────────────────
 │   旗舰·架构    (Qwen3.7 Max)   top-level architecture
 │   旗舰·规划    (GLM)          structured planning
 │   旗舰·工程    (MiniMax M3)   large-scale implementation
 │   旗舰·融合    (Kimi)         fuse three architecture plans
 │   旗舰·实现    (Flash)        implement per fused plan
 │   旗舰·质检    (DeepSeek Pro) plan vs code acceptance
 │
 └── Frontend opinion layer ──────────────────────────
      前端·还原    (MiMo)         pixel-perfect UI restore
      前端·逻辑    (Qwen3.7 Plus)  component architecture & state mgmt
      前端·动效    (MiMo-Pro)     interaction & motion
      前端·总工    (Kimi)         pick best of three frontend plans
```

## Fault tolerance design

### Fallback chain

The tool layer failing doesn't freeze — it auto-downgrades:

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

### MCP permission isolation

Opinion-layer agents are forbidden from MCP tools, preventing them from bypassing the tool layer to fetch material themselves:

- Tool layer: can call MCP (read code, search files)
- Opinion layer: `read: deny` + MCP blocked, can only plan based on material from the tool layer
- Fusion layer: same, can only fuse based on the three opinions

### No-material fallback

When the opinion layer is called but has no material (tool layer fully failed), it asks the user:

- Choose "give plan directly" → pure logical reasoning based on the requirement description (no code read)
- Choose "wait for tool layer" → output WAITING, retry after tool layer recovers

### Error classification

The tool layer outputs a clear error category on failure, instead of blindly retrying:

- `ERROR_PROVIDER` — server 502/503/timeout
- `ERROR_AUTH` — auth failure
- `ERROR_UNKNOWN` — other errors

## Cost

### Why ~90% saved

MoA bills by a call-volume-weighted mix: ~80% tool-layer Flash, ~18% mid-tier, ~2% flagship. Estimate the effective output unit price with the per-unit prices in this section's cost table:

| Layer      | Share | Output unit price /1M                                             | Weighted |
| ---------- | ----- | ----------------------------------------------------------------- | -------- |
| Tool layer | 80%   | $0.28                                                             | $0.224   |
| Opinion    | 18%   | ~$2.00 (MiniMax $1.20 / DeepSeek Pro $3.48 / Qwen Plus $1.60 avg) | $0.36    |
| Fusion     | 2%    | ~$5.30 (Kimi $4.00 / Qwen Max $7.50 / GLM $4.40 avg)              | $0.106   |

Blended effective output unit price ≈ **$0.69 / 1M**. Compared to "all-flagship GLM $7.50" → about 9% → **~90% saved**; compared to "all-mid-tier DeepSeek Pro $3.48" → about 20% → **~80% saved**. The "save 90%" claim is the real value against the flagship baseline.

### OpenCode Go plan

MoA is based on the [OpenCode Go](https://opencode.ai/docs/zh-cn/go/) plan, **first month $5, then $10/month**.

**Usage limits:**

| Time window   | Quota |
| ------------- | ----- |
| Every 5 hours | $12   |
| Weekly        | $30   |
| Monthly       | $60   |

Limits are defined by dollar value. Cheap models (Flash) can be used more often, expensive models (GLM) less often.

### Monthly quota per layer

| Layer      | Model           | Unit price (in/out per 1M) | Monthly quota | Call frequency    |
| ---------- | --------------- | -------------------------- | ------------- | ----------------- |
| Tool layer | Flash           | $0.14 / $0.28              | 158,150       | ~80%              |
| Tool layer | MiMo-V2.5       | $0.14 / $0.28              | 150,400       | (use freely)      |
| Opinion    | MiniMax M3      | $0.30 / $1.20              | 16,000        | ~18%              |
| Opinion    | DeepSeek V4 Pro | $1.74 / $3.48              | 17,150        |                   |
| Opinion    | Qwen3.7 Plus    | $0.40 / $1.60              | 21,600        |                   |
| Fusion     | Kimi K2.7 Code  | $0.95 / $4.00              | 9,250         | ~2%               |
| Fusion     | Qwen3.7 Max     | $2.50 / $7.50              | 4,770         | (where it counts) |
| Fusion     | GLM-5.2         | $1.40 / $4.40              | 4,300         |                   |

> All model IDs are declarations only; replace with any model you prefer.

### After hitting the limit

- **Free model fallback** — after Go hits the limit you can keep using free models
- **Zen balance fallback** — enable "use balance" in the console; after Go limit, auto-use Zen balance

### Free models

OpenCode Zen provides free models as a last resort:

| Model                  | Trait                           |
| ---------------------- | ------------------------------- |
| DeepSeek V4 Flash Free | fast, but limited context       |
| MiMo-V2.5 Free         | better quality, but may be slow |
| North Mini Code Free   | provided by Cohere              |
| Nemotron 3 Ultra Free  | NVIDIA free endpoint            |

> ⚠️ Free model limits: smaller context window, possibly slower response, data may be used for training, free for a limited time.

## Security

| Protection                 | Effect                                                          |
| -------------------------- | --------------------------------------------------------------- |
| Global catch-all           | undeclared tool call → popup confirm                            |
| Agent permission isolation | each agent can only use allowed tools                           |
| MCP permission isolation   | opinion layer forbidden from MCP, prevents bypassing tool layer |
| Task whitelist             | doorman can only call declared agents                           |
| Fallback chain             | tool layer fails → ask user → wait/skip/free model              |
| One-click rollback         | delete `.opencode/` to restore                                  |

## Local models

Supports mixing in local models like Ollama / LM Studio:

```yaml
# .opencode/agents/中级·码农.md
model: ollama-local/qwen3-coder
```

See Appendix A of [`docs/opencode-moa.md`](docs/opencode-moa.md).

## Verification

After deploy, run the static check (needs `pwsh`):

```bash
pwsh .opencode/tests/T0-static-verify.ps1
# expected: all PASS / FAIL=0 (with system-level key, WARN also counts as pass)
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
A: Method 1 is most convenient — drag `docs/opencode-moa.md` into the chat box and let the AI auto-deploy. Methods 2/3 require operating in a terminal (CMD/PowerShell/Terminal) first.

### Usage

**Q: Can't see "门童路由员"?**
A: See the three checks under "30-second deploy → How to tell deployment succeeded": `opencode.json` at project root, 19 .md under `.opencode/agents/`, switch with `Tab` after restart (Windows desktop client: `Ctrl+.` also works).

**Q: `@工具人` no response?**
A: Confirm `.opencode/agents/工具人.md` exists and the frontmatter format is correct.

**Q: Error "model not found"?**
A: Model ID format should be `provider/model-id` (e.g. `opencode-go/kimi-k2.7-code`). Register the corresponding provider in the config file (system-level `~/.config/opencode/opencode.json` or project `opencode.json`), then use `/models` inside the TUI to see available models.

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
A: See "Fault tolerance design → Fallback chain" above: MoA asks the user to choose A. wait a few minutes / B. skip tool layer and call opinion layer directly (higher cost) / C. switch to free model.

**Q: Where are the free models?**
A: See "Cost → Free models" above: use `/models` to open the model list and pick one tagged "Free" (Windows desktop client: `Ctrl+'` also works) (DeepSeek V4 Flash Free, MiMo-V2.5 Free, Big Pickle, etc.). Free models have limited context, may be slower, and data may be used for training.

## Contributing

PRs and Issues welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE) · [OpenCode MoA](https://github.com/ZenHG/opencode-moa)
