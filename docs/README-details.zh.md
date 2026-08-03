# OpenCode MoA — 参考细节

> 本文档收录原先放在 README 中的深度章节：容错设计、成本模型、安全、本地模型、验证、FAQ、维护者工具。快速上手请回到 [README](../README.md)。

## 容错设计

### 降级链

工具层挂了不会卡死，自动降级：

```
工具人 (Flash) 失败 → 立即重试1次
  → 重试成功 → 正常返回
  → 重试失败 → 工具人-mimo / tool-handler-mimo (MiMo) 失败 → 立即重试1次
    → 重试成功 → 正常返回
    → 重试失败 → ask 用户：
      A. 等几分钟再试
      B. 跳过工具层，直接调意见层（成本较高）
      C. 切换到免费模型处理
```

> 大多数 provider 错误（502/503/timeout/网络中断/SSE 流终止 terminated）是瞬时的，快速重试一次通常能成功。门童在 task 调用返回 terminated/网络错误时按容错规则自动重发同一任务一次（`.opencode/agents/门童.md` 容错节）。

### 融合层降级

若主融合 agent 失败（STUCK / ERROR_PROVIDER / timeout / 空结果），门童自动降级到 `@融合·保底`（DeepSeek V4 Pro）：

```
旗舰·融合 (Kimi K3) 失败
  → task(@融合·保底) (DeepSeek V4 Pro) → 输出保底结果
中级·融合 (Kimi) 失败
  → task(@融合·保底) (DeepSeek V4 Pro) → 输出保底结果
前端·总工 (DeepSeek V4 Flash) 失败
  → task(@融合·保底) (DeepSeek V4 Pro) → 输出保底结果
```

保底 agent 使用同样的残差增强融合流程。

### 意见层部分失败容错

单条意见链（架构/规划/工程，前端·还原/逻辑/动效，中级·工程/创意/码农）可能独立返回空结果或超时。系统会优雅地处理：

```
3 条并行意见链同时启动
  → 任一条返回空结果 → 重试该链一次
    → 重试成功 → 正常继续
    → 重试失败 → 标记为"降级"，以 N/3 输入继续融合流程
      → 残差提取仅用可用输入工作
      → 旗舰·融合应用降级融合规则
      → 输出带有 "[部分] N/3 输入" 标注
      → 置信度评分下调
```

降级融合规则（N < 3）：
- 共识覆盖率分母使用 N，而非 3
- 缺失视角标注为"[缺失：视角名]"
- 共识覆盖率 < 50% 时，输出"低置信降级融合"警告
- 单源融合（N=1）施加 0.7 置信度惩罚因子

> 这防止了一条意见链失败时流水线卡死的问题——这也是用户反馈的常见痛点。

### 声明式 Agent 预条件

Agent 的激活由声明式 `前置条件` 元数据驱动，而非硬编码路由规则。每个 Agent 声明何时应该被激活：

| Agent | 预条件 |
|-------|--------|
| 闪电侠 | always |
| 工具人 | 需要代码库上下文 |
| 视觉翻译 | 主条件：`截图`；降级条件：`错误日志 OR 图表 OR 长文档 OR 模糊意图` |
| 中级·工程 | 需要工程复杂度 |
| 中级·创意 | 需要创意复杂度 |
| 中级·码农 | 需要实现复杂度 |
| 旗舰·架构/规划/工程 | 需要系统设计复杂度 |
| 前端·还原/逻辑/动效 | 需要前端任务 |
| 融合·保底 | 融合层失败或意见层返回部分结果时激活 |

条件激活遵循短路原则：前置条件满足 → 激活；无任何前置条件满足 → 询问用户确认。这替代了硬编码触发规则（如"有截图→+@视觉翻译"），变成 Agent 自描述的、可文档化的元数据。

### 流水线阶段可视化

每次路由输出都带有阶段标识，让用户无需学习内部步骤编号即可追踪流水线进度：

```
[阶段：工具层] → [阶段：意见层] → [阶段：融合层] → [阶段：执行层]
```

阶段到流水线的映射：
- `工具层` — 材料搜集阶段
- `意见层` — 并行方案设计阶段（中级/旗舰/前端）
- `融合层` — 方案融合与校验阶段
- `执行层` — 编码与验收阶段

### 统一进度报告格式

成功路径和失败路径都遵循相同的报告格式，不暴露内部 Agent 名：

```
[流水线] 模式=<lite|balanced|strict>  阶段=<工具层|意见层|融合层|执行层>  状态=<等待中|执行中|已完成|降级|已卡死>
  reason: <为何走该层级>
  path: <工具层|中级链|旗舰链|前端链>
  fallback: <恢复策略>
```

状态标识：
- `等待中` — 等待输入
- `执行中` — 当前阶段执行中
- `已完成` — 阶段成功完成
- `降级` — 以部分输入降级模式运行
- `已卡死` — 所有恢复路径耗尽，等待用户干预

