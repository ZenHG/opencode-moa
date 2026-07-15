# Changelog

<details open>
<summary>🇬🇧 English</summary>

## Versioning rules

- Format: `v0.X.Y` (SemVer: major.minor.patch)
- Patch (Y): fixes, doc updates, config tweaks
- Minor (X): new features, model changes, agent changes
- Major: architectural rewrite
- No version skips; each change bumps exactly one level

### Entry structure

- One entry per release: `## v0.X.Y（YYYY-MM-DD）` (level-2 heading; fullwidth parentheses around the date).
- Two collapsible blocks per entry: English `<details open>` (expanded by default) then Chinese `<details>` (collapsed by default).
- One-line summary at the top of each block (plain text, not bold).
- Changes go under `###` category headings (e.g. `New agents`, `Fix`, `Docs`) — short category words + optional `(parenthetical note)`. Do not number headings (e.g. `### 1.`).
- Severity-ordered changes use `### Critical (P0)` / `### High (P1)` / `### Low (P2)`, each listed once in P0→P1→P2 order (never interleaved or repeated).
- Entries separated by `---`; keep one blank line between `</details>` and `---`, and between `---` and the next `##` heading (missing blanks make the heading render as a code block).

</details>

<details>
<summary>🇨🇳 中文</summary>

## 版本规范

- 格式：`v0.X.Y`（语义化版本：主版本.次版本.修订号）
- 修订号（Y）：小修、文档更新、配置调整
- 次版本号（X）：新增功能、模型调整、agent 改动
- 主版本号：架构重构
- 不跳版本号，每次改动只升一级

### 条目结构

- 每个版本一条：`## v0.X.Y（YYYY-MM-DD）`（二级标题；日期用全角括号）。
- 每条含两个折叠块：英文 `<details open>`（默认展开）在前，中文 `<details>`（默认折叠）在后。
- 每个块顶部一句摘要（纯文本，不加粗）。
- 变更用 `###` 分类小标题组织（如 `新增 agent`、`修复`、`文档`）：简短分类词 + 可选（括号说明）。不要用数字编号（如 `### 1.`）。
- 按严重度排序时用 `### 致命（P0）` / `### 高（P1）` / `### 低（P2）`，各只出现一次、按 P0→P1→P2 排列（不穿插、不重复）。
- 版本之间用 `---` 分隔；`</details>` 与 `---` 之间、`---` 与下一个 `##` 标题之间各留一个空行（缺空行会导致标题被渲染成代码块）。

</details>

---
## v0.0.9（2026-07-15）

<details open>
<summary>🇬🇧 English</summary>

MoA 2.0: Residual-enhanced fusion + confidence routing + 22 agents.

### New agents (+2)

- ``残差提取者`` (Flash): analyzes divergence between 3 parallel plans; triggers only when consensus < 95%. Enriches fusion with structured difference data.
- ``置信度评估者`` (DS Pro): evaluates fusion output across 4 dimensions (hallucination, requirement alignment, spec conflict, feasibility), returns a 0–100 confidence score.

### Fusion layer overhaul (residual-enhanced)

- **旗舰·融合** (Qwen3.7 Max, 16384 tokens): upgraded to 3-stage fusion — consensus identification → residual analysis → integration. Includes a "fast path" that skips residual when consensus ≥ 95%.
- **中级·融合** (Kimi, 16384 tokens): 2-stage simplified fusion (consensus + residual → output).
- **前端·总工** (GLM-5.2, 16384 tokens): adds confidence scoring dimension to frontend plan selection.
- **融合·保底** (DS V4 Pro, 16384 tokens): generic fallback fusion agent that inherits the residual-enhanced fusion flow. Triggered automatically when any primary fusion agent fails.
- All 3 fusion agents now have ``hidden: true`` (not shown in @ menu).

### Quality assurance upgrade

- **旗舰·质检** (DS Pro, 16384 tokens): expanded to dual-role — plan review (with confidence assessment) AND code acceptance. Adds "learning records" (logs typical problem tags after each review).

### Router upgrade

- **门童路由员** (Flash): added confidence estimation (4 dimensions: clarity, familiarity, context sufficiency, risk level) and VOC (Value of Computation) escalation rules. Expanded task whitelist to include the 2 new agents.

### Token limit fixes

- All production-layer agents bumped from 8192 → 16384 max_tokens (旗舰·实现, 旗舰·质检, 旗舰·融合, 旗舰·架构, 旗舰·规划, 旗舰·工程, 中级·工程, 中级·创意, 中级·码农, 中级·融合, 前端·总工, 前端·逻辑, 前端·动效, 融合·保底).
- Frontend·还原 bumped from 8192 → 16384; added ``hidden: true``.
- Analysis-layer agents (残差提取者, 置信度评估者): 4096 max_tokens.
- Tool-layer agents remain at 2048 (cost optimization).

### Command updates

- ``/moa-flagship``: reflects new flow (残差提取者 + 质检方案审查).
- ``/moa-medium``: reflects new flow (残差提取者 + 可选质检).
- ``/moa-quick``: marked as deprecated/equivalent to "small task" shortcut.

### Skill updates

- ``architecture-moa/SKILL.md``: reflects new flow (残差提取者 + 质检方案审查).

### Documentation fixes

- README: agent count updated 19 → 22 (header, deploy section, FAQ).
- README: clarified "MCP permission isolation" — noted it refers to agent-level ``read: deny`` / ``bash: deny``, not actual MCP server isolation (no MCP servers are configured).
- README: 80/18/2 ratio annotated as "designed call volume distribution, not measured cost proportion".
- T0 test script: updated to expect 22 agents, correct model assignments, 22 reasoningEffort entries.

### Abandoned items (intentionally not done)

- **P0-4: Clean up invalid bash allows in opencode.json** — The ``grep/ls/cat allow`` entries on ``bash: deny`` agents are noise but harmless; they're still useful for ``bash: ask`` agents.
- **P0-5: Unify 4 fusion agent prompts** — Different input sources make unified prompts counterproductive; separate prompts allow fine-tuning per chain.
- **P1-3: Deduplicate 3-document set (README + 2 manuals)** — Each doc serves a different purpose (quick-start guide vs AI installer vs English installer); cross-referencing would increase maintenance burden.

### Verification

- T0 static verification: 44/44 PASS (previously 40/40 at v0.0.8, +4 new checks for new agents/models).

</details>

<details>
<summary>🇨🇳 中文</summary>

MoA 2.0：残差增强融合 + 置信度路由 + 22 个 agent。

### 新增 agent（+2）

- ``残差提取者`` (Flash)：分析 3 份并行方案的差异；仅在共识覆盖率 < 95% 时触发，为融合层提供结构化差异数据。
- ``置信度评估者`` (DS Pro)：从 4 个维度评估融合输出（幻觉检测、要求对齐、规范冲突、可行性），返回 0–100 置信度评分。

### 融合层重构（残差增强）

- **旗舰·融合** (Qwen3.7 Max, 16384 token)：升级为三阶段融合 — 共识识别 → 残差分析 → 整合。含「快速通道」：共识 ≥ 95% 时跳过残差分析。
- **中级·融合** (Kimi, 16384 token)：两阶段简化融合（共识 + 残差 → 输出）。
- **前端·总工** (GLM-5.2, 16384 token)：新增置信度评分维度。
- **融合·保底** (DS V4 Pro, 16384 token)：通用保底融合 agent，继承残差增强融合流程。任一主融合 agent 失败时自动触发。
- 3 个融合 agent 均设 ``hidden: true``（不在 @ 菜单显示）。

