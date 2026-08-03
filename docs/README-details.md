# OpenCode MoA — Reference Details

> This document holds the deep-dive sections that used to live in the README: fault tolerance design, cost model, security, local models, verification, FAQ, and maintainer tooling. Return to [README](../README.md) for the quickstart.

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
fe-lead (前端·总工, DeepSeek V4 Flash) failed
  → task(@融合·保底) (DeepSeek V4 Pro) → output fallback result
```

The fallback agent uses the same residual-enhanced fusion process.

### Opinion layer partial failure tolerance

Individual opinion agents (architecture/planning/engineering, frontend-restore/logic/motion, mid-tier engineering/creative/coding) may return empty results or time out independently. The system handles this gracefully:

```
3 parallel opinion agents dispatched
  → any agent returns empty result → retry that agent once
    → retry succeeds → continue normally
    → retry fails → mark as "degraded" and proceed with N/3 inputs
      → 残差提取 works with available inputs only
      → 旗舰·融合 applies degraded fusion rules
      → output carries "[Partial] N/3 inputs" label
      → confidence score is adjusted downward
```

Degraded fusion rules (N < 3):
- Consensus coverage denominator is N, not 3
- Missing perspectives are labeled `[Missing: perspective name]`
- Consensus coverage < 50% triggers "low confidence degraded fusion" warning
- Single-source fusion (N=1) applies a 0.7 confidence penalty factor

> This prevents the pipeline from stalling (STUCK) when one opinion agent fails — a common user complaint.

### Declarative agent preconditions

Agent activation is governed by declarative `precondition` metadata, not hardcoded routing rules. Each agent declares when it should be active:

| Agent | preconditions |
|-------|---------------|
| 闪电侠 | always |
| 工具人 | requires codebase context |
| 视觉翻译 | primary: `screenshot`; fallback: `error_log OR diagram OR long_document OR ambiguous_intent` |
| 中级·工程 | requires engineering complexity |
| 中级·创意 | requires creative complexity |
| 中级·码农 | requires implementation complexity |
| 旗舰·架构/规划/工程 | requires system design complexity |
| 前端·还原/逻辑/动效 | requires frontend task |
| 融合·保底 | activated when fusion layer fails or opinion layer returns partial results |

Condition activation follows short-circuit logic: preconditions met → activate; none met → ask user for confirmation. This replaces hardcoded trigger rules (like "screenshot available → @vision-translator") with agent-declared, self-documenting preconditions.

### Pipeline stage visualization

Every routing decision outputs a stage identifier so users can track pipeline progress without learning internal step numbers:

```
[Stage: Tool Layer] → [Stage: Opinion Layer] → [Stage: Fusion Layer] → [Stage: Execution Layer]
```

Stage-to-phase mapping:
- `Tool Layer` — material collection phase
- `Opinion Layer` — parallel plan design phase (mid-tier / flagship / frontend)
- `Fusion Layer` — plan fusion and verification phase
- `Execution Layer` — code implementation and acceptance phase

### Unified progress reporting

Both success and failure paths follow the same reporting format, never exposing internal agent names:

```
[Pipeline] mode=<lite|balanced|strict>  stage=<Tool Layer|Opinion Layer|Fusion Layer|Execution Layer>  status=<idle|in_progress|complete|degraded|stuck>
  reason: <why this stage>
  path: <Tool Layer|Mid-tier chain|Flagship chain|Frontend chain>
  fallback: <recovery strategy>
