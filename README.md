# OpenCode MoA

> 🌐 Languages: English · [中文](README.zh.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![OpenCode](https://img.shields.io/badge/OpenCode-%3E%3D1.3.4-orange.svg)](https://opencode.ai)

> 🔥 **Hot (2026-07):** **DeepSeek-V4-Flash-0731** official release — agentic capability sharply upgraded, beating the pricier **GLM-5.2** on agent benchmarks (Terminal Bench 82.7 vs 81.0, DeepSWE 54.4 vs 46.2, Toolathlon 70.3 vs 59.9) at far lower cost. MoA's Flash tier (tool + opinion layers) got much stronger at the same low price.

> 🔄 **LongLoop (24h unattended):** Keep your project iterating for days — no forgetting, no stopping, no repeating. The concierge wakes every round, routes through the full MoA pipeline, and writes progress to disk. One command to run it on your project: **[▶ Get started →](longloop/docs/LongLoop.md)**

> **One conversation entry point, 22 specialized models collaborating automatically. Simple tasks use Flash (cheap), complex tasks call the flagship (expensive). Cost down up to ~90% (vs all-flagship) when simple tasks dominate the workload and flagship calls are minimized — actual savings depend on task mix; code quality significantly up.**

> structured output (---section--- markers), 界线 acceptance, anti-cheat, auto-routing. See [CHANGELOG](CHANGELOG.md).

<!-- ARCH-IMG -->
![OpenCode MoA Architecture](.github/moa-arch.png)
<!-- /ARCH-IMG -->

OpenCode MoA is a Mixture of Agents configuration package for OpenCode. It lets multiple models **think about the same problem simultaneously**, then fuse into an output quality a single model can't reach. You don't need to switch tools, write code, or have an API quota — just drop the files into your project and restart OpenCode.

**22 agents · 5 commands · 3 skills · 30-second deploy**

---

## Why do you need this?

By default OpenCode uses a single model from start to finish. Changing one character and designing a system architecture use the same prompt, same temperature, same context. No division of labor.

**Three problems:** ① cost out of control — simple tasks also use the expensive model; ② quality bottleneck — a single model has only one way of thinking; ③ no fault tolerance — if the model dies it freezes, no fallback.

**MoA's solution:**

```
You: help me design a message queue solution

    ┌─ flag-arch (Qwen3.7 Max)  ─── plan from the architect's view
    ├─ flag-plan (DeepSeek V4 Flash)  ─── plan from the planning view
    ├─ flag-eng  (DeepSeek V4 Flash)  ─── plan from the implementer's view
    └─ flag-fuse (Kimi K3    )  ─── take the best of each, one optimal solution
```

<!-- COST-IMG -->
![Cost down up to 90%](.github/moa-cost.png)
<!-- /COST-IMG -->

Three independent plans from three different models naturally form a "consensus + divergence" structure. The fusion model keeps the consensus and takes the best where they diverge — something a single model cannot do.

---

## Prerequisites

| Requirement        | Notes                                                                                          |
| ------------------ | ---------------------------------------------------------------------------------------------- |
| OpenCode **>= 1.3.4** | agent-level `reasoningEffort`/`hidden`/`task` support, [install](https://opencode.ai/install) |
| OpenCode Go plan   | [Subscribe](https://opencode.ai/auth), first month $5, then $10/month                           |
| Git                | used to clone the repo                                                                         |

Install scripts additionally need `pwsh` (Windows) / `jq` (Linux/macOS) — without them use Method 1 or Method 3 below.

> ⚠️ **Key path pitfall** — put the provider + key in either the **project-level `opencode.json`** or the **system-level** shared path, pick **one**. System-level correct path: Linux/macOS `~/.config/opencode/opencode.json`; Windows `%USERPROFILE%\.config\opencode\opencode.json` (**not** `%APPDATA%\opencode`). Wrong path → "deployment succeeds but all agents can't connect".

---

## 30-second deploy

### Method 1: AI auto-deploy (recommended)

1. Download [`docs/opencode-moa.en.md`](https://github.com/ZenHG/opencode-moa/blob/master/docs/opencode-moa.en.md)
2. Upload that document in OpenCode and send:

> Deploy all 22 agents, 5 commands, and 3 skills from this manual into the current project

3. The AI creates all files automatically. **Restart OpenCode** when done.

> The deployment manual is itself the installer — no need to manually create any file.

### Method 2: one-click install script (CLI-friendly)

```bash
# clone the repo, then copy the config into your project
git clone https://github.com/ZenHG/opencode-moa.git
cd your-project
cp -r ../opencode-moa/.opencode/ .
cp -r ../opencode-moa/.moa/ .

# run the install script (auto-merge config, keeps your API key)
# Windows:  pwsh ../opencode-moa/install.ps1
# Linux/macOS:  bash ../opencode-moa/install.sh
```

> The install script auto-backs up your original `opencode.json`, only merging MoA config while keeping your provider and API key.

### Method 3: manual install

```bash
# 1. clone the repo
# 2. copy the .opencode directory and .moa config into your project
# 3. manually merge opencode.json (do NOT replace directly!)
#    merge MoA's permission.task and agent sections in, keep your existing provider and model config
```

> ⚠️ **Do not** use `cat >>` to append (corrupts JSON) and **do not** replace directly (loses your API key).

### Customize any model

MoA is a **generic template** — every agent's model is just an ID you can change. Each agent file starts with `model: opencode-go/<model-id>`. Swap a model by editing that one line in `.opencode/agents/<agent>.md` (e.g. `opencode-go/kimi-k2.7-code`, `opencode-go/deepseek-v4-flash`). No reinstall needed.

### How to tell deployment succeeded?

1. Restart OpenCode, press `Tab` to cycle agents (Windows desktop: `Ctrl+.` also works) and see 门童
2. Type `@工具人` and it responds
3. Run `pwsh .opencode/tests/T0-static-verify.ps1` — expected all PASS

### One-click rollback

```bash
rm -rf your-project/.opencode/
rm -rf your-project/.moa/
# manually restore your opencode.json (the install script auto-backs up a .bak file)
```

---

## How to use?

**Learn nothing — just talk.** 门童 (concierge-router) automatically judges task complexity and dispatches the corresponding agent chain.

| What you say                         | What 门童 does                                             | Agents used                         |
| ------------------------------------ | ---------------------------------------------------------------- | ----------------------------------- |
| "rename this variable"               | judged as a simple task                                          | swift (Flash)                       |
| "write a user auth module"           | tool layer gathers → 3 mid-tier parallel → fuse                  | tool-handler + mid-tier trio + fuse |
| "design a microservice architecture" | tool layer gathers → 3 flagship parallel → fuse → implement → QA | full-chain 6 agents                 |
| "restore this screenshot's UI"       | 3 frontend experts parallel → lead picks best                    | frontend quartet                    |
| message with screenshot              | vision-translator converts to text → normal routing              | vision-translator                   |
| message with error log / diagram / complex content | vision-translator decomposes content → normal routing  | vision-translator (fallback role)   |

**Direct `@` calls (visible agents only):** `@闪电侠 help me write a hello world` · `@工具人 search all TODOs in the project` · `@视觉翻译 analyze this screenshot` — the other 18 agents are hidden from the `@` menu; 门童 calls them via the Task tool automatically.

**One-click commands:**

| Command         | Scenario                                       |
| --------------- | ---------------------------------------------- |
| `/moa-quick`    | simple task, translation, config change        |
| `/moa-medium`   | function module, bug fix, single-file refactor |
| `/moa-flagship` | system architecture, large refactor            |
| `/moa-frontend` | UI restore, CSS, screenshot fix                |
| `/moa-describe` | screenshot/image to text                       |

### Auto-routing

门童 auto-detects task type via keyword analysis: **exploration** tasks ("analyze", "compare", "understand", "investigate") → exploration prompt + exploration acceptance specs; **execution** tasks ("fix", "add", "implement", "deploy") → execution prompt + stop-loss rules. The task type (`taskType=explore|execute`) is inlined as metadata to the fusion layer, which generates the matching acceptance criteria.

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

- **Tool layer** (Flash + MiMo + Qwen3.7 Plus) — read code, search files, screenshot to text. Cheap and fast, call freely.
- **Opinion layer** (Qwen / Kimi / Flash) — plans from different perspectives; three opinions naturally form "consensus + divergence".
- **Fusion layer** (Kimi K3 / Kimi K2.7 / Flash lead / DeepSeek V4 Pro fallback) — keep consensus, take the best on divergence. The flagship fuse runs on **Kimi K3** (2.8T params, 1M context) — MoA's quality ceiling is at the front of the pack.

> ⚠️ The call-volume ratios (~80% / ~18% / ~2%) are **design targets**, not measured statistics. Actual ratios vary by task complexity.

Opinion and fusion agents use `---section-name---` markers for structured output (opinion: `---记忆层---` + `---方案---` + `---红线---`; fusion: `---融合方案---` + `---分歧裁决---` + `---白名单---` + `---红线---` + `---验收标准---`), enabling downstream parsing and acceptance verification. Anti-cheat prevents implementation agents from cutting corners: baseline non-regression, forbidden actions (skip/mock/delete tests), hidden spot-checks (暗线), stop-loss. Acceptance criteria are frozen in `.moa/界线.json`. Deep-dive: [fault tolerance, cost, security, FAQ](docs/README-details.md).

## 22 Agents

> The English name is the logical role; the Chinese in parentheses is the **exact filename** under `.opencode/agents/`. Call visible agents directly with `@` (`@门童`, `@工具人`, `@闪电侠`, `@视觉翻译`); the 18 `[hidden]` agents are orchestrated by 门童 via the Task tool and are not directly @-callable.

```
concierge-router (门童, Flash)
 │
 ├── Tool layer ─────────────────────────────────────────────
 │   tool-handler      (工具人, Flash    ) read code, search files
 │   tool-handler-mimo (工具人-mimo, MiMo) [hidden]  reliable file read (fallback + parallel)
 │   swift             (闪电侠, Flash    ) simple tasks in one shot
 │   vision-translator (视觉翻译, Qwen3.7 Plus ) screenshot/UI→text; logs/diagrams/docs→decomposition
 │
 ├── residual-extractor  (残差提取,  Flash     ) analyze divergence between plans
 ├── confidence-assessor (置信度评估, DeepSeek V4 Flash    ) assess fusion result confidence
 │
 ├── Mid-tier opinion layer ─────────────────────────────────────────────
 │   mid-eng      (中级·工程, Kimi K2.6 ) engineering view
 │   mid-creative (中级·创意, Qwen3.7 Plus) creative view
 │   mid-coder    (中级·码农, Flash     ) pragmatic view
 │   mid-fuse     (中级·融合, Kimi K2.7 Code) fuse three plans [max_tokens: 16384]
 │
 ├── Flagship opinion layer ─────────────────────────────────────────────
 │   flag-arch (旗舰·架构, Qwen3.7 Max ) top-level architecture
 │   flag-plan (旗舰·规划, DeepSeek V4 Flash) structured planning
 │   flag-eng  (旗舰·工程, DeepSeek V4 Flash  ) large-scale implementation
 │   flag-fuse (旗舰·融合, Kimi K3     ) fuse three architecture plans [max_tokens: 16384]
 │   flag-impl (旗舰·执行, Flash) [hidden]  implement per fused plan
 │   flag-qa   (旗舰·质检, DeepSeek V4 Pro) plan review + code acceptance [max_tokens: 16384]
 │
 └── Frontend opinion layer ─────────────────────────────────────────────
     fe-restore (前端·还原, Qwen3.7 Plus       ) pixel-perfect UI restore
     fe-logic   (前端·逻辑, Qwen3.7 Plus) component architecture & state mgmt
     fe-motion  (前端·动效, MiMo-Pro   ) interaction & motion
     fe-lead (前端·总工, DeepSeek V4 Flash) pick best of three frontend plans [max_tokens: 16384]
```

Fallback agent (not in the router chain above, called only when fusion fails):

```
fallback (融合·保底, DeepSeek V4 Pro) — same residual-enhanced fusion, used when flag-fuse / mid-fuse / fe-lead fail
```

---

## Documentation

| Doc | Contents |
| --- | -------- |
| [docs/README-details.md](docs/README-details.md) | Fault tolerance design · cost model · security · local models · verification · FAQ · maintainer tooling |
| [docs/opencode-moa.md](docs/opencode-moa.md) (zh) / [.en.md](docs/opencode-moa.en.md) | Full deployment manual — also serves as the AI auto-deploy installer |

---

## Verification

```bash
# Layer 0 — static check (automatic, 0 token)
pwsh .opencode/tests/T0-static-verify.ps1
# run all three layers at once
pwsh .opencode/tests/run-all.ps1
```

Check scripts under `.opencode/tests/`: Layer 0 automatic (T0 static / T1 README consistency / T3 permission security); Layers 1–2 guided checklists. Details: [Verification](docs/README-details.md#verification).

---

## Contributing

PRs and Issues welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE) · [OpenCode MoA](https://github.com/ZenHG/opencode-moa)