### 质检升级

- **旗舰·质检** (DS Pro, 16384 token)：扩展为双重职责 — 方案审查（含置信度评估）+ 代码验收。新增「学习记录」（每次审查后记录典型问题标签）。

### 路由升级

- **门童路由员** (Flash)：新增置信度估计（4 维度：需求清晰度、技术熟悉度、上下文充分性、风险等级）和 VOC（计算价值）升级规则。task 白名单扩展至包含 2 个新 agent。

### Token 上限修复

- 所有产出层 agent 从 8192 → 16384 max_tokens（旗舰·实现/质检/融合/架构/规划/工程，中级·工程/创意/码农/融合，前端·总工/逻辑/动效，融合·保底）。
- 前端·还原 从 8192 → 16384；添加 ``hidden: true``。
- 分析层 agent（残差提取者、置信度评估者）：4096 max_tokens。
- 工具层 agent 保持 2048（成本优化）。

### 命令文件更新

- ``/moa-flagship``：反映新流程（残差提取者 + 质检方案审查）。
- ``/moa-medium``：反映新流程（残差提取者 + 可选质检）。
- ``/moa-quick``：标记为废弃/等价于「小任务」快捷方式。

### Skill 更新

- ``architecture-moa/SKILL.md``：反映新流程（残差提取者 + 质检方案审查）。

### 文档修正

- README：agent 计数 19 → 22（头部、部署节、FAQ）。
- README：澄清「MCP 权限隔离」— 实际指 agent 级别的 ``read: deny`` / ``bash: deny``，并非真实 MCP 服务器隔离（项目未配置 MCP 服务器）。
- README：80/18/2 比例标注为「设计调用量占比，非实测成本占比」。
- T0 测试脚本：更新为期望 22 个 agent、正确的模型分配、22 个 reasoningEffort。

### 放弃项（有意不做）

- **P0-4: 清理 opencode.json 中无效的 bash allow** — 对 ``bash: deny`` agent 无效但对 ``bash: ask`` agent 仍有用，保留无害。
- **P0-5: 统一 4 个融合 agent 提示词** — 输入来源不同，统一反而失去针对性。
- **P1-3: 三件套文档去重** — README/部署手册/英文手册各有定位，改为互相引用增加维护负担。

### 验证

- T0 静态验证：44/44 PASS（v0.0.8 时为 40/40，新增 4 项对新 agent/模型的检查）。

</details>

---

## v0.0.8（2026-07-11）

<details open>
<summary>🇬🇧 English</summary>

Deploy-deviation fixes and 信达雅 (faithful / expressive / elegant) wrap-up across both language manuals.

- `docs/opencode-moa.en.md` moved from `docs/en/` to `docs/`; README download link updated.
- Both manuals: fixed two deploy-blocking bugs — command file `moa-Medium.md` → `moa-medium.md` (case-sensitivity on Linux/WSL); Provider key handling now explicitly creates `.opencode/local/opencode-go.key` and references it via `{file:}` (was ambiguous → silent 401 on all 19 agents).
- Both manuals: unified router name (EN `doorman` → `concierge-router`); added a "Customization" note — agent names and `model` assignments are not hard-bound and can be swapped freely, with a warning that renaming an agent must sync the `task:` whitelist, `permission.task`, and all cross-agent `@`/`task` calls.
- READMEs (EN/ZH): 信达雅 fixes — qualified "~90%" savings (vs all-flagship baseline); unified `concierge-router` naming; fixed free-model name (`Big Pickle` → `North Mini Code Free`); fixed ZH typo (`hero 的` → `这里说的`).
- Doc footer version v0.0.6 → v0.0.8 in both manuals.

</details>

<details>
<summary>🇨🇳 中文</summary>

部署偏差修复与信达雅收口（两份语言手册）。

- `docs/en/opencode-moa.en.md` → `docs/opencode-moa.en.md`（移出 `docs/en/`）；README 下载链接同步。
- 两份手册修复两个部署阻断 bug：命令文件 `moa-Medium.md` → `moa-medium.md`（Linux/WSL 大小写敏感）；密钥落盘改为显式创建 `.opencode/local/opencode-go.key` 并经 `{file:}` 引用（原表述歧义 → 全 19 agent 静默 401）。
- 两份手册统一路由名（英文 `doorman` → `concierge-router`）；新增「自定义」备注——agent 名称与 `model` 不捆绑死、可自由替换，并提醒改名须同步 `task:` 白名单、`permission.task` 与跨 agent 调用。
- 中英文 README 信达雅修正：限定「省 90%」（对比全程旗舰基线）；统一 `concierge-router` 命名；修正免费模型名（`Big Pickle` → `North Mini Code Free`）；修正中文错别字（`hero 的` → `这里说的`）。
- 两份手册文档页脚版本 v0.0.6 → v0.0.8。

</details>

---

## v0.0.7（2026-07-11）

<details open>
<summary>🇬🇧 English</summary>

Cross-platform keybindings and version-floor consistency wrap-up (extension of the v0.0.6 doc fixes, covering code / config / agent files not yet aligned).

- `.opencode/skills/opencode-moa/SKILL.md`: env-check version floor `>= 1.1.1` → `>= 1.3.4`; deploy-success check "`Ctrl+.` to switch agent" → cross-platform "`Tab` cycle (Windows desktop also `Ctrl+.`)"; verify expectation "41 PASS" → "all PASS / FAIL=0 (with system-level key, WARN also counts as pass)"; removed the no-upload entry for the no-longer-generated `user_config.json`.
- `install.sh` / `install.ps1`: post-install keybinding hint changed from hardcoded `Ctrl+.` to cross-platform "`Tab` (Windows desktop also `Ctrl+.`)".
- `.opencode/agents/concierge-router.md`: free-model switch hint `Ctrl+.` (actually the agent key, conflicting with the keybinding convention) → `/models` and pick the Free tag (Windows desktop `Ctrl+'`); plan-agent switch `Ctrl+.` → cross-platform "`Tab` (Windows desktop `Ctrl+.`)".
- `.github/ISSUE_TEMPLATE/bug-report.yml`: version placeholder `1.1.1` → `1.3.4`.

</details>

<details>
<summary>🇨🇳 中文</summary>

跨平台键位与版本门槛一致性收口（v0.0.6 文档修正的延伸，覆盖尚未对齐的代码 / 配置 / agent 文件）。

- `.opencode/skills/opencode-moa/SKILL.md`：环境检查版本门槛 `>= 1.1.1` → `>= 1.3.4`；部署成功判定「`Ctrl+.` 切 agent」→ 跨平台「`Tab` 循环（Win 桌面端亦可用 `Ctrl+.`）」；验证预期「41 PASS」→「全部 PASS / FAIL=0（系统级 key 时 WARN 也算过）」；「不上传」清单移除已不生成的 `user_config.json`。
- `install.sh` / `install.ps1`：安装完成提示的切换键由写死的 `Ctrl+.` 改为跨平台「`Tab`（Win 桌面端亦可用 `Ctrl+.`）」。
- `.opencode/agents/concierge-router.md`：免费模型切换指引 `Ctrl+.`（实为 agent 键，与键位约定冲突）→ `/models` 选 Free 标签（Win 桌面端 `Ctrl+'`）；plan agent 切换 `Ctrl+.` → 跨平台「`Tab`（Win 桌面端 `Ctrl+.`）」。
- `.github/ISSUE_TEMPLATE/bug-report.yml`：版本占位符 `1.1.1` → `1.3.4`。