> 统一的报告格式让用户无论流水线成功还是失败，都能以相同格式理解当前状态。

### 闪电侠优先并行快捷通道

主流水线执行期间，闪电侠可并行处理独立的简单子任务：

```
主流水线：工具层 → 意见层 → 融合层 → 执行层
并行通道：闪电侠（始终就绪，与主流水线并行运行）
```

触发条件（满足其一）：
- 用户指令明确要求并行（"同时做 X""顺便查 Y"）
- 主流水线执行中产生与主线无依赖的简单子任务（如架构设计中顺便搜索 TODO）
- 用户主动 @闪电侠调用

限定范围：
- ✅ 与主线输出无依赖的独立任务
- ✅ 简单操作：文件搜索、grep、配置查询、格式化
- ❌ 会产生主线输入的任务
- ❌ 意见融合任务（必须串行）
- ❌ 实现与验收任务（必须串行）

闪电侠先完成后暂存结果，待主线流水线完成后统一返回。若主线先完成，闪电侠结果立即返回给用户。闪电侠失败不影响主流水线执行。

### MCP 权限隔离

意见层 agent 被禁止直接读取文件和调用命令，防止绕过工具层自行获取材料：

- 工具层：可以调用 bash/read（读代码、搜文件）
- 意见层：`read: deny` + `bash: deny`，只能基于工具层提供的材料出方案
- 融合层：同上，只能基于三份意见融合

> 注：项目未配置 MCP server，此处"权限隔离"指通过 deny 策略阻止 agent 自行取数，而非 MCP 层面的隔离。

### Task 嵌套防御

非路由 agent 默认 `task: deny`，防止子 agent 再次调用 task() 造成嵌套递归；例外：意见层与旗舰·质检授权 `task: {工具人: allow}` 做备选取证/独立取证。`subagent_depth: 2` 允许 agent → 工具人 一层深度，工具人自身 `task: deny`，深度 3 不可达，故无递归：

- **第一层（agent 文件头部）**：非路由 agent 默认声明 `task: deny`（12 个）；意见层 8 个 + 旗舰·质检声明 `task: {工具人: allow}` 做取证（备选路径，依赖环境）
- **第二层（opencode.json）**：`permission.task` 门童可调全部 agent，意见层/质检仅可调工具人；`subagent_depth: 2` 放开 agent → 工具人 一层，阻止更深的嵌套
- **第三层（prompt 护栏）**：门童 prompt 末尾追加约束，禁止自身调子 agent 进入新流水线

> 2026-07 发现门童→工具人→工具人三层嵌套后添加的防御。后为支持质检独立取证（明线/暗线复跑），意见层与质检放行一层 `task(@工具人)`；工具人自身拒绝 task，深度 2 即终结。

### 无材料保底

意见层被调用但没有材料时（工具层全部失败），会 ask 用户：

- 选"直接出方案" → 基于需求描述纯逻辑推演（不读代码）
- 选"等工具层恢复" → 输出 WAITING，等工具层恢复后重试

### 错误分类

工具层失败时输出明确的错误类别，不再盲目重试：

- `ERROR_PROVIDER` — 服务端 502/503/timeout
- `ERROR_AUTH` — 认证失败
- `ERROR_UNKNOWN` — 其他错误

---

## 成本

