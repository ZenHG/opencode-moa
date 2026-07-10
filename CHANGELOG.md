# Changelog

## 版本规范

- 格式：`v0.X.Y`（语义化版本：主版本.次版本.修订号）
- 修订号（Y）：小修、文档更新、配置调整
- 次版本号（X）：新增功能、模型调整、agent 改动
- 主版本号：架构重构
- 不跳版本号，每次改动只升一级

---

## v0.0.5（2026-07-10）

审计 opencode-moa 是否误导 AI / 用户，修复一批会导致「部署后 19 agent 全连不上」与泄露凭据的问题。

### 致命（P0）

- **install.ps1 / install.sh 非交互 / 无 key 分支**：原逻辑生成 `user_config.json` 并提示用户填 key。但 OpenCode 仅加载 `opencode.json` 与系统级 `~/.config/opencode/opencode.json`，**不加载 `user_config.json`**，且该分支根本不往 `opencode.json` 注入 provider —— 跑完脚本 19 个 agent 全部连不上。已改为：**无 key 时直接把 `opencode-go` provider（apiKey 占位符 `<YOUR_GO_API_KEY>`）合并进 `opencode.json`**，并提示用户替换 key；彻底移除 `user_config.json` 生成。
- **`opencode.json11` 含明文 Go API Key 且 schema 错误**（`llm.model/base_url/api_key` 非 OpenCode 格式）：既泄密又误导。已删除工作区文件；该 key 视为已泄露，需到 opencode.ai/auth 轮换。

### 高（P1）

- **T0 静态测试不校验 `reasoningEffort` 取值**：原只数 `=19`，大写 `Medium` 会 PASS，重打包发布会复现 v0.0.3/0.0.4 的 400 根因。已新增检查：每个 `reasoningEffort` 必须落在网关小写枚举 `low/medium/high/max/xhigh/none/minimal`，否则 FAIL。

### 低（P2）

- 手册 Provider 块（`docs/opencode-moa.md:69-77`）与 install 脚本模型 `name` 由显示名改为 slug（API 实际按 map key=slug 调用，显示名仅别名；本次统一以避免与真实配置不一致）。
- 9 个编排层 agent（门童路由员、中级·工程/创意/码农、旗舰·工程/架构/规划、前端·逻辑/动效）的 `hidden: true` 已从手册约定**实际应用**到 `.opencode/agents/*.md`（v0.0.4 标记「待应用」已结清）。
- 创建 `.opencode/local/` 目录占位（手册方式 A 引用 `{file:.opencode/local/opencode-go.key}` 不再因目录缺失报错）。

### 高（P1）