</details>

---

## v0.0.6（2026-07-11）

<details open>
<summary>🇬🇧 English</summary>

This release = manual `forceReasoning` premise correction + i18n completion (en promoted from skeleton to full) + README rework.

### Correct the manual's wrong premise that "custom provider must add `forceReasoning: true`"

#### Background

The v0.0.5 manual stated: "opencode ≥ 1.3.4, `@ai-sdk/openai-compatible` providers no longer pass reasoning params by default; you must add `forceReasoning: true`, otherwise the matrix silently fails." Per OpenCode issue #20815, that premise is false.

#### Correction (based on issue #20815 testing)

- The v1.3.4 reasoning passthrough regression **only affects custom providers using `"npm": "@ai-sdk/openai"`** (AI SDK v6 validates against a "known reasoning model list"; if not in the list it silently drops `reasoningEffort`).
- The same issue confirms **`@ai-sdk/openai-compatible` is unaffected** — `reasoningEffort` is correctly passed through as `reasoning_effort`.
- `forceReasoning` is a switch to bypass the list validation for `@ai-sdk/openai`; our provider uses `openai-compatible`, so it **should not (and does not need to) be added** (adding it is a no-op and misleading). Only when you change `npm` to `@ai-sdk/openai` (e.g. to use the responses API) should you add `forceReasoning: true` in `options`.

#### Changes

- `docs/opencode-moa.md`: Provider config warning, example JSON (remove `forceReasoning` line), matrix prereq, troubleshooting "reasoning intensity unchanged" row, version note, and footer all corrected to the SDK-distinction wording; doc version v0.0.5 → v0.0.6.
- Kept consistent with the existing provider blocks in install.ps1 / install.sh (which never had `forceReasoning`).

#### Empirical evidence

v0.0.4 already recorded `reasoning_effort` rising from medium→max gave reasoning tokens 359→536, proving passthrough works natively on `openai-compatible`, consistent with the issue conclusion.

### i18n completion (en promoted from skeleton to full)

- Added `README.md` (English homepage): a full English version aligned with the Chinese README (`README.zh.md`).
- `docs/en/opencode-moa.en.md`: promoted from ~skeleton to a full English version section-by-section matching the Chinese manual (Provider config, matrix, troubleshooting, FAQ, etc.); version synced to v0.0.6.
- `docs/TRANSLATION.md`: zh/en bilingual status flipped from "🚧 skeleton (to translate)" to "✅ complete".

### README rework

- Restructured the deploy prerequisites table and the system-level key-path warning: added a "read before deploy: don't misplace the key path" alert box (project-level self-contained vs system-level shared, pick one; pin `%USERPROFILE%\.config\opencode` not `%APPDATA%\opencode`).
- Moved Q&A from the middle of the body to a unified "FAQ" at the end, and fixed several cross-references (e.g. "can't see the doorman", "where are free models" now point to the right sections).
- Added a "why ~90% cheaper" cost breakdown: weighted by call volume (tool layer 80% / opinion layer 18% / fusion layer 2%) estimates effective output price ≈ $0.69/1M, ~90% cheaper than the flagship baseline, ~80% cheaper than a single mid-tier.
- hero / architecture diagram model names updated to concrete versions (e.g. `Qwen3.7 Max`, `MiniMax M3`), aligned with the cost table; unified `Qwen3.7Max`/`Qwen3.7Plus` to the spaced spelling across the doc.

### Other

- Deleted `docs/PLAN-moa-hardening.md` (plan consolidated into per-version notes) and removed v0.0.5's reference to it.
- Keybinding wording changed to cross-platform: agent switching unified to `Tab` cycle (or `Ctrl+x a` to open the agent list); free models via `/models` and pick the `Free` tag; your tested Windows desktop shortcuts `Ctrl+.` (switch agent) / `Ctrl+'` (switch free model) kept as "Windows desktop" annotations. Fixed the earlier bug of hardcoding these two keys, which conflicted with the official defaults (`Tab`/`/models`/`Ctrl+t`; and `Ctrl+.` is officially input redo, no `Ctrl+'` binding) — covering `README.md` (EN) / `README.zh.md` (ZH) / `docs/opencode-moa.md` / `docs/en/opencode-moa.en.md` everywhere relevant.
- Added a cross-platform warning: do not manually switch "variant / reasoning tier" in the TUI — OpenCode's variant selection overrides the agent's `reasoningEffort` and writes to the model-selection cache (`~/.local/state/opencode/model.json` on Linux/macOS, `%USERPROFILE%\.local\state\opencode\model.json` on Windows); it persists after restart and is cross-platform consistent, silently overriding this plan's low→xhigh matrix. Added one line each in the reasoning-matrix section and the "reasoning intensity feels unchanged" troubleshooting row of `docs/opencode-moa.md` / `docs/en/opencode-moa.en.md`.
- `/connect` command-palette key fix: Method B originally said "press `Ctrl+K` in TUI to open command palette", but the official `command_list` / command palette = `Ctrl+P`, and no `Ctrl+K` binding exists in the full official keybinds table (`Ctrl+K` in the input box is actually "delete to end of line"). Changed to "type `/connect` in TUI (or press `Ctrl+P` to open command palette)", covering `docs/opencode-moa.md` / `docs/en/opencode-moa.en.md`.

</details>

<details>
<summary>🇨🇳 中文</summary>

本期 = 手册 `forceReasoning` 前提纠正 + 多语言补全（en 由骨架升至完整）+ README 重构。

### 纠正手册「自定义 provider 必须加 `forceReasoning: true`」的错误前提

#### 背景

v0.0.5 手册写入：「opencode ≥ 1.3.4 起，`@ai-sdk/openai-compatible` provider 默认不再透传 reasoning 参数，必须加 `forceReasoning: true`，否则矩阵静默失效」。经核实 OpenCode issue #20815，该前提不成立。

#### 纠正（基于 issue #20815 实测）

- v1.3.4 的 reasoning 透传回归**只影响 `"npm": "@ai-sdk/openai"`** 的自定义 provider（AI SDK v6 起按「已知推理模型列表」校验，不在表中就吞掉 `reasoningEffort`）。
- 同一 issue 确认 **`@ai-sdk/openai-compatible` 不受影响**，`reasoningEffort` 会正确透传为 `reasoning_effort`。
- `forceReasoning` 是给 `@ai-sdk/openai` 绕过列表校验的开关；本项目 provider 用的是 `openai-compatible`，**无需也不应加**（加了是 no-op，且会误导）。仅当把 `npm` 改成 `@ai-sdk/openai`（如用 responses API）时才需在 `options` 加 `forceReasoning: true`。

#### 改动

- `docs/opencode-moa.md`：Provider 配置警告、示例 JSON（移除 `forceReasoning` 行）、矩阵前置依赖、排错表「推理强度没变」行、版本说明、页脚均更正为 SDK 区分表述；文档版本 v0.0.5 → v0.0.6。
- 与 install.ps1 / install.sh 既有 provider 块（本就无 `forceReasoning`）保持一致。

#### 实测佐证