OpenCode Go 订阅的价格与额度详情：[opencode.ai/docs/go/](https://opencode.ai/docs/go/)

## 安全

| 防护           | 效果                                                                                |
| ------------ | --------------------------------------------------------------------------------- |
| 全局兜底 | 未声明的工具调用 → 弹窗确认                                                                   |
| Agent 权限隔离   | 每个 agent 只能用允许的工具                                                                 |
| MCP 权限隔离     | 意见层禁止直接读代码/调命令（read: deny + bash: deny），防止绕过工具层（项目未配置 MCP server，此处指 agent 级工具限制） |
| MCP 主开关（kill-switch） | `opencode.json` 中 16 个 agent override 块的 `"*_*": "deny"` —— MCP 工具名恒为 `server_tool`（含下划线），无需预知名单即可封禁任意环境下的全部 MCP 工具；模板不附带 MCP server，deny-by-default 安全 |
| task 三级防御     | 非路由 agent 默认拒绝 task（意见层/质检仅可调工具人）→ `subagent_depth: 2` 限深 → prompt 护栏，防嵌套递归 |
| 降级链          | 工具层失败 → ask 用户 → 等待/跳过/免费模型                                                       |
| 一键回滚         | 删掉 `.opencode/` 目录即可还原                                                            |

---

## 本地模型

支持 Ollama / LM Studio 等本地模型混用：

```yaml
# .opencode/agents/中级·码农.md
model: ollama-local/qwen3-coder
```

详见仓库根目录的 [`opencode.json`](../opencode.json)（完整 provider 配置示例）。

---

## 验证

仓库在 `.opencode/tests/` 下提供三个检查脚本。Layer 0 全自动；Layer 1–2 是在 OpenCode 内按引导逐步核对的人工清单。

```bash
# Layer 0 — 静态检查（自动，0 token）
pwsh .opencode/tests/T0-static-verify.ps1
# 预期：全部 PASS / FAIL=0（key 走系统级时 WARN 也算过）

# 一次性跑三层
pwsh .opencode/tests/run-all.ps1
```

| 脚本                      | Layer | 作用                                                                                       | 模式                 |
| ------------------------- | ----- | ------------------------------------------------------------------------------------------ | -------------------- |
| `T0-static-verify.ps1`    | 0     | 检查文件结构、agent/command/skill 数量、README 锚点、key 路径正确性                            | 自动                 |
| `T1-behavioral-guide.ps1` | 1     | 打印路由 / 意见层 / 融合层行为核对清单                                                        | 人工（在 OpenCode 内） |
| `T2-moa-smoke-guide.ps1`  | 2     | 打印 `/moa-*` 命令端到端冒烟清单                                                            | 人工（在 OpenCode 内） |
| `run-all.ps1`             | 0–2   | 先跑 T0，再打印 T1/T2 引导清单                                                              | 混合                 |

---

## 常见问题（Q&A）

### 安装相关

**Q: 我已有 opencode.json，会不会覆盖？**
A: 不会。安装脚本只合并 MoA 的 `permission`、`agent`、`default_agent` 配置，保留你已有的 `provider`、`model` 等设置。原文件会自动备份为 `.bak.时间戳`。

**Q: Windows 没有 `cp` 命令怎么办？**
A: 用 `Copy-Item` 或 `xcopy`：

```powershell
# PowerShell
Copy-Item -Recurse -Force opencode-moa\.opencode .\.opencode
# CMD
xcopy opencode-moa\.opencode .\.opencode /E /I /Y
```

**Q: 没有 pwsh/jq 能装吗？**
A: 可以。用方式一（AI 自动部署）或方式三（手动合并配置）。

**Q: 桌面端怎么装？**
A: 方式一最方便——克隆仓库（`git clone https://github.com/ZenHG/opencode-moa.git`）后，在 OpenCode 中让 AI 按 `opencode-moa` 仓库把 22 个 agent 全部部署进当前项目。方式二/三需要先在终端（CMD/PowerShell/Terminal）操作。

### 使用相关

**Q: 看不到「门童」？**
A: 见上方「30 秒部署 → 部署成功怎么判断」的三点检查：`opencode.json` 在项目根、`.opencode/agents/` 下 22 个 .md、重启后按 `Tab` 切换（Win 桌面端亦可用 `Ctrl+.`）。

**Q: `@工具人`（英文 alias：`@tool-handler`）无响应？**
A: 确认 `.opencode/agents/工具人.md` 存在且 frontmatter 格式正确；若使用英文命名版本，也可检查 `.opencode/agents/tool-handler.md`。

**Q: 报错 "model not found"？**
A: 模型 ID 格式应为 `provider/model-id`（如 `opencode-go/kimi-k2.7-code`）。在配置文件（系统级 `~/.config/opencode/opencode.json` 或项目 `opencode.json`）注册对应的 provider，然后在 TUI 内用 `/models` 查看可用模型。

**Q: 怎么切换回原来的 build/plan agent？**
A: 按 `Tab` 切换（Win 桌面端亦可用 `Ctrl+.`），或输入 `/build`、`/plan`。MoA 不影响内置 agent。

**Q: 我想用自己的模型，不走 Go 订阅？**
A: 修改 agent 的 `model` 字段即可：

```yaml
# .opencode/agents/中级·工程.md
model: opencode-go/deepseek-v4-flash
```

**Q: 部署后能删掉仓库吗？**
A: 可以。MoA 已复制到你的项目 `.opencode/` 目录，原仓库可以删除。

**Q: 多个项目怎么部署？**
A: 每个项目单独部署。`.opencode/` 是项目级配置，不影响其他项目。

### 降级相关

**Q: 工具层全部挂了怎么办？**
A: 见上方「容错设计 → 降级链」：MoA 会 ask 用户选 A. 等几分钟 / B. 跳过工具层直接调意见层（成本较高）/ C. 切换到免费模型。

**Q: 免费模型在哪？**
A: 见上方「成本 → 免费模型」：用 `/models` 打开模型列表选带 "Free" 标签的模型（Win 桌面端亦可用 `Ctrl+'`）（DeepSeek V4 Flash Free、MiMo-V2.5 Free、North Mini Code Free 等）。免费模型上下文有限、可能较慢、数据可能被用于训练。

---


