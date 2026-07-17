# OpenCode MoA

> 🌐 Languages: English · [中文](README.zh.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![OpenCode](https://img.shields.io/badge/OpenCode-%3E%3D1.3.4-orange.svg)](https://opencode.ai)

> 🔥 **Hot (2026-07):** flagship fuse upgraded to **Kimi K3** — 2.8T params, 1M context, top-tier frontier model. OpenCode Go quota 2x until 7/24 (140 → 280 / 5h, then back to 140). MoA quality ceiling now at the front of the pack.

> **One conversation entry point, 22 specialized models collaborating automatically. Simple tasks use Flash (cheap), complex tasks call the flagship (expensive). Cost down up to ~90% (vs all-flagship) when simple tasks dominate the workload and flagship calls are minimized — actual savings depend on task mix; code quality significantly up.**

![OpenCode MoA](.github/opengraph.png)

OpenCode MoA is a Mixture of Agents configuration package for OpenCode. It lets multiple models **think about the same problem simultaneously**, then fuse into an output quality a single model can't reach. You don't need to switch tools, write code, or have an API quota — just drop the files into your project and restart OpenCode.

**22 agents · 5 commands · 3 skills · 30-second deploy**

---

## Why do you need this?

By default OpenCode uses a single model from start to finish. Changing one character and designing a system architecture use the same prompt, same temperature, same context. No division of labor.

**Three problems:**

1. **Cost out of control** — simple tasks also use the expensive model, monthly bill stays high
2. **Quality bottleneck** — a single model has only one way of thinking, easily stuck in blind spots
3. **No fault tolerance** — if the model dies it freezes, no fallback

**MoA's solution:**

```
You: help me design a message queue solution

    ┌─ flag-arch (Qwen3.7 Max) ─── plan from the architect's view
    ├─ flag-plan (GLM        ) ─── plan from the PM's view
    ├─ flag-eng  (MiniMax M3 ) ─── plan from the implementer's view
    └─ flag-fuse (Kimi K3) ─── take the best of each, one optimal solution
```

Three independent plans from three different models naturally form a "consensus + divergence" structure. The fusion model identifies what is consensus and keeps it, and takes the best where they diverge — something a single model cannot do.

---

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

---

## 30-second deploy

### Method 1: AI auto-deploy (recommended)

1. Download [`docs/opencode-moa.en.md`](https://github.com/ZenHG/opencode-moa/blob/master/docs/opencode-moa.en.md)
2. Upload that document in OpenCode and send:

> Deploy all 22 agents, 5 commands, and 3 skills from this manual into the current project

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
> 
> Note: this method copies the repo's bundled `.opencode/` as-is — its agents have **Chinese display names**. If you want English-named agents (so you can `@english-name`), use Method 1 instead.

### Customize any model

MoA is a **generic template** — every agent's model is just an ID you can change. Each agent file starts with:

```yaml
model: opencode-go/<model-id>
```

To swap a model, edit that one line in `.opencode/agents/<agent>.md` to any `provider/model-id` you have access to (e.g. `opencode-go/kimi-k2.7-code`, `opencode-go/glm-5.2`). No reinstall needed. Mix and match freely — the template binds you to nothing.

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
> 
> Note: this method copies the repo's bundled `.opencode/` as-is — its agents have **Chinese display names**. If you want English-named agents (so you can `@english-name`), use Method 1 instead.

### How to tell deployment succeeded?

1. After restarting OpenCode, press `Tab` to cycle agents (Windows desktop client: `Ctrl+.` also works) and see "concierge-router"
2. Type `@tool-handler` and it responds
3. Run the verification script: `pwsh .opencode/tests/T0-static-verify.ps1` (generated by manual Block 5.5 during deploy), expected all PASS (FAIL=0; with system-level key, WARN also counts as pass)

### One-click rollback

```bash
rm -rf your-project/.opencode/
# manually restore your opencode.json (the install script auto-backs up a .bak file)
```

---

## How to use?

**Learn nothing — just talk.** The concierge-router automatically judges task complexity and dispatches the corresponding agent chain.

| What you say                         | What the concierge-router does                                   | Agents used                         |
| ------------------------------------ | ---------------------------------------------------------------- | ----------------------------------- |
| "rename this variable"               | judged as a simple task                                          | swift (Flash)                       |
| "write a user auth module"           | tool layer gathers → 3 mid-tier parallel → fuse                  | tool-handler + mid-tier trio + fuse |
| "design a microservice architecture" | tool layer gathers → 3 flagship parallel → fuse → implement → QA | full-chain 6 agents                 |
| "restore this screenshot's UI"       | 3 frontend experts parallel → lead picks best                    | frontend quartet                    |
| message with screenshot              | vision-translator converts to text → normal routing              | vision-translator                   |

**Direct `@` calls:**

```
@swift help me write a hello world
@tool-handler search all TODOs in the project
@flag-arch design a message queue solution
```

**One-click commands:**

| Command         | Scenario                                       |
| --------------- | ---------------------------------------------- |
| `/moa-quick`    | simple task, translation, config change        |
| `/moa-medium`   | function module, bug fix, single-file refactor |
| `/moa-flagship` | system architecture, large refactor            |
| `/moa-frontend` | UI restore, CSS, screenshot fix                |
| `/moa-describe` | screenshot/image to text                       |

---

## Architecture

```
                      concierge-router (Flash)
                                 │
                ┌────────────────┼─────────────────┐
                ▼                ▼                 ▼
             Tool layer     Opinion layer       Fusion layer
             Flash + MiMo   3 parallel opinions take the best
             (~80% calls)   (~18% calls)        (~2% calls)
```

**Tool layer** (Flash + MiMo) — read code, search files, screenshot to text. Cheap and fast, call freely.

**Opinion layer** (MiniMax / DeepSeek Pro / Qwen / MiMo-Pro) — plans from different perspectives. Three opinions naturally form a "consensus + divergence" structure.

**Fusion layer** (Kimi K3 / Qwen-Max / GLM / DeepSeek Pro fallback) — keep consensus, take the best on divergence, with fallback to DeepSeek V4 Pro if fusion fails. The flagship fuse now runs on **Kimi K3** (2.8T params, 1M context, top-tier frontier model) — pushing MoA's quality ceiling to the front of the pack.

> ⚠️ The call-volume ratios below (~80% / ~18% / ~2%) are **design targets**, not measured statistics. Actual ratios vary by task complexity.

---

## 22 Agents

> The English name is the logical role; the Chinese in parentheses is the **exact filename** under `.opencode/agents/` — you call them with `@` (e.g. `@门童路由员`).

```
concierge-router (门童路由员, Flash)
 │
 ├── Tool layer ─────────────────────────────────────────────
 │   tool-handler      (工具人,      Flash ) read code, search files [+ material self-check]
 │   tool-handler-mimo (工具人-mimo, MiMo  ) reliable file read (fallback + parallel) [hidden]
 │   swift             (闪电侠,      Flash ) simple tasks in one shot
 │   vision-translator (视觉翻译官,  MiMo  ) screenshot/UI/error image to text
 │
 ├── residual-extractor  (残差提取者,  Flash     ) analyze divergence between plans
 ├── confidence-assessor (置信度评估者, DS Pro    ) assess fusion result confidence
 │
 ├── Mid-tier opinion layer ─────────────────────────────────────────────
  │   mid-eng      (中级·工程, Kimi K2.6   ) engineering view
  │   mid-creative (中级·创意, Qwen3.7 Plus) creative view
 │   mid-coder    (中级·码农, Flash       ) pragmatic view
 │   mid-fuse     (中级·融合, Kimi        ) fuse three plans [max_tokens: 16384]
 │
 ├── Flagship opinion layer ─────────────────────────────────────────────
 │   flag-arch (旗舰·架构, Qwen3.7 Max ) top-level architecture
 │   flag-plan (旗舰·规划, GLM         ) structured planning
 │   flag-eng  (旗舰·工程, MiniMax M3  ) large-scale implementation
 │   flag-fuse (旗舰·融合, Kimi K3     ) fuse three architecture plans [max_tokens: 16384]
 │   flag-impl (旗舰·实现, Flash       ) implement per fused plan [hidden]
 │   flag-qa   (旗舰·质检, DeepSeek Pro) plan review + code acceptance [max_tokens: 16384]
 │
 └── Frontend opinion layer ─────────────────────────────────────────────
     fe-restore (前端·还原, MiMo        ) pixel-perfect UI restore
     fe-logic   (前端·逻辑, Qwen3.7 Plus) component architecture & state mgmt
     fe-motion  (前端·动效, MiMo-Pro     ) interaction & motion
     fe-lead    (前端·总工, GLM-5.2      ) pick best of three frontend plans [max_tokens: 16384]
 ```

Fallback agent (not in the router chain above, called only when fusion fails):
```
fallback (融合·保底, DeepSeek V4 Pro) — same residual-enhanced fusion, used when flag-fuse / mid-fuse / fe-lead fail
 ```

---

## Fault tolerance design

### Tool layer fallback chain

The tool layer failing doesn't freeze — it auto-downgrades:

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

### Fusion layer fallback

If the primary fusion agent fails (STUCK / ERROR_PROVIDER / timeout / empty result), the concierge-router automatically falls back to `@融合·保底` (DeepSeek V4 Pro, fallback):

```
flag-fuse (旗舰·融合, Kimi K3) failed
  → task(@融合·保底) (DeepSeek V4 Pro) → output fallback result
mid-fuse (中级·融合, Kimi) failed
  → task(@融合·保底) (DeepSeek V4 Pro) → output fallback result
fe-lead (前端·总工, GLM-5.2) failed
  → task(@融合·保底) (DeepSeek V4 Pro) → output fallback result
 ```

The fallback agent uses the same residual-enhanced fusion process.

### MCP permission isolation

Opinion-layer agents are forbidden from reading code directly (via `read: deny` + `bash: deny`), preventing them from bypassing the tool layer to fetch material themselves:

- Tool layer: can read code, search files (has `read`/`bash` access)
- Opinion layer: `read: deny` + `bash: deny`, can only plan based on material from the tool layer
- Fusion layer: same restriction, can only fuse based on the three opinions

> Note: This project does not configure any MCP servers. The term "MCP permission isolation" refers to the agent-level tool restrictions (`read: deny` / `bash: deny`), not MCP server-level isolation.

### No-material fallback

When the opinion layer is called but has no material (tool layer fully failed), it asks the user:

- Choose "give plan directly" → pure logical reasoning based on the requirement description (no code read)
- Choose "wait for tool layer" → output WAITING, retry after tool layer recovers

### Error classification

The tool layer outputs a clear error category on failure, instead of blindly retrying:

- `ERROR_PROVIDER` — server 502/503/timeout
- `ERROR_AUTH` — auth failure
- `ERROR_UNKNOWN` — other errors

---

## Cost

### Why ~90% saved

MoA bills by a call-volume-weighted mix: ~80% tool-layer Flash, ~18% mid-tier, ~2% flagship. Estimate the effective output unit price with the per-unit prices in this section's cost table:

> **Important**: The 80/18/2 ratios are **expected call volume distribution designed by the architecture**, not measured cost proportions. Actual usage depends on task types and complexity.

| Layer      | Share | Output unit price /1M                                             | Weighted |
| ---------- | ----- | ----------------------------------------------------------------- | -------- |
| Tool layer | 80%   | $0.28                                                             | $0.224   |
| Mid tier   | 18%   | ~$2.10 (MiniMax $1.20 / DeepSeek Pro $3.48 / Qwen Plus $1.60 / **Kimi K2.7 $4.00 mid-fuse** avg) | $0.378   |
| Flagship   | 2%    | ~$6.00 (Qwen/GLM/MiniMax ~$4-7 + **Kimi K3 $15.00 flag-fuse**)    | $0.12    |

Blended effective output unit price ≈ **$0.72 / 1M**. Compared to "all-flagship GLM $7.50" → about 10% → **~90% saved**; compared to "all-mid-tier DeepSeek Pro $3.48" → about 21% → **~79% saved**. The "save 90%" claim is the real value against the flagship baseline.

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

| Layer      | Model           | Unit price (in/out per 1M) | Monthly quota | Call frequency      |
| ---------- | --------------- | -------------------------- | ------------- | ------------------- |
| Tool layer | Flash           | $0.14 / $0.28              | 158,150       | ~80%                |
| Tool layer | MiMo-V2.5       | $0.14 / $0.28              | 150,400       | (use freely)        |
| Opinion    | MiniMax M3      | $0.30 / $1.20              | 16,000        | ~18%                |
| Opinion    | DeepSeek V4 Pro | $1.74 / $3.48              | 17,150        |                     |
| Opinion    | Qwen3.7 Plus    | $0.40 / $1.60              | 21,600        |                     |
| Fusion     | Kimi K2.7 Code  | $0.95 / $4.00              | 9,250         | ~2% (mid-tier fuse) |
| Fusion     | Kimi K3         | $3.00 / $15.00             | 280             | ~2% (flagship fuse) |
| Fusion     | GLM-5.2         | $1.40 / $4.40              | 4,300         | ~2% (frontend lead) |

> All model IDs are declarations only; replace with any model you prefer.

![OpenCode Go quota per 5h](.github/quota-chart-en.svg)

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

---

## Security

| Protection                 | Effect                                                                                                                                                                                        |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Global catch-all           | undeclared tool call → popup confirm                                                                                                                                                          |
| Agent permission isolation | each agent can only use allowed tools                                                                                                                                                         |
| MCP permission isolation   | opinion layer forbidden from reading code (read: deny / bash: deny), prevents bypassing tool layer (project has no MCP server configured; "MCP" here refers to agent-level tool restrictions) |
| Task whitelist             | concierge-router can only call declared agents                                                                                                                                                |
| Fallback chain             | tool layer fails → ask user → wait/skip/free model                                                                                                                                            |
| One-click rollback         | delete `.opencode/` to restore                                                                                                                                                                |

---

## Local models

Supports mixing in local models like Ollama / LM Studio:

```yaml
# .opencode/agents/mid-coder.md
model: ollama-local/qwen3-coder
```

See Appendix A of [`docs/opencode-moa.md`](docs/opencode-moa.md).

---

## Verification

The repo ships three check scripts under `.opencode/tests/`. Layer 0 is fully automatic; Layers 1–2 are guided checklists you walk through inside OpenCode.

```bash
# Layer 0 — static check (automatic, 0 token)
pwsh .opencode/tests/T0-static-verify.ps1
# expected: all PASS / FAIL=0 (with system-level key, WARN also counts as pass)

# run all three layers at once
pwsh .opencode/tests/run-all.ps1
```

| Script | Layer | What it does | Mode |
| ------ | ----- | ------------ | ---- |
| `T0-static-verify.ps1` | 0 | Checks file structure, agent/command/skill counts, README anchors, key-path correctness | Automatic |
| `T1-behavioral-guide.ps1` | 1 | Prints a step-by-step checklist for routing / opinion / fusion behavior | Manual (in OpenCode) |
| `T2-moa-smoke-guide.ps1` | 2 | Prints a smoke-test checklist for `/moa-*` commands end-to-end | Manual (in OpenCode) |
| `run-all.ps1` | 0–2 | Runs T0 then prints the T1/T2 guided checklists | Mixed |

---

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
A: Method 1 is most convenient — drag `docs/opencode-moa.en.md` into the chat box and let the AI auto-deploy. Methods 2/3 require operating in a terminal (CMD/PowerShell/Terminal) first.

### Usage

**Q: Can't see "concierge-router"?**
A: See the three checks under "30-second deploy → How to tell deployment succeeded": `opencode.json` at project root, 22 .md under `.opencode/agents/`, switch with `Tab` after restart (Windows desktop client: `Ctrl+.` also works).

**Q: `@tool-handler` no response?**
A: Confirm `.opencode/agents/tool-handler.md` exists and the frontmatter format is correct.

**Q: Error "model not found"?**
A: Model ID format should be `provider/model-id` (e.g. `opencode-go/kimi-k2.7-code`). Register the corresponding provider in the config file (system-level `~/.config/opencode/opencode.json` or project `opencode.json`), then use `/models` inside the TUI to see available models.

**Q: How do I switch back to the original build/plan agent?**
A: Press `Tab` to switch (Windows desktop client: `Ctrl+.` also works), or type `/build`, `/plan`. MoA does not affect built-in agents.

**Q: I want to use my own model, not the Go plan?**
A: Just change the agent's `model` field:

```yaml
# .opencode/agents/mid-eng.md
model: opencode-go/glm-5.2
```

**Q: Can I delete the repo after deploying?**
A: Yes. MoA is already copied to your project's `.opencode/` directory; the original repo can be deleted.

**Q: How do I deploy across multiple projects?**
A: Deploy each project separately. `.opencode/` is project-level config and does not affect other projects.

### Fallback

**Q: The whole tool layer is down, what now?**
A: See "Fault tolerance design → Fallback chain" above: MoA asks the user to choose A. wait a few minutes / B. skip tool layer and call opinion layer directly (higher cost).

**Q: Where are the free models?**
A: See "Cost → Free models" above: use `/models` to open the model list and pick one tagged "Free" (Windows desktop client: `Ctrl+'` also works) (DeepSeek V4 Flash Free, MiMo-V2.5 Free, North Mini Code Free, etc.). Free models have limited context, may be slower, and data may be used for training.

---

## Maintainer tooling (not needed by end users)

The following files are for **repo maintainers**, not for deploying MoA. End users can ignore them.

| File | Purpose |
| ---- | ------- |
| `deploy-sync.ps1` | Maintainers only — syncs the repo to GitHub and uploads the `opencode-moa` skill to SkillHub. Supports `-SkipGit` / `-SkipSkillHub` / `-DryRun`. |
| `scripts/hooks/pre-commit` | Local git hook reminder: warns when you stage a `CHANGELOG.md` change (which auto-releases on push to `master`). |
| `scripts/hooks/pre-push` | Local git hook reminder: confirms the version before pushing `CHANGELOG.md` changes to `master`; auto-proceeds in non-interactive/CI environments. |

> These hooks are not installed automatically. Symlink them into `.git/hooks/` if you want the reminders, e.g. `ln -s ../../scripts/hooks/pre-push .git/hooks/pre-push`.

---

## Contributing

PRs and Issues welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## License

[MIT](LICENSE) · [OpenCode MoA](https://github.com/ZenHG/opencode-moa)