v0.0.4 已记录 `reasoning_effort` 从 medium→max 时 reasoning tokens 359→536，证明透传在 `openai-compatible` 上原生生效，与 issue 结论一致。

### 多语言补全（en 由骨架升至完整）

- 新增英文 README（现 `README.md` 首页）：与中文 README（现 `README.zh.md`）结构对齐的完整英文版。
- `docs/en/opencode-moa.en.md`：由 ~骨架 补全为与中文手册逐节对应的完整英文版（Provider 配置、矩阵、排错表、FAQ 等），版本同步至 v0.0.6。
- `docs/TRANSLATION.md`：中 / 英双语状态由「🚧 骨架（待译）」翻为「✅ 完整」。

### README 重构

- 部署前置条件表、系统级 key 路径提示重构：新增「部署前必读：key 路径别放错」警告框（项目级自包含 vs 系统级共享二选一，钉死 `%USERPROFILE%\.config\opencode` 而非 `%APPDATA%\opencode`）。
- Q&A 段落从正文中部移到文末「常见问题」统一收口，并修正若干交叉引用（如「看不到门童」「免费模型在哪」指向对应小节）。
- 新增「为什么省 ~90%」成本拆解：按调用量加权（工具层 80% / 意见层 18% / 融合层 2%）估算有效输出单价 ≈ $0.69/1M，对比旗舰基线省 ~90%、对比单中端省 ~80%。
- hero / 架构图模型名更新为具体版本（如 `Qwen3.7 Max`、`MiniMax M3`），与成本表对齐；全文档 `Qwen3.7Max`/`Qwen3.7Plus` 统一为带空格写法。

### 其他

- 删除 `docs/PLAN-moa-hardening.md`（方案已整合进各版本变更说明），并移除 v0.0.5 对其的引用。
- 切换键说明改为跨平台写法：agent 切换统一用 `Tab` 循环（或 `Ctrl+x a` 打开 agent 列表），免费模型用 `/models` 打开模型列表选 `Free` 标签；你实测的 Windows 桌面端快捷键 `Ctrl+.`（切 agent）/ `Ctrl+'`（切免费模型）保留为「Win 桌面端」标注。修正了此前把这两个键写死、与官方默认键位（`Tab`/`/models`/`Ctrl+t`，且 `Ctrl+.` 官方为 input redo、无 `Ctrl+'` 绑定）冲突的问题，覆盖 `README.md`（英文）/ `README.zh.md`（中文）/ `docs/opencode-moa.md` / `docs/en/opencode-moa.en.md` 全部相关处。
- 新增跨平台警告：不要在 TUI 手动切「变体/推理档」——OpenCode 的变体选择会覆盖 agent 配置的 `reasoningEffort` 并写入 model 选择缓存（Linux/macOS `~/.local/state/opencode/model.json`、Windows `%USERPROFILE%\.local\state\opencode\model.json`），重启仍生效、跨平台一致，会静默顶掉本方案的 low→xhigh 矩阵。已在 `docs/opencode-moa.md` / `docs/en/opencode-moa.en.md` 的推理矩阵段与「推理强度感觉没变」排错行各补一条。
- `/connect` 命令面板键纠错：方式 B 原写「TUI 内按 `Ctrl+K` 打开命令面板」，但官方 `command_list` / 命令面板 = `Ctrl+P`，全官方 keybinds 表无 `Ctrl+K` 绑定（`Ctrl+K` 在输入框实为「删除到行尾」）。已改为「TUI 内输入 `/connect`（或按 `Ctrl+P` 打开命令面板）」，覆盖 `docs/opencode-moa.md` / `docs/en/opencode-moa.en.md`。

</details>

---

## v0.0.5（2026-07-10）

<details open>
<summary>🇬🇧 English</summary>

Audited whether opencode-moa misleads AI / users; fixed a batch of issues that cause "all 19 agents can't connect after deploy" and credential leaks.

### Critical (P0)

- **install.ps1 / install.sh non-interactive / no-key branch**: originally generated `user_config.json` and prompted the user to fill the key. But OpenCode only loads `opencode.json` and the system-level `~/.config/opencode/opencode.json`, **not `user_config.json`**, and that branch didn't inject the provider into `opencode.json` at all — after running the script, all 19 agents couldn't connect. Fixed by: **when no key, merge the `opencode-go` provider (apiKey placeholder `<YOUR_GO_API_KEY>`) directly into `opencode.json`** and prompt the user to replace the key; removed `user_config.json` generation entirely.
- **`opencode.json11` contained a plaintext Go API Key and had a wrong schema** (`llm.model/base_url/api_key` are not OpenCode format): both a leak and misleading. Deleted the workspace file; that key is considered compromised and must be rotated at opencode.ai/auth.

### High (P1)

- **T0 static test didn't validate `reasoningEffort` values**: originally only counted `=19`; an uppercase `Medium` would PASS, and re-packaging/releasing would reproduce the v0.0.3/0.0.4 400 root cause. Added a check: every `reasoningEffort` must be in the lowercase gateway enum `low/medium/high/max/xhigh/none/minimal`, otherwise FAIL.