- **reasoning 矩阵在 opencode ≥ 1.3.4 静默失效**：自定义 `@ai-sdk/openai-compatible` provider 默认不再把 reasoning 参数透传到请求体（[issue #20815](https://github.com/anomalyco/opencode/issues/20815)），`reasoningEffort` 矩阵等于摆设且不报错。已在 Provider 配置块 `options` 加 `"forceReasoning": true`；并把手册必需版本从 ≥ 1.1.1 提到 **≥ 1.3.4**（reasoning 透传修复；1.1.1 仅能跑通基础、矩阵失效）。README badge 与前置条件表同步更新。

### 低（P2）

- **Windows 系统级路径辟谣**：钉死为 `%USERPROFILE%\.config\opencode\opencode.json`，明确否定网上误传的 `%APPDATA%\opencode`（按错路径会「部署成功但全 agent 连不上」且无明显报错）；手册新增各平台真实路径表，README 加跨平台提示。
- **验证脚本跨平台**：Block 6 原 bash（`ls` / `wc` / `grep` / `find`）在 Windows 原生 CMD / PowerShell 跑不了，补 PowerShell 原生版，并加「bash 仅 Linux / macOS / WSL / Git Bash」提示。
- **`instructions` 不再写死**：`["AGENTS.md"]` 改为默认注释，仅当项目根**已存在** `AGENTS.md` 才启用——消除无该文件项目的启动告警，且不替项目强加约定文件。
- **`T0-static-verify.ps1` 随部署生成**：手册新增 Block 5.5 把脚本完整写入 `.opencode/tests/`，解决「手册引用但该文件不随仓库分发、其他用户照跑找不到」；脚本对**系统级 key** 判定为 PASS（key 检查从硬 FAIL 改为 lenient，匹配系统级部署方式）。
- 手册与 README 的「41 PASS」旧话术统一改为准确预期（全部 PASS / FAIL=0 / 系统级 key 时 WARN 也算过）。

### 高（P1）

- **Provider 改为「存在 + 真实 key」硬门（抓空壳）**：实测极端场景——系统级 `opencode.json` 被删 / 系统目录为空 / provider 缺失或占位符 key——部署仍能写出完整 19 文件，却运行时全 agent 连不上，且旧检查只 WARN 不红。已做：
  - Block 0 新增 **Provider 硬门**：部署后必须断言项目 `opencode.json` 或系统级 `~/.config/opencode/opencode.json`（二选一，同目录只留一个）含 `provider.opencode-go` 且 `apiKey` 非 `<YOUR_GO_API_KEY>`/非空，否则 AI 必须重建 provider，不许宣布成功。
  - Block 0 的 `opencode` 二进制检查**软化**：桌面端子 shell / 沙箱常因 PATH 不同误报 not found，改为仅 WARN，不阻断文件部署、更不因此跳过 provider。
  - **Provider 默认写项目级 `opencode.json`**（自包含，抗系统目录被删/为空）；系统级降级为多项目共享可选项。

### 低（P2）

- **T0 增 provider 真实 key 校验**：Block 5.5 脚本现 grep 项目/系统级 `.json`/`.jsonc` 中的 `opencode-go` 且 `apiKey` 为真实值（`sk-*` 或 `{file:}` 引用）且非占位符/空，否则 FAIL——直接抓住「系统级被删 / 没重建」式空壳。
- **T0 skills 误判修复**：从「总数 == 3」改为校验 **3 个指定目录存在**（`code-review-moa` / `architecture-moa` / `frontend-moa`），避免仓库自带 `opencode-moa` 元 skill 导致端用户复制后变 4 而**误 FAIL**。
- **同层双文件警告修正**：原写「`.jsonc` 优先、`.json` 被忽略」来自第三方插件文档，**官方未定义同目录双文件优先级**。已改为准确表述：OpenCode 同时支持 `.json`/`.jsonc`，但同目录两份并存优先级未定义、内容还可能冲突，安全做法是只留一个且含有效 provider + 真实 key。
- **速查表补空壳成因**：新增「系统级被删/目录为空」「同目录双 `.json`+`.jsonc`」「占位符 key」三行，对应处理均指向重建 provider / 只留一个 / 替换真实 key，并注明 T0 现会 FAIL 拦截。
- 方案存档：`docs/PLAN-moa-hardening.md`。

## v0.0.4（2026-07-10）

修复 v0.0.3 误诊后仍未消除的 `Upstream request failed`（真实根因：agent `reasoningEffort` 透传参数被网关拒绝）。

### 根因

见 v0.0.3「根因（更正）」。`reasoningEffort` 大写取值、以及部分模型不支持的档位，导致网关返回 HTTP 400 `invalid_request_error`，被包装成 `Upstream request failed`。

### 修复（均已落地）

- 19 个 agent `reasoningEffort` 取值全部改小写；意见/旗舰层按模型最高支持档提档：minimax-m3 / glm-5.2 / deepseek-v4-pro / mimo-v2.5-pro → `max`，qwen3.7-max/plus → `xhigh`（该模型 `max` 反而 400），kimi-k2.7-code → `high`（最高只到 high），工具/快任务层 → `medium`。
- 9 模型 `reasoning_effort` 支持矩阵实测写入 `docs/opencode-moa.md`（各档 OK/400/500 + 4 条规则）。
- 19 个 agent 新增 `max_tokens` 分档：工具/快任务层 2048，意见/旗舰/实现层 8192。
- `@` 菜单显示上限约 10 行会截断编排层 agent：约定编排层（旗舰×6、中级·融合、前端·总工、工具人-mimo）设 `hidden: true`（仅隐藏 @ 菜单、不阻止 Task 调用），约定已写入手册；agent 文件待应用。
- 参数生效实测：reasoning_effort（reasoning tokens 359→536）、max_tokens（5 vs 60）、temperature（0.1 确定性 vs 1.0 离散）、stop/top_p（网关接受）全部确认透传生效。

### 配置加载机制核实（deployer 发现正确）

官方配置文档确认 OpenCode **仅加载** `opencode.json`（项目级）与 `~/.config/opencode/opencode.json`（系统级，含 `.jsonc`），**不加载 `user_config.json`**。据此：

- v0.0.3 整条 `user_config.json` 路线（含"主会话靠 user_config.json 的 legacy `llm` 块"归因）**错误**；deployer 判定正确。
- 实际生效机制 = 系统级 `~/.config/opencode/opencode.json(c)` 注册 `provider.opencode-go`（带 key）+ 项目级 `opencode.json`（permissions / agent / default_agent）。子代理模型 `opencode-go/<model>` 经系统级 provider 解析。
- 仓库内 `user_config.json` / `user_config - 副本.json` 为死文件（且被 `.gitignore` 排除），建议删除。
- 部署手册 `Block 0` 的 "`user_config.json` 已创建且含有效 key 或占位符" 引用同样需更正为系统级 `opencode.json`，否则会误导用户走错误路线。

---

## v0.0.3（2026-07-10）

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

---

## v0.0.2（2026-07-09）

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

---

## v0.0.1（2026-07-08）

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

---

## Pre-release 历史

> 以下为 v0.0.1 之前的内部迭代记录，保留供参考。

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