```

Status indicators:
- `in_progress` — executing current stage
- `complete` — stage finished successfully
- `degraded` — running with partial inputs, lower confidence
- `stuck` — all recovery paths exhausted, user intervention needed

### Swift Parallel Shortcut

When the main pipeline is executing, swift can be dispatched in parallel for independent simple subtasks:

```
Main pipeline: Tool Layer → Opinion Layer → Fusion Layer → Execution Layer
Parallel lane: swift (always ready, runs alongside main pipeline)
```

Trigger conditions (any one):
- User instruction explicitly requests parallel work ("do X simultaneously", "also quickly check Y")
- A simple subtask emerges during main pipeline execution (e.g., searching TODOs while architecture plans are being designed)
- User directly calls @swift

Scope limitations:
- ✅ Independent tasks with no dependency on main pipeline output
- ✅ Simple operations: file search, grep, config query, formatting
- ❌ Tasks that produce input for the main pipeline
- ❌ Opinion fusion tasks (must remain serial)
- ❌ Implementation and QA tasks (must remain serial)

If swift finishes before the main pipeline, results are held and returned together at the end. If the main pipeline finishes first, swift results are returned immediately. swift failure does not affect main pipeline execution.

### MCP permission isolation

Opinion-layer agents are forbidden from reading code directly (via `read: deny` + `bash: deny`), preventing them from bypassing the tool layer to fetch material themselves:

- Tool layer: can read code, search files (has `read`/`bash` access)
- Opinion layer: `read: deny` + `bash: deny`, can only plan based on material from the tool layer
- Fusion layer: same restriction, can only fuse based on the three opinions

> Note: This project does not configure any MCP servers. The term "MCP permission isolation" refers to the agent-level tool restrictions (`read: deny` / `bash: deny`), not MCP server-level isolation.

### Task nesting defense

Non-routing agents declare `task: deny` by default to prevent child agents from calling task() again, blocking recursive nesting; exceptions: opinion layer and flagship QC authorize `task: {工具人: allow}` for evidence-gathering / independent verification. `subagent_depth: 2` permits one level of agent → tool-handler nesting, while tool-handler itself declares `task: deny`, making depth 3 unreachable — hence no recursion:

- **Layer 1 (agent frontmatter)**: non-routing agents declare `task: deny` by default (12 agents); 8 opinion-layer agents + flagship QC declare `task: {工具人: allow}` for evidence gathering (fallback path, environment-dependent)
- **Layer 2 (opencode.json)**: `permission.task` allows concierge to call all agents; opinion layer/QC may only call tool-handler; `subagent_depth: 2` opens one level of agent → tool-handler nesting while blocking deeper nesting
- **Layer 3 (prompt guard)**: concierge prompt ends with constraint forbidding itself from launching a new pipeline via sub-agent

> Added 2026-07 after discovering concierge→tool-handler→tool-handler triple nesting. Later, to support QC independent verification (re-running bright/dark acceptance lines), the opinion layer and QC were allowed one level of `task(@工具人)`; tool-handler itself refuses task, so nesting terminates at depth 2.

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

OpenCode Go plan pricing and quota details: [opencode.ai/docs/go/](https://opencode.ai/docs/go/)

## Security

| Protection                 | Effect                                                                                                                                                                                        |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Global catch-all           | undeclared tool call → popup confirm                                                                                                                                                          |
| Agent permission isolation | each agent can only use allowed tools                                                                                                                                                         |
| MCP permission isolation   | opinion layer forbidden from reading code (read: deny / bash: deny), prevents bypassing tool layer (project has no MCP server configured; "MCP" here refers to agent-level tool restrictions) |
| MCP master kill-switch     | `"*_*": "deny"` on the 16 agent override blocks in `opencode.json` — MCP tool names are always `server_tool` (contain `_`), so this wildcard blocks every MCP tool in any environment without knowing the server list; template ships no MCP servers, so deny-by-default is safe |
| Task 3-layer defense        | non-routing agents deny task by default (opinion/QC may call tool-handler only) → `subagent_depth: 2` depth cap → prompt guard, prevents recursive nesting |
| Fallback chain             | tool layer fails → ask user → wait/skip/free model                                                                                                                                            |
| One-click rollback         | delete `.opencode/` to restore                                                                                                                                                                |

---

## Local models

Supports mixing in local models like Ollama / LM Studio:

```yaml
# .opencode/agents/mid-coder.md
model: ollama-local/qwen3-coder
```

See Appendix A of [`opencode-moa.md`](opencode-moa.md).

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

| Script                    | Layer | What it does                                                                            | Mode                 |
| ------------------------- | ----- | --------------------------------------------------------------------------------------- | -------------------- |
| `T0-static-verify.ps1`    | 0     | Checks file structure, agent/command/skill counts, README anchors, key-path correctness | Automatic            |
| `T1-behavioral-guide.ps1` | 1     | Prints a step-by-step checklist for routing / opinion / fusion behavior                 | Manual (in OpenCode) |
| `T2-moa-smoke-guide.ps1`  | 2     | Prints a smoke-test checklist for `/moa-*` commands end-to-end                          | Manual (in OpenCode) |
| `run-all.ps1`             | 0–2   | Runs T0 then prints the T1/T2 guided checklists                                         | Mixed                |

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
model: opencode-go/deepseek-v4-flash
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