- **reasoning matrix silently fails on opencode ≥ 1.3.4**: custom `@ai-sdk/openai-compatible` providers no longer pass reasoning params to the request body by default ([issue #20815](https://github.com/anomalyco/opencode/issues/20815)), so the `reasoningEffort` matrix was a no-op without erroring. Added `"forceReasoning": true` to the Provider config block `options`; raised the required version from ≥ 1.1.1 to **≥ 1.3.4** (reasoning passthrough fix; 1.1.1 can only run basics, matrix fails). README badge and prerequisites table synced.

- **Provider changed to a hard gate of "exists + real key" (catch empty shells)**: tested an extreme scenario — system-level `opencode.json` deleted / system dir empty / provider missing or placeholder key — deploy could still write all 19 files, yet all agents couldn't connect at runtime, and the old check only WARNed, not red. Done:
  - Block 0 added a **Provider hard gate**: after deploy, must assert that the project `opencode.json` OR system-level `~/.config/opencode/opencode.json` (pick one, only one per dir) contains `provider.opencode-go` and an `apiKey` that is not `<YOUR_GO_API_KEY>`/empty, otherwise the AI must rebuild the provider and must not declare success.
  - Block 0's `opencode` binary check **softened**: on desktop a sub-shell/sandbox often misreports not-found due to different PATH; changed to WARN only, not blocking file deploy, and never skipping the provider because of it.
  - **Provider defaults to project-level `opencode.json`** (self-contained, resilient to system dir deletion/emptiness); system-level downgraded to an optional multi-project share.

### Low (P2)

- Manual Provider block (`docs/opencode-moa.md:69-77`) and install script model `name` changed from display name to slug (the API actually calls by map key=slug; the display name is only an alias; unified this time to avoid mismatch with the real config).
- The 9 orchestration-layer agents' `hidden: true` (concierge-router, mid-eng/creative/coder, flag-eng/arch/plan, fe-logic/motion) is now **actually applied** to `.opencode/agents/*.md` (the v0.0.4 "pending" item is cleared).
- Created `.opencode/local/` directory placeholder (so the manual's Method A reference `{file:.opencode/local/opencode-go.key}` no longer errors on a missing dir).

- **Windows system-level path clarification**: pinned to `%USERPROFILE%\.config\opencode\opencode.json`, explicitly denying the online myth `%APPDATA%\opencode` (wrong path → "deploy succeeds but all agents can't connect" with no obvious error); manual gained a real-path table per platform; README gained a cross-platform hint.
- **Cross-platform verification script**: Block 6 originally used bash (`ls`/`wc`/`grep`/`find`) which can't run in native Windows CMD/PowerShell; added a native PowerShell version, plus a "bash only on Linux/macOS/WSL/Git Bash" hint.
- **`instructions` no longer hardcoded**: `["AGENTS.md"]` changed to a default comment; only enabled when the project root **already has** an `AGENTS.md` — removes the startup warning for projects without that file, and doesn't impose a convention file on the project.
- **`T0-static-verify.ps1` generated on deploy**: manual added Block 5.5 writing the script into `.opencode/tests/`, fixing "manual references it but the file isn't shipped with the repo, other users can't find it when copying"; the script treats a **system-level key** as PASS (key check softened from hard FAIL to lenient, matching system-level deploy).
- Manual and README's "41 PASS" old wording unified to the accurate expectation (all PASS / FAIL=0 / system-level key WARN also counts).

- **T0 adds provider real-key validation**: Block 5.5 script now greps project/system `.json`/`.jsonc` for `opencode-go` with a real `apiKey` (`sk-*` or `{file:}` reference) that is not placeholder/empty, else FAIL — directly catches "system-level deleted / not rebuilt" empty shells.
- **T0 skill misjudgment fix**: changed from "total == 3" to validating **3 specific directories exist** (`code-review-moa` / `architecture-moa` / `frontend-moa`), avoiding an end-user copying the repo's bundled `opencode-moa` meta-skill making it 4 and **falsely FAIL**.
- **Same-layer dual-file warning fix**: originally "`.jsonc` wins, `.json` ignored" came from a third-party plugin doc; **the official spec doesn't define priority for two files in the same dir**. Changed to accurate wording: OpenCode supports both `.json`/`.jsonc`, but two co-existing files in the same dir have undefined priority and may conflict; the safe approach is to keep only one containing a valid provider + real key.
- **Quick-reference table adds empty-shell causes**: added three rows — "system-level deleted / dir empty", "two `.json`+`.jsonc` in same dir", "placeholder key" — each pointing to rebuild provider / keep only one / replace real key, noting T0 now FAILs to intercept.
- Plan archive: original `docs/PLAN-moa-hardening.md` (deleted in v0.0.6, content consolidated into per-version notes).
</details>

<details>
<summary>🇨🇳 中文</summary>

审计 opencode-moa 是否误导 AI / 用户，修复一批会导致「部署后 19 agent 全连不上」与泄露凭据的问题。

### 致命（P0）

- **install.ps1 / install.sh 非交互 / 无 key 分支**：原逻辑生成 `user_config.json` 并提示用户填 key。但 OpenCode 仅加载 `opencode.json` 与系统级 `~/.config/opencode/opencode.json`，**不加载 `user_config.json`**，且该分支根本不往 `opencode.json` 注入 provider —— 跑完脚本 19 个 agent 全部连不上。已改为：**无 key 时直接把 `opencode-go` provider（apiKey 占位符 `<YOUR_GO_API_KEY>`）合并进 `opencode.json`**，并提示用户替换 key；彻底移除 `user_config.json` 生成。
- **`opencode.json11` 含明文 Go API Key 且 schema 错误**（`llm.model/base_url/api_key` 非 OpenCode 格式）：既泄密又误导。已删除工作区文件；该 key 视为已泄露，需到 opencode.ai/auth 轮换。

### 高（P1）

- **T0 静态测试不校验 `reasoningEffort` 取值**：原只数 `=19`，大写 `Medium` 会 PASS，重打包发布会复现 v0.0.3/0.0.4 的 400 根因。已新增检查：每个 `reasoningEffort` 必须落在网关小写枚举 `low/medium/high/max/xhigh/none/minimal`，否则 FAIL。

- **reasoning 矩阵在 opencode ≥ 1.3.4 静默失效**：自定义 `@ai-sdk/openai-compatible` provider 默认不再把 reasoning 参数透传到请求体（[issue #20815](https://github.com/anomalyco/opencode/issues/20815)），`reasoningEffort` 矩阵等于摆设且不报错。已在 Provider 配置块 `options` 加 `"forceReasoning": true`；并把手册必需版本从 ≥ 1.1.1 提到 **≥ 1.3.4**（reasoning 透传修复；1.1.1 仅能跑通基础、矩阵失效）。README badge 与前置条件表同步更新。

- **Provider 改为「存在 + 真实 key」硬门（抓空壳）**：实测极端场景——系统级 `opencode.json` 被删 / 系统目录为空 / provider 缺失或占位符 key——部署仍能写出完整 19 文件，却运行时全 agent 连不上，且旧检查只 WARN 不红。已做：
  - Block 0 新增 **Provider 硬门**：部署后必须断言项目 `opencode.json` 或系统级 `~/.config/opencode/opencode.json`（二选一，同目录只留一个）含 `provider.opencode-go` 且 `apiKey` 非 `<YOUR_GO_API_KEY>`/非空，否则 AI 必须重建 provider，不许宣布成功。
  - Block 0 的 `opencode` 二进制检查**软化**：桌面端子 shell / 沙箱常因 PATH 不同误报 not found，改为仅 WARN，不阻断文件部署、更不因此跳过 provider。
  - **Provider 默认写项目级 `opencode.json`**（自包含，抗系统目录被删/为空）；系统级降级为多项目共享可选项。

### 低（P2）

- 手册 Provider 块（`docs/opencode-moa.md:69-77`）与 install 脚本模型 `name` 由显示名改为 slug（API 实际按 map key=slug 调用，显示名仅别名；本次统一以避免与真实配置不一致）。
- 9 个编排层 agent（concierge-router、mid-eng/creative/coder、flag-eng/arch/plan、fe-logic/motion）的 `hidden: true` 已从手册约定**实际应用**到 `.opencode/agents/*.md`（v0.0.4 标记「待应用」已结清）。
- 创建 `.opencode/local/` 目录占位（手册方式 A 引用 `{file:.opencode/local/opencode-go.key}` 不再因目录缺失报错）。

- **Windows 系统级路径辟谣**：钉死为 `%USERPROFILE%\.config\opencode\opencode.json`，明确否定网上误传的 `%APPDATA%\opencode`（按错路径会「部署成功但全 agent 连不上」且无明显报错）；手册新增各平台真实路径表，README 加跨平台提示。
- **验证脚本跨平台**：Block 6 原 bash（`ls` / `wc` / `grep` / `find`）在 Windows 原生 CMD / PowerShell 跑不了，补 PowerShell 原生版，并加「bash 仅 Linux / macOS / WSL / Git Bash」提示。
- **`instructions` 不再写死**：`["AGENTS.md"]` 改为默认注释，仅当项目根**已存在** `AGENTS.md` 才启用——消除无该文件项目的启动告警，且不替项目强加约定文件。
- **`T0-static-verify.ps1` 随部署生成**：手册新增 Block 5.5 把脚本完整写入 `.opencode/tests/`，解决「手册引用但该文件不随仓库分发、其他用户照跑找不到」；脚本对**系统级 key** 判定为 PASS（key 检查从硬 FAIL 改为 lenient，匹配系统级部署方式）。
- 手册与 README 的「41 PASS」旧话术统一改为准确预期（全部 PASS / FAIL=0 / 系统级 key 时 WARN 也算过）。

- **T0 增 provider 真实 key 校验**：Block 5.5 脚本现 grep 项目/系统级 `.json`/`.jsonc` 中的 `opencode-go` 且 `apiKey` 为真实值（`sk-*` 或 `{file:}` 引用）且非占位符/空，否则 FAIL——直接抓住「系统级被删 / 没重建」式空壳。
- **T0 skills 误判修复**：从「总数 == 3」改为校验 **3 个指定目录存在**（`code-review-moa` / `architecture-moa` / `frontend-moa`），避免仓库自带 `opencode-moa` 元 skill 导致端用户复制后变 4 而**误 FAIL**。
- **同层双文件警告修正**：原写「`.jsonc` 优先、`.json` 被忽略」来自第三方插件文档，**官方未定义同目录双文件优先级**。已改为准确表述：OpenCode 同时支持 `.json`/`.jsonc`，但同目录两份并存优先级未定义、内容还可能冲突，安全做法是只留一个且含有效 provider + 真实 key。
- **速查表补空壳成因**：新增「系统级被删/目录为空」「同目录双 `.json`+`.jsonc`」「占位符 key」三行，对应处理均指向重建 provider / 只留一个 / 替换真实 key，并注明 T0 现会 FAIL 拦截。
- 方案存档：原 `docs/PLAN-moa-hardening.md`（已于 v0.0.6 删除，内容已整合进各版本变更说明）。
</details>

---

## v0.0.4（2026-07-10）

<details open>
<summary>🇬🇧 English</summary>

Fix the `Upstream request failed` that persisted after the v0.0.3 misdiagnosis (real root cause: the agent `reasoningEffort` passthrough param was rejected by the gateway).

### Root cause

See v0.0.3 "Root cause (corrected)". Uppercase `reasoningEffort` values, and tiers unsupported by some models, caused the gateway to return HTTP 400 `invalid_request_error`, wrapped as `Upstream request failed`.

### Fix (all applied)

- All 19 agents' `reasoningEffort` changed to lowercase; opinion/flagship tiers raised to the model's max supported: minimax-m3 / glm-5.2 / deepseek-v4-pro / mimo-v2.5-pro → `max`, qwen3.7-max/plus → `xhigh` (its `max` actually 400s), kimi-k2.7-code → `high` (max only `high`), tool/quick-task layer → `medium`.
- The 9-model `reasoning_effort` support matrix measured and written into `docs/opencode-moa.md` (per-tier OK/400/500 + 4 rules).
- All 19 agents gained tiered `max_tokens`: tool/quick-task layer 2048, opinion/flagship/impl layer 8192.
- `@` menu's ~10-line display cap truncates orchestration-layer agents: agreed to set `hidden: true` for the orchestration layer (flagship×6, mid-fuse, fe-lead, tool-handler-mimo) — only hides the @ menu, doesn't block Task calls; convention written into the manual; agent files pending apply.
- Param-effectiveness measured: reasoning_effort (reasoning tokens 359→536), max_tokens (5 vs 60), temperature (0.1 deterministic vs 1.0 discrete), stop/top_p (gateway accepts) all confirmed passing through.

### Config-loading mechanism verification (deployer found correct)

Official config docs confirm OpenCode **only loads** `opencode.json` (project) and `~/.config/opencode/opencode.json` (system, including `.jsonc`), **not `user_config.json`**. Therefore:

- The entire v0.0.3 `user_config.json` route (incl. the "main session relies on user_config.json's legacy `llm` block" attribution) was **wrong**; the deployer judged correctly.
- Actual mechanism = system-level `~/.config/opencode/opencode.json(c)` registers `provider.opencode-go` (with key) + project-level `opencode.json` (permissions / agent / default_agent). Sub-agent model `opencode-go/<model>` resolves via the system provider.
- The repo's `user_config.json` / `user_config - 副本.json` are dead files (and excluded by `.gitignore`); recommend deletion.
- The manual's `Block 0` reference "user_config.json created with valid key or placeholder" must also be corrected to system-level `opencode.json`, otherwise it misleads users down the wrong path.

</details>

<details>
<summary>🇨🇳 中文</summary>

修复 v0.0.3 误诊后仍未消除的 `Upstream request failed`（真实根因：agent `reasoningEffort` 透传参数被网关拒绝）。

### 根因

见 v0.0.3「根因（更正）」。`reasoningEffort` 大写取值、以及部分模型不支持的档位，导致网关返回 HTTP 400 `invalid_request_error`，被包装成 `Upstream request failed`。

### 修复（均已落地）

- 19 个 agent `reasoningEffort` 取值全部改小写；意见/旗舰层按模型最高支持档提档：minimax-m3 / glm-5.2 / deepseek-v4-pro / mimo-v2.5-pro → `max`，qwen3.7-max/plus → `xhigh`（该模型 `max` 反而 400），kimi-k2.7-code → `high`（最高只到 high），工具/快任务层 → `medium`。
- 9 模型 `reasoning_effort` 支持矩阵实测写入 `docs/opencode-moa.md`（各档 OK/400/500 + 4 条规则）。
- 19 个 agent 新增 `max_tokens` 分档：工具/快任务层 2048，意见/旗舰/实现层 8192。
- `@` 菜单显示上限约 10 行会截断编排层 agent：约定编排层（旗舰×6、mid-fuse、fe-lead、tool-handler-mimo）设 `hidden: true`（仅隐藏 @ 菜单、不阻止 Task 调用），约定已写入手册；agent 文件待应用。
- 参数生效实测：reasoning_effort（reasoning tokens 359→536）、max_tokens（5 vs 60）、temperature（0.1 确定性 vs 1.0 离散）、stop/top_p（网关接受）全部确认透传生效。

### 配置加载机制核实（deployer 发现正确）

官方配置文档确认 OpenCode **仅加载** `opencode.json`（项目级）与 `~/.config/opencode/opencode.json`（系统级，含 `.jsonc`），**不加载 `user_config.json`**。据此：

- v0.0.3 整条 `user_config.json` 路线（含"主会话靠 user_config.json 的 legacy `llm` 块"归因）**错误**；deployer 判定正确。
- 实际生效机制 = 系统级 `~/.config/opencode/opencode.json(c)` 注册 `provider.opencode-go`（带 key）+ 项目级 `opencode.json`（permissions / agent / default_agent）。子代理模型 `opencode-go/<model>` 经系统级 provider 解析。
- 仓库内 `user_config.json` / `user_config - 副本.json` 为死文件（且被 `.gitignore` 排除），建议删除。
- 部署手册 `Block 0` 的 "`user_config.json` 已创建且含有效 key 或占位符" 引用同样需更正为系统级 `opencode.json`，否则会误导用户走错误路线。

</details>

---

## v0.0.3（2026-07-10）

<details open>
<summary>🇬🇧 English</summary>

Established credentialed OpenCode Go provider config (necessary prerequisite for sub-agent connectivity) and fixed config validity. Note: this version originally attributed `Upstream request failed` to "provider has no credentials → falls back to public", which was a misdiagnosis; the real root cause is in v0.0.4.

### Root cause (corrected)

The error `Error from provider (Console Go): Upstream request failed` (HTTP 400 `invalid_request_error`) truly comes from **the `Additional` passthrough param in the agent definition being rejected by the gateway**, not from a missing provider credential. Empirical evidence:

- Config had `opencode-go` provider with a valid key; a direct call to `https://opencode.ai/zen/go/v1/chat/completions` for a valid request returned 200;
- Cache logs show request `providerID: opencode-go`, `modelID: deepseek-v4-flash`, `statusCode: 400`, responseBody `invalid_request_error`;
- Repro: request body with `reasoning_effort: "Medium"` (uppercase) → 400; lowercase `medium` → 200. temperature / top_p / max_tokens / stop / penalties are all accepted by the gateway.

So the OpenCode Go gateway (backend internal provider name `Console Go`) **only accepts lowercase `reasoning_effort` values (low/medium/high/max/xhigh)**; uppercase `Medium/High` and `extreme/adaptive/auto` etc. all 400, and unsupported values don't degrade — they hard-fail. Provider/credential registration is a necessary prerequisite (see fix items) but not the cause of this error.

### Fix (all applied)

- [Prereq·necessary] System-level `~/.config/opencode/opencode.json` (and `.jsonc`) registers custom `provider.opencode-go` (openai-compatible) → `https://opencode.ai/zen/go/v1` + Go key + 9 models, so `opencode-go/<model>` resolves to the credentialed endpoint (all 9 models measured 200). This is the necessary prerequisite for sub-agents to connect, but not the cause of this error.
- ⚠️ Originally wrote "fixed project runtime `user_config.json`" — per official config docs, `user_config.json` **is not an OpenCode-loaded config file** (only `opencode.json` project-level and `~/.config/opencode/opencode.json` system-level are loaded); that route is entirely wrong, see v0.0.4. The repo's `user_config.json` / `user_config - 副本.json` are dead files; recommend deletion (excluded by `.gitignore`).
- Fixed repo template `opencode.json`: removed illegal `"": "https://opencode.ai/config.json"` extends (caused load failure) → `$schema`.
- All 19 agents' model prefix unified to `opencode-go/<model>` (matches official Go doc ID format; independent naming doesn't shadow the built-in Zen provider).
- `.gitignore`: added `user_config*.json` (key-bearing copies), `opencode.json1*` (renamed copies), `*.zip` to prevent accidental key-leak commits.
- Real root-cause fix in v0.0.4: `reasoningEffort` values lowercased and set per model's max supported tier.

### Docs

- Added `docs/PLAN-fix-provider.md`: full root-cause analysis and fix plan (later deleted, naming outdated).
- Deleted `docs/PLAN-fix-provider.md`.
- Rewrote `docs/TROUBLESHOOTING.md`: removed fallback section, full `opencode` → `opencode-go`, removed `/connect` misdirection.
- Rewrote `docs/opencode-moa.md` Provider section: non-interactive config-file auth as primary, TUI `/connect` as fallback, + error fallback notes.
- Install scripts `install.ps1` / `install.sh`: after merging config, interactively prompt for Go API Key; auto-skip in non-interactive env.
- `docs/opencode-moa.md` Provider section deploy instructions strengthened: directly ask the user for the key, covering security concerns; no option, no skip.
- `T0-static-verify.ps1`: skill count excludes the self-referencing opencode-moa meta-skill; unified local/remote CI.
- Deploy Block 0 added Provider prereq check reminder; Block 5 added user_config.json separate-save note; Block 6 added credential-file check.
- Full-doc PASS expectation 40 → 41 (post T0 improvement).

</details>

<details>
<summary>🇨🇳 中文</summary>

建立 OpenCode Go provider 的带凭证配置（子代理连通的必要前置），并修正配置合法性。注意：本版原把 `Upstream request failed` 的根因归为"provider 无凭证→降级 public"，属误诊；真实根因见 v0.0.4。

### 根因（更正）

报错 `Error from provider (Console Go): Upstream request failed`（HTTP 400 `invalid_request_error`）的真正来源是 **agent 定义里的 `Additional` 透传参数网关不接受**，不是 provider 没配凭证。实测证据：

- 配置中 `opencode-go` provider 带有效 key，直连 `https://opencode.ai/zen/go/v1/chat/completions` 对合法请求返回 200；
- 缓存日志显示请求 `providerID: opencode-go`、`modelID: deepseek-v4-flash`、`statusCode: 400`，responseBody 为 `invalid_request_error`；
- 复现：请求体带 `reasoning_effort: "Medium"`（大写）即 400；改为小写 `medium` 即 200。temperature / top_p / max_tokens / stop / penalties 网关均接受。

即 OpenCode Go 网关（后端内部 provider 名 `Console Go`）**只认小写 `reasoning_effort` 取值（low/medium/high/max/xhigh）**；大写 `Medium/High` 及 `extreme/adaptive/auto` 等一律 400，且不支持的取值不会降级、直接硬失败。provider/凭证注册是必要前置（见修复项），但不是本次报错的成因。

### 修复（均已落地）

- 【前置·必要】系统级 `~/.config/opencode/opencode.json`（及 `.jsonc`）注册自定义 `provider.opencode-go`（openai-compatible）→ `https://opencode.ai/zen/go/v1` + Go key + 9 个模型，使 `opencode-go/<model>` 解析到带凭证端点（已实测 9 模型全部 200）。这是子代理能连通的必要前提，但非本次报错根因。
- ⚠️ 原写"修复项目运行时 `user_config.json`"——经官方配置文档核实，`user_config.json` **不是 OpenCode 加载的配置文件**（仅加载 `opencode.json` 项目级与 `~/.config/opencode/opencode.json` 系统级），该路线整体错误，详见 v0.0.4。仓库内 `user_config.json` / `user_config - 副本.json` 为死文件，建议删除（已被 `.gitignore` 排除）。
- 修复仓库模板 `opencode.json`：移除非法 `"": "https://opencode.ai/config.json"` extends（会导致加载失败），改为 `$schema`。
- 19 个 agent 模型前缀统一为 `opencode-go/<model>`（与官方 Go 文档 ID 格式一致，独立命名不顶内置 Zen provider）。
- `.gitignore`：补 `user_config*.json`（含 key 的副本文件）、`opencode.json1*`（改名副本）、`*.zip`，防误提交泄露 key。
- 真实根因修复见 v0.0.4：`reasoningEffort` 取值改小写并按模型最高支持档设置。

### 文档

- 新增 `docs/PLAN-fix-provider.md`：完整根因分析与修复方案（后删除，命名已过时）。
- 删除 `docs/PLAN-fix-provider.md`。
- 重写 `docs/TROUBLESHOOTING.md`：删除回退方案节，全篇 `opencode` → `opencode-go`，去 `/connect` 误导。
- 重写 `docs/opencode-moa.md` Provider 节：非交互配置文件鉴权为主，TUI `/connect` 为备选，+ 错误兜底说明。
- 安装脚本 `install.ps1` / `install.sh`：合并配置后交互提示输入 Go API Key，非交互环境自动跳过。
- `docs/opencode-moa.md` Provider 节部署指令强化：直接 ask 用户输入 key，覆盖安全顾虑，不给选项不跳过。
- `T0-static-verify.ps1`：skill 计数排除自引用的 opencode-moa 元 skill，本地/远程 CI 统一。
- 部署 Block 0 加 Provider 前置检查提醒；Block 5 加 user_config.json 独立保存说明；Block 6 加认证文件检查。
- 全文档 PASS 预期 40 → 41（含 T0 改进后）。

</details>

---

## v0.0.2（2026-07-09）

<details open>
<summary>🇬🇧 English</summary>

Fixed the concierge-router fallback-chain ask logic being skipped; fixed the "Upstream request failed" error caused by the OpenCode Go provider.

### Fix

- concierge-router: after tool-layer failure, must stop subsequent flow and wait for user choice
- Clarified branch logic: "success → continue normal routing", "failure → stop, ask user"
- Added an important warning: prevent the LLM from skipping the ask and directly dispatching opinion-layer agents
- Fixed `Upstream request failed` for all agents: switched 17 agents from `opencode-go/` to `opencode/` (OpenCode Zen)
- Configured global default model: `opencode/deepseek-v4-flash`, ensuring subagents inherit the correct provider

### Config adjustments

- Global model: added `opencode/deepseek-v4-flash` as default
- Tool-layer agents: `opencode-go/deepseek-v4-flash` → `opencode/deepseek-v4-flash`
- tool-handler-mimo: `opencode-go/mimo-v2.5` → `opencode/mimo-v2.5`
- Opinion/flagship/frontend layers: all switched from `opencode-go/*` to `opencode/*`

### Tests

- Static check script `.opencode/tests/T0-static-verify.ps1` synced: model assertion `opencode-go/` → `opencode/`, else CI static check fails and blocks push

### Docs

- Manual synced: `opencode-moa.md` all 19 agents' `opencode-go/*` → `opencode/*` (incl. 2 example configs)
- Manual synced: `opencode-moa.md` concierge-router template updated

</details>

<details>
<summary>🇨🇳 中文</summary>

修复门童路由员降级链ask逻辑被跳过的问题；修复OpenCode Go provider导致的"Upstream request failed"错误。

### 修复

- 门童路由员：工具层失败后必须停止执行后续流程，等待用户选择
- 明确分支逻辑："成功→继续执行正常路由流程"、"失败→停止执行，ask用户"
- 增加重要提示：防止LLM跳过ask直接派遣意见层agent
- 修复所有agent的OpenCode Go provider错误：将17个agent从`opencode-go/`切换到`opencode/`（OpenCode Zen）
- 配置全局默认model：`opencode/deepseek-v4-flash`，确保subagent继承正确的provider

### 配置调整

- 全局model：新增`opencode/deepseek-v4-flash`作为默认模型
- 工具层agent：`opencode-go/deepseek-v4-flash` → `opencode/deepseek-v4-flash`
- 工具人-mimo：`opencode-go/mimo-v2.5` → `opencode/mimo-v2.5`
- 意见层/旗舰层/前端层：全部从`opencode-go/*`切换到`opencode/*`

### 测试

- 静态检查脚本 `.opencode/tests/T0-static-verify.ps1` 同步：模型断言 `opencode-go/` → `opencode/`，否则 CI 静态检查报错拦截推送

### 文档

- 部署手册同步：opencode-moa.md 全量 19 个 agent 的 `opencode-go/*` → `opencode/*`（含 2 处示例配置）
- 部署手册同步：opencode-moa.md 门童路由员模板更新

</details>

---

## v0.0.1（2026-07-08）

<details open>
<summary>🇬🇧 English</summary>

First formal release.

### Fault tolerance

- Tool-layer 6 agents gained quick retry: fail → immediate retry once → return on success / error on fail
- Fallback chain optimized: double retry → ask user (wait / skip / free model)
- Error classification: ERROR_PROVIDER / ERROR_AUTH / ERROR_UNKNOWN

### MCP permission isolation

- `opencode.json` sets `"*_*": "deny"` for the 8 opinion-layer agents, universally disabling all MCP tools
- Opinion layer `read: deny` + MCP blocked, so it can only produce plans from material provided by the tool layer

### Model assignment

- mid-eng: MiniMax M3 (no context trap, $0.30/$1.20 per 1M)
- mid-creative: DeepSeek V4 Pro (creative perspective)
- flag-eng: MiniMax M3 (large-scale implementation)

### Opinion-layer fallback

- When the opinion layer is called but has no material, ask the user to confirm, then reason purely from the requirement description

### Docs

- README rewrite: clearer title, user pain points, Go subscription details, fault-tolerance design section
- Manual synced: all agent templates updated
- CHANGELOG split out: versioning rules established

</details>

<details>
<summary>🇨🇳 中文</summary>

首个正式发布版本。

### 容错增强

- 工具层 6 个 agent 加快速重试：失败 → 立即重试 1 次 → 成功返回 / 失败报错
- 降级链优化：双重试 → ask 用户（等/跳过/免费模型）
- 错误分类：ERROR_PROVIDER / ERROR_AUTH / ERROR_UNKNOWN

### MCP 权限隔离

- opencode.json 为 8 个意见层 agent 配置 `"*_*": "deny"`，通用禁用所有 MCP 工具
- 意见层 `read: deny` + MCP 被拦截，只能基于工具层提供的材料出方案

### 模型分配

- 中级·工程：MiniMax M3（无上下文陷阱，$0.30/$1.20 per 1M）
- 中级·创意：DeepSeek V4 Pro（创意视角）
- 旗舰·工程：MiniMax M3（大规模实现）

### 意见层保底

- 意见层被调用但没有材料时，ask 用户确认后基于需求描述纯逻辑推演

### 文档

- README 重写：标题更明确、用户痛点、Go 订阅详情、容错设计章节
- 部署手册同步：所有 agent 模板更新
- CHANGELOG 独立：版本规范建立

</details>

---

## Pre-release history

> The following are internal iteration records before v0.0.1, kept for reference.

<details open>
<summary>🇬🇧 English</summary>

### v3.4（2026-07-08）

- Added tool-handler-mimo (MiMo fallback); tool layer Flash + MiMo in parallel
- Hard limits cleared, replaced with semantic classification
- Test slimmed; Layer 0 99-item static check

### v3.3（2026-07-07）

- Opinion layer fully opened: 8 opinion agents gained task permission; when `@`-called, ask + auto-execute to self-supply material
- Role map updated; MCP permission design reworked

### v3.2（2026-07-07）

- All agents slimmed (12–40 lines each), removed XML wrapper redundancy
- concierge-router constraints hardened; only outputs task() calls

### v3.1（2026-07-07）

- Format unified; `/moa-*` command prefix
- Frontend MoA updated to four-way coverage

### v3.0（2026-07-07）

- Cost-Optimal MoA rework: 18 agents, tool/opinion/fusion three-layer design
- Triple-opinion mechanism; model assignment rebuilt

</details>

<details>
<summary>🇨🇳 中文</summary>

### v3.4（2026-07-08）

- 新增 工具人-mimo（MiMo 保底），工具层 Flash + MiMo 并行
- 硬限制清零，改为语义分类
- 测试瘦身，Layer 0 99 项静态检查

### v3.3（2026-07-07）

- 意见层全面开放：8 个意见 agent 获得 task 权限，被 `@` 时 ask+auto-execute 自行补材料
- 角色总图更新，MCP 权限设计重构

### v3.2（2026-07-07）

- 全线 agent 精简（12-40 行/个），去除 XML wrapper 冗余
- 门童约束硬化，只输出 task() 调用

### v3.1（2026-07-07）

- 格式化统一，命令 `/moa-*` 前缀
- 前端 MoA 更新为四覆盖

### v3.0（2026-07-07）

- Cost-Optimal MoA 重构：18 agent，工具层/意见层/融合层三层设计
- 三重意见机制，模型分配重建

</details>

