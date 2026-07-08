---
name: opencode-moa
description: 19-agent Cost-Optimal MoA 配置。性价比模型充当工具人，中端模型出意见，旗舰模型做融合。一次性部署，部署后可删除。
---

# OpenCode MoA 多模型智能路由编排方案 — 部署手册

---

默认 opencode 只有一个模型从头处理到尾。改一行字和设计一套系统架构用的是同一个 prompt、同一个温度、同一个上下文。没有分工。

这套方案部署一个 **门童 + 18 个专业 agent** 的 Cost-Optimal MoA 架构。核心设计原则只有一条：

> **搬砖用 flash 和 MiMo，意见用中端，融合用旗舰。** 每个模型只干自己最擅长的事，不浪费一次调用。

### 成本分层

```
月配额对比：
  DeepSeek V4 Flash   158,000 次  → 工具层（随便调）
  MiMo-V2.5           150,400 次  → 工具层（随便调）
  ──── 以上是工具人模型，占比 ~80% 调用量 ────
  Qwen3.7 Plus         21,600 次
  DeepSeek V4 Pro      17,150 次
  MiniMax M3           16,000 次
  MiMo-V2.5-Pro        16,300 次
  Qwen3.6 Plus         16,300 次
  ──── 以上是中端意见模型，占比 ~18% ────
  Kimi K2.7 Code        9,250 次
  Qwen3.7 Max           4,770 次
  GLM-5.2               4,300 次
  ──── 以上是旗舰融合模型，占比 ~2% ────
```

**工具层（Flash + MiMo）配额 30 万次/月**，覆盖所有读文件、搜代码、调 MCP、改代码的机械操作。**旗舰层合计不到 2 万次/月**，只做判断——融合、质检、架构规划。

整个过程就像排球队：自由人（Flash/MiMo）接全部一传，二传手（中端）组织进攻，主攻手（旗舰）扣球得分。各司其职。

### 旧 vs 新

|            | 之前                 | 之后                                                                |
| ---------- | ------------------ | ----------------------------------------------------------------- |
| 默认 agent   | `build`（自己切）       | **门童路由员**（自动编排）                                                   |
| 简单任务       | 一个模型做              | **闪电侠**（Flash, 一步到位）                                              |
| 工具调用       | 谁需要谁自己做            | **工具人 + 工具人-mimo**（Flash + MiMo, 专职苦力）                            |
| 写代码        | 一个模型出方案            | **3 中端意见 + 1 旗舰融合**                                               |
| 架构         | 一个模型又设计又编码         | **3 旗舰意见 → 1 旗舰融合 → Flash 实现 → pro 质检**                           |
| 截图/报错      | 你描述，AI 猜           | **视觉翻译官**（MiMo）精确还原                                               |
| 前端 UI      | 凭感觉猜尺寸             | **4 面覆盖：还原(MiMo-V2.5) + 逻辑(Qwen) + 动效(MiMo-V2.5-Pro) → 总工(Kimi)** |
| 安全命令       | 全弹窗确认              | 安全命令自动放行，危险直接拒                                                    |
| 一键命令       | 无                  | **5 个 `/moa-*`**                                                  |
| agent 定义位置 | 全在 `opencode.json` | 每个 agent 独立 `.md` 文件                                              |
| 内置 agent   | 无                  | `build`/`plan` 仍在，门童降级时回退                                         |

### 怎么用

**方式一：直接说需求（推荐）**

> 帮我写一个 Markdown 转 HTML 的函数

门童自动：判定复杂度 → 派工具人搜集上下文 → 3 个中端意见并行出方案 → 旗舰融合 → flash 实现 → pro 质检。全程不需切换 Agent、不需选模型。

**方式二：命令指定流程**

| 命令              | 场景                | 谁干活                   |
| --------------- | ----------------- | --------------------- |
| `/moa-quick`    | 改配置、翻译、简单查询       | @闪电侠                  |
| `/moa-medium`   | 函数模块、bug 修复、单文件重构 | 工程 + 创意 + 码农 → 融合     |
| `/moa-flagship` | 系统架构、大型重构         | 3 旗舰意见 → 融合 → 实现 → 质检 |
| `/moa-frontend` | UI 还原、CSS、截图修复    | 还原 + 逻辑 + 动效 → 总工     |
| `/moa-describe` | 截图/图片转文字          | 视觉翻译官                 |

**方式三：`@` 唤出（独立可用）**

输入 `@` 选 agent 直接对话。每个 agent 都可独立使用：

- `@工具人` / `@视觉翻译官` → 直接读取文件/截图
- `@中级·工程` → 会 ask 是否先搜集材料，你选「是」它自动调工具人
- `@中级·融合` → 你直接给它三份方案，它融合输出（没有三份方案时提示走门童）

意见层 agent 被 `@` 时：ask 你「直接出方案还是先搜集材料？」——选「搜集」它自动调工具人，一步到位。

### 分层设计

整个 MoA 严格按三层结构组织：

```
┌──────────────────────────────────────────────────────┐
│                  门童路由员 (flash)                    │
│              edit:deny, bash:deny, task:18子代理      │
└──────┬──────────────────────────────────────┬────────┘
       │                                      │
  ┌────▼──────────────────────────────┐  ┌────▼───────────────┐
  │ 工具层（苦力，随便调）                │  │ 执行层（搬砖）       │
  │                                   │  │                    │
  │ 工具人        (flash)              │  │ 闪电侠    (flash)   │
  │ 工具人-mimo  (MiMo-V2.5)           │  │ 旗舰·实现 (flash)   │
  │ 视觉翻译官    (MiMo-V2.5)           │  │ 前端·还原 (MiMo)    │
  └──────┬────────────────────────────┘  └────────────────────┘
         ▼ 提供材料给
  ┌─────────────────────────────────────────────────────┐
  │ 意见层（中端模型，每次任务消耗 3 次调用）                 │
  │                                                     │
  │ 中级: 工程(Pro) + 创意(MiniMax) + 码农(flash)          │
  │ 旗舰: 架构(Q3.7Max) + 规划(GLM) + 工程(Pro)            │
  │ 前端: 逻辑(Q3.7Plus) + 动效(MiMo-Pro)                 │
  └────────────────────────┬────────────────────────────┘
                           ▼
  ┌─────────────────────────────────────────────────────┐
  │ 融合层（旗舰模型，~2% 调用量）                          │
  │                                                     │
  │ 中级·融合 (Kimi K2.7)   — 三份意见取长补短              │
  │ 旗舰·融合 (Kimi K2.7)   — 架构方案融合                 │
  │ 前端·总工 (Kimi K2.7)   — 三份方案择优                 │
  │ 旗舰·质检 (Pro)         — 实现验收                    │
  └─────────────────────────────────────────────────────┘
```

**关键设计：**

- **工具人并行编组** — 工具人(flash快速) + 工具人-mimo(MiMo可靠) + 视觉翻译官(截图)，并行或保底。量大/紧急时全开，谁先回谁先用。
- **中层意见必须 3 份** — 两份意见容易产生"对 vs 错"的二元对立，三份意见天然形成"共识 + 分歧"结构，融合更有依据
- **flash 既是工具人也是意见人** — 在中级 MoA 中，flash 以"码农视角"参与意见输出，提供"老子直接写"的实战视角，和 Pro/MiniMax 的工程/创意视角互补
- **GLM-5.2 用在刀刃上** — 月配额仅 4,300 次，只用于 10+ 模块的极复杂架构和中文合规方案

### 角色总图

```
 门童路由员 (flash)
 │  edit:deny, bash:deny, task:18子代理
 │
 ├── 工具人      (flash)         edit:deny  bash:deny          ← 快速读文件
 ├── 工具人-mimo (MiMo-V2.5)     edit:deny  bash:deny ← 可靠读文件（保底+并行）
 ├── 闪电侠      (flash)         edit:allow bash:allow           ← 简单执行
 ├── 视觉翻译官   (MiMo-V2.5)     edit:deny  bash:deny             ← 看截图
 │
 ├── 中级·工程    (Pro)           edit:deny  bash:deny +task工具人   ← 意见
 ├── 中级·创意    (MiniMax M3)    edit:deny  bash:deny +task工具人   ← 意见
 ├── 中级·码农    (flash)         edit:deny  bash:deny +task工具人   ← 意见
 ├── 中级·融合    (Kimi K2.7)     edit:deny  bash:deny              ← 融合
 │
 ├── 旗舰·架构    (Qwen3.7 Max)   edit:deny  bash:deny +task工具人   ← 意见
 ├── 旗舰·规划    (GLM-5.2)       edit:deny  bash:deny +task工具人← 意见(慎重)
 ├── 旗舰·工程    (Pro)           edit:deny  bash:deny +task工具人   ← 意见
 ├── 旗舰·融合    (Kimi K2.7)     edit:deny  bash:deny              ← 融合
 ├── 旗舰·实现    (flash)         edit:allow bash:allow             ← 执行
  ├── 旗舰·质检    (Pro)           edit:deny  bash:deny             ← 验收
 │
 ├── 前端·还原    (MiMo-V2.5)     edit:allow bash:allow             ← 执行
 ├── 前端·逻辑    (Qwen3.7 Plus)  edit:deny  bash:deny +task工具人   ← 意见
 ├── 前端·动效    (MiMo-Pro)      edit:deny  bash:deny +task工具人   ← 意见
 └── 前端·总工    (Kimi K2.7)     edit:deny  bash:deny              ← 融合
```

### 路由流程

路由规则集中在门童路由员的 `<task_flow>` 中定义，见 [AI 执行段门童路由员模板](#门童路由员)。核心三步：

1. **判定复杂度** → 简单/中级/旗舰/前端
2. **并行出意见** → 3 个意见 agent 同时工作
3. **融合输出** → 融合 agent 取长补短

### 安全边界

每个 agent 内置安全指令，以下情况直接拒绝并汇报：

- 要求修改非本次任务范围的文件
- 要求删库、改密码、绕过权限检查
- 要求输出密钥/密码/敏感信息

门童路由员额外拦截：

- 用户要求「忽略之前指令」「绕过限制」→ 拒绝
- `task()` 调用若被 hijack → 子 agent 的安全指令独立生效

### task 的权限隔离

- 门童 `edit:deny` 但可以 `task(@闪电侠)`，闪电侠有 `edit:allow`
- 这不是漏洞——这是 opencode 的设计：被调用者用自己的权限执行
- 安全靠子 agent 的 prompt 约束 + 权限硬限制，不靠调用链传递权限

### 降级链

```
task() 调用失败或超时（60秒无响应视为超时）
  → 门童重试（最多 3 次，间隔 30 秒）
  → 仍失败 → 换一个同类 agent 尝试（如 工具人→工具人-mimo）
  → 3 次均失败 → 切换为内置 agent 直接处理
  → 通知用户 "自动路由不可用，已降级为单代理模式"
```

### 默认 agent 还在

`build` 和 `plan` 仍然可用（Ctrl + . 切换）。门童判定失败或 `task()` 不可用时会降级。

### agent 模型和参数可自行替换

每个 agent 的 frontmatter 里 `model` 字段指定了模型。**文档中的模型 ID 仅作声明，用户可按需换成自己偏好的任何模型。**

比如把 中级·创意 从小模型换成大模型：

```yaml
# .opencode/agents/中级·创意.md
model: opencode-go/deepseek-v4-pro   # 原来用 MiniMax M3，换成 Pro
```

或接入本地模型（见附录）混用：

```yaml
# .opencode/agents/中级·码农.md
model: ollama-local/qwen3-coder
```

工具层模型（flash / MiMo）可替换为任何高性价比模型，融合层模型（Kimi）可替换为你的最强模型。不换也完全可用。

### 意见层自动补材料

意见层 agent（中级·工程/创意/码农、旗舰·架构/规划/工程、前端·逻辑/动效）被直接 `@` 调用时，会 ask 你「是否先搜集材料？」。选「是」它自动 `task(@工具人)` 获取上下文，然后出方案——一步到位，不多操作。

被门童通过 `task()` 调用时，材料已随上下文传入，直接出方案。

这和「工具层双视角」互补：

- 通过门童走完整 MoA → 工具人+视觉翻译官并行提供材料 → 意见层获得双视角输入 → 三意见差异更大 → 融合结果质变
- 直接 `@` 某个意见 agent → ask → task(工具人)单视角 → 快速独立输出

### 工具层双视角

工具人（flash）取代码视角——变量名、控制流、依赖关系、边界条件。
视觉翻译官（MiMo）取结构视角——模块布局、调用链拓扑、命名模式、架构风格。
两份材料同时喂给意见层，视角差异天然放大意见分歧，融合结果因此更全面。

---

### 为什么每个 tier 要 3 个意见

两份意见形成"对 vs 错"的二元对立，融合时只能选边站。三份意见天然分化成：

- **共识部分**（两份以上一致）→ 直接保留
- **分歧部分**（各执一词）→ 融合模型取长补短

比如一个 API 设计方案：

- 工程视角（Pro）："用 REST，清晰直观"
- 创意视角（MiniMax）："用 GraphQL，灵活查询"
- 码农视角（flash）："REST 就行，GraphQL 写死了查询解析"
- 融合（Kimi）："核心 CRUD 用 REST，复杂查询用 GraphQL"→ 取到两方之长

三份意见的"质量"不是关键——**差异才是**。模型架构越不同，意见分化越大，融合效果越好。所以用 flash（代码倾向）、Pro（工程倾向）、MiniMax（创意倾向）三款架构完全不同的模型。

---

## AI 执行

### 执行规则

- **先读再写**：写文件前先 `Get-ChildItem` 检查目标路径下已有文件，避免覆盖
- **每块自检**：每完成一个 Block，自检确认文件存在、内容完整，再走下一块
- **降级兜底**：如果某个模型的 provider 在 `opencode.json` 中未配置，对应 agent 的 `model` 字段改为 `default` 或注释掉，opencode 会使用默认模型
- **预期不符**：Block 6 检查发现文件数不符时，列出缺失文件路径，不跳过

---

### Block 0：环境检查

先检测 opencode 运行模式（CLI / 桌面版 / 未安装），再按模式执行版本检查。

```bash
# 检测运行模式
# OPENCODE_CLIENT 由 CLI 和桌面版自动设置，最可靠
if [ -n "$OPENCODE_CLIENT" ]; then
    echo "运行模式: $([ "$OPENCODE_CLIENT" = "desktop" ] && echo "桌面版" || echo "CLI")"
else
    # 环境变量未设时尝试命令检测
    if command -v opencode >/dev/null 2>&1; then
        echo "运行模式: CLI"
        opencode --version || exit 1
    else
        echo "未检测到 opencode，请安装：https://opencode.ai/install"
        exit 1
    fi
fi
```

**自检**：CLI 模式 `opencode --version` >= 1.1.1。桌面版跳过此步。

---

### Block 1：目录结构

缺失的目录自动创建，opencode 会识别并读取。跨平台兼容（Linux/macOS/Windows）。

```bash
mkdir -p .opencode/agents .opencode/commands .opencode/skills .opencode/tests
```

**自检**：确认 `ls -d .opencode/*/` 输出包含 agents、commands、skills、tests。

---

### Block 2：19 个 Agent 文件

所有 agent 写到 `.opencode/agents/`。写前先检查目录已有文件，避免覆盖同名文件。

**降级兜底**：如果某个模型的 provider 未配置，将 `model: opencode-go/<模型名>` 改为 `model: default`，opencode 会用主模型运行该 agent。

写文件顺序：

1. 门童路由员（primary）
2. 工具人 → 工具人-mimo → 闪电侠 → 视觉翻译官
3. 中级·工程 → 中级·创意 → 中级·码农 → 中级·融合
4. 旗舰·架构 → 旗舰·规划 → 旗舰·工程 → 旗舰·融合 → 旗舰·实现 → 旗舰·质检
5. 前端·还原 → 前端·逻辑 → 前端·动效 → 前端·总工

**自检**：`Get-ChildItem .opencode/agents/*.md` 计数应为 19。

#### 门童路由员

`.opencode/agents/门童路由员.md`：

```markdown
---
description: 路由分发入口，不产生任何代码/方案
mode: primary
model: opencode-go/deepseek-v4-flash
temperature: 0.1
reasoningEffort: Medium
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

小 → @闪电侠
上下文 → @工具人，量大并行 @工具人-mimo
截图 → +@视觉翻译官
中 → @工具人 → 并行 @中级·工程 @中级·创意 @中级·码农 → @中级·融合
大 → @工具人 → 并行 @旗舰·架构 @旗舰·规划 @旗舰·工程 → @旗舰·融合 → @旗舰·实现 → @旗舰·质检
界面 → 并行 @前端·还原 @前端·逻辑 @前端·动效 → @前端·总工

最终结果（融合层输出）转发给用户。中间结果不暴露。
某 agent 失败/超时 → 跳过，用已返回的结果继续。全部失败 → STUCK: 无法路由
STUCK → 提示用户 Ctrl+. 切换 plan agent
```

#### 工具人

`.opencode/agents/工具人.md`：

```markdown
---
description: 读代码搜文件调MCP，不给意见
mode: subagent
model: opencode-go/deepseek-v4-flash
temperature: 0.1
reasoningEffort: Medium
permission:
  edit: deny
  bash: deny
---

只执行读取/搜索任务。返回文件路径+原文或摘要。不做分析不给方案。

卡住 → STUCK: 说明原因，重试3次，每次30秒，还是失败就@工具人-mimo

```

#### 工具人-mimo

`.opencode/agents/工具人-mimo.md`：

```markdown
---
description: 工具人，MiMo模型保底
mode: subagent
model: opencode-go/mimo-v2.5
temperature: 0.1
reasoningEffort: Medium
permission:
  edit: deny
  bash: deny
---

只执行读取/搜索任务。返回文件路径+原文或摘要。不做分析不给方案。

卡住 → STUCK: 说明原因，重试3次，每次30秒，还是失败就@工具人
都失败了就暂停，ask 你「继续无限重试还是有别的想法？」
```

#### 视觉翻译官

`.opencode/agents/视觉翻译官.md`：

```markdown
---
description: 截图/UI图/报错图转文字描述
mode: subagent
model: opencode-go/mimo-v2.5
temperature: 0.2
reasoningEffort: Medium
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

卡住 → STUCK: 说明原因
```

#### 闪电侠

`.opencode/agents/闪电侠.md`：

```markdown
---
description: 快速处理简单零碎任务
mode: subagent
model: opencode-go/deepseek-v4-flash
temperature: 0.2
reasoningEffort: Medium
permission:
  edit: allow
  bash: allow
---

专攻简单明确的小任务。直接出结果，不加开场白不改废话。

超能力范围 → ESCALATE:
卡住 → STUCK: 说明原因
```

#### 中级·工程

`.opencode/agents/中级·工程.md`：

```markdown
---
description: 工程视角方案
mode: subagent
model: opencode-go/deepseek-v4-pro
temperature: 0.4
reasoningEffort: High
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

---记忆层---
（核心思路+关键决策）
---方案---
```

#### 中级·创意

`.opencode/agents/中级·创意.md`：

```markdown
---
description: 创意视角方案
mode: subagent
model: opencode-go/minimax-m3
temperature: 0.5
reasoningEffort: Medium
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

---记忆层---
（与工程方案的差异+独特优势）
---方案---
```

#### 中级·码农

`.opencode/agents/中级·码农.md`：

```markdown
---
description: 实战视角方案
mode: subagent
model: opencode-go/deepseek-v4-flash
temperature: 0.3
reasoningEffort: Medium
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

`.opencode/agents/中级·融合.md`：

```markdown
---
description: 三份方案取长补短输出一份
mode: subagent
model: opencode-go/kimi-k2.7-code
temperature: 0.3
reasoningEffort: High
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

---

#### 旗舰·架构

`.opencode/agents/旗舰·架构.md`：

```markdown
---
description: 顶层架构设计
mode: subagent
model: opencode-go/qwen3.7-max
temperature: 0.4
reasoningEffort: high
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

---架构设计---
核心决策(≤5) | 技术选型+理由 | 模块划分+数据流 | 接口定义 | 风险+mitigation
```

#### 旗舰·规划

`.opencode/agents/旗舰·规划.md`：

```markdown
---
description: 结构化方案设计
mode: subagent
model: opencode-go/glm-5.2
temperature: 0.4
reasoningEffort: high
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

---规划方案---
问题域分析 | 方案结构 | 实施路径 | 风险与应对
```

#### 旗舰·工程

`.opencode/agents/旗舰·工程.md`：

```markdown
---
description: 大规模实现视角方案
mode: subagent
model: opencode-go/deepseek-v4-pro
temperature: 0.5
reasoningEffort: high
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

---工程方案---
实现要点 | 模块划分+接口 | 性能与容量 | 可观测性
```

#### 旗舰·融合

`.opencode/agents/旗舰·融合.md`：

```markdown
---
description: 三份架构方案取长补短
mode: subagent
model: opencode-go/kimi-k2.7-code
temperature: 0.3
reasoningEffort: high
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

`.opencode/agents/旗舰·实现.md`：

```markdown
---
description: 按融合方案编码落地
mode: subagent
model: opencode-go/deepseek-v4-flash
temperature: 0.2
reasoningEffort: Medium
permission:
  edit: allow
  bash: allow
---

按融合方案编码。不改接口签名。方案歧义时汇报，不自作主张。

---实现说明---
（范围+关键决策）
---代码---
```

#### 旗舰·质检

`.opencode/agents/旗舰·质检.md`：

```markdown
---
description: 对比方案和代码全维度验收
mode: subagent
model: opencode-go/deepseek-v4-pro
temperature: 0.2
reasoningEffort: High
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
---

对比方案和代码。不输出代码。打回时指明具体问题。

通过 / 有条件通过 / 打回
```

---

#### 前端·还原

`.opencode/agents/前端·还原.md`：

```markdown
---
description: 像素级还原UI设计稿
mode: subagent
model: opencode-go/mimo-v2.5
temperature: 0.3
reasoningEffort: Medium
permission:
  edit: allow
  bash: allow
---

严格按布局、颜色、文字精确还原UI。组件化、响应式。输出完整代码。
```

#### 前端·逻辑

`.opencode/agents/前端·逻辑.md`：

```markdown
---
description: 前端组件架构与状态管理方案
mode: subagent
model: opencode-go/qwen3.7-plus
temperature: 0.4
reasoningEffort: Medium
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

---逻辑方案---
组件树+职责 | 类型定义 | 状态管理层 | API接口层
```

#### 前端·动效

`.opencode/agents/前端·动效.md`：

```markdown
---
description: 前端交互体验与动效方案
mode: subagent
model: opencode-go/mimo-v2.5-pro
temperature: 0.5
reasoningEffort: High
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
```

#### 前端·总工

`.opencode/agents/前端·总工.md`：

```markdown
---
description: 三份前端方案择优融合
mode: subagent
model: opencode-go/kimi-k2.7-code
temperature: 0.3
reasoningEffort: high
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
---

对比还原、逻辑、动效三份代码。选最优或融合。不得模棱两可。三份都有缺陷→出修正版。

评分(布局/代码质量/交互/视觉/TS) | 对比结论 | ---最终代码---
```

### Block 3：5 个 `/moa-*` 命令

每个命令一个文件在 `.opencode/commands/`。文件名统一 `moa-` 前缀。

**自检**：`Get-ChildItem .opencode/commands/*.md` 计数应为 5，全部以 `moa-` 开头。

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

### Block 4：3 个 Skill

每个 skill 一个目录，内放 `SKILL.md`。

**自检**：`Get-ChildItem .opencode/skills/*/SKILL.md` 计数应为 3。

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

### Block 5：opencode.json

先读现有 `opencode.json`，合并 permissions.task 而不是覆盖。

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
  "instructions": ["AGENTS.md"],
  "compaction": {
    "auto": true,
    "reserved": 10000
  },
  "share": "manual",
  "snapshot": true
}
```

### Block 6：验证

跨平台兼容（Linux/macOS/Windows 的 Git Bash/WSL）。

```bash
echo "=== 数量检查 ==="
ls .opencode/agents/*.md 2>/dev/null | wc -l
ls .opencode/commands/*.md 2>/dev/null | wc -l
find .opencode/skills -name "SKILL.md" 2>/dev/null | wc -l
test -f opencode.json && echo "Config ok" || echo "Config missing"
```

预期：Agent 19，Commands 5，Skills 3，Config ok。

```bash
echo "=== 内容检查 ==="
grep "reasoningEffort:" .opencode/agents/*.md 2>/dev/null | wc -l
grep "task:" .opencode/agents/*.md 2>/dev/null | wc -l
ls .opencode/commands/moa-*.md 2>/dev/null | wc -l
```

预期：reasoningEffort 出现 19 次（全 agent），task: 出现 9 次（门童+8意见层），moa- 命令文件名匹配 5 个。

**预期不符时**：

- Agent 不足 19 → `ls .opencode/agents/` 对比模板补写缺失文件
- reasoningEffort/task: 不足 → 对比 doc 模板补充缺失 frontmatter
- Commands 不足 5 → 补写缺失的 `moa-*.md`
- Skills 不足 3 → 检查各 skill 目录（`code-review-moa`、`architecture-moa`、`frontend-moa`）
- Config missing → 写入 Block 5 的内容

> **完成部署**：以上全部验证通过后，**重启 opencode 使所有配置生效**。

---

### Block 7：多模型路由编排验证

```bash
# 需要 PowerShell（pwsh 跨平台可用）
./tests/run-all.ps1
```

三层验证聚焦**多模型智能路由编排**核心：

| 层级      | 文件                        | 方式  | 验证内容                                                       | token 成本    |
| ------- | ------------------------- | --- | ---------------------------------------------------------- | ----------- |
| Layer 0 | `T0-static-verify.ps1`    | 自动  | **模型分配**（19 agent model 字段与 doc 一致）、**权限分组**（5 组权限边界）、基础设施 | **0 token** |
| Layer 1 | `T1-behavioral-guide.ps1` | 人工  | 门童路由分发、意见层 ask、融合层引导、工具层独立可用                               | 正常使用        |
| Layer 2 | `T2-moa-smoke-guide.ps1`  | 人工  | 旗舰 MoA、`/moa-*` 命令、前端 MoA 完整编排                             | 正常使用        |

**关键验证点**：

- Layer 0 是唯一可信的模型验证层——行为测试看不到底层模型，只有 frontmatter 的 `model:` 字段能确认哪个 agent 用了哪个模型
- 模型分层验证：工具层必须 flash/MiMo，意见层必须 Pro/MiniMax/Qwen/MiMo-Pro，融合层必须 Kimi/Qwen-Max/GLM
- Layer 1/2 验证编排流程是否走通、约束是否生效（ask 机制、引导机制、拒绝机制）

**全部验证通过后，可删除本部署手册（`opencode-moa.md`）**。

---

## 附录 A：本地模型接入

可选。不影响远程模型。可同时启用多种本地模型。

### Ollama

```jsonc
{
  "provider": {
    "opencode-go": { /* 原配置 */ },
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
    "opencode-go": { /* 原配置 */ },
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

### 混合使用

```yaml
# .opencode/agents/中级·工程.md
model: opencode-go/deepseek-v4-pro

# .opencode/agents/中级·码农.md
model: ollama-local/qwen3-coder
```

---

## 附录 B：安全边界说明

| 防护层              | 位置                             | 效果                     |
| ---------------- | ------------------------------ | ---------------------- |
| 全局 catch-all     | opencode.json                  | 未显式声明的工具→"ask"弹窗       |
| agent permission | 各 agent 文件 frontmatter         | 工具级 allow/deny 硬限制     |
| agent prompt 约束  | 各 agent 文件正文                   | 运行时指令级拒绝               |
| 门童安全过滤           | 门童路由员 prompt                   | 拦截绕过规则指令               |
| task 权限白名单       | opencode.json + 门童 frontmatter | 只能 task 指定 agent       |
| 降级链              | 门童路由员 routing_rules            | task 失败不卡死，降级到内置 agent |

---

> **文档版本**：v3.4 | **对应 opencode**：>= 1.1.1
> 
> **v3.4 工具人编组**（2026-07-08）：
> 
> - **新增 工具人-mimo**：MiMo 模型保底工具人，与 工具人(flash) 并列为工具层，量大/紧急时并行调用，flash 超时时自动补位
> - **门童智能并行策略**：简单读→flash，量大/紧急→flash+MiMo并行先回先用，有截图+视觉翻译官
> - **硬限制清零**：移除 `300字内` `200字内` `1000行` 等数值阈值，改为语义分类（简单/中级/旗舰/前端）
> - **全局审计修整**：agent 计数 17→19、"Flash和" typo、"四份→三份"、"脑力→验收"、分层图补工具人-mimo、附录 B 同步
> - **测试瘦身**：移除无关测试（2+2、排序正确性等），Layer 0 99项静态检查，Layer 1/2 聚焦编排约束
> 
> **v3.3 公有化**（2026-07-07）：
> 
> - **意见层全面开放**：8 个意见 agent 获得 `task: { 工具人: allow, 视觉翻译官: allow }` + `edit:deny` `bash:deny`，被 `@` 直接调用时通过 ask+auto-execute 自行补材料，不再依赖门童唯一入口
> - **ask+auto-execute 模式**：意见 agent 被 `@` 时 ask 用户是否搜集材料，用户选「是」自动 task(工具人) 一步到位，零额外操作
> - **角色总图更新**：8 个意见 agent 权限从 `edit:allow` 改为 `edit:deny + task工具人`，融合层保持 `edit:deny`
> - **MCP 权限设计章节重构**：移除「只开放给工具层两 agent」的限制说明，改为意见层自动补材料机制
> - **`@` 方式三重写**：从「17 个都可单独点」改为「每个 agent 独立可用，无隐藏角色」
> 
> **v3.2 精简**（2026-07-07）：
> 
> - **全线 agent 精简**：所有 agent prompt 压缩到极致（12-40 行/个），去除 XML wrapper/safety/output_format 冗余结构，全文无多余上下文
> - **门童约束硬化**：`只输出 task() 调用或转发 subagent 结果。不产生任何原创内容。`——从机制上杜绝门童自行干活
> - **意见 agent 精简**：一句话角色 + 固定格式标记（`---方案---`），无流程描述了无 MoA 上下文污染
> - **融合 agent 精简**：同上，只做对比融合，不废话
> - **Block 6 验证脚本修复**：`findstr "moa-"` 改为 `dir` 文件名匹配
> 
> **v3.0 重构**（2026-07-07）：
> 
> - **Cost-Optimal MoA**：从 12 agent 重构为 18 agent（1 主 + 17 子），按"工具层/意见层/融合层"三层设计
> - **工具层双视角**：flash（代码逻辑）+ MiMo（视觉结构）并行提供材料，中端模型获得两份差异化输入
> - **三重意见**：每个 tier 改为 3 份意见并行，消除二元对立，融合模型能识别共识+分歧
> - **模型分配重建**：搬砖用 flash/MiMo，意见用 Pro/MiniMax/Qwen/MiMo-Pro，融合用 Kimi
> - **前端四覆盖**：新增 前端·逻辑(Qwen3.7 Plus)，和还原(MiMo)、动效(MiMo-Pro)构成前端的代码/视觉/交互三维度
> - **GLM-5.2 → 旗舰·规划**：月配额仅 4.3k，只在极复杂架构场景使用
> - **v2.2 的两个 bug 修复已合并**
> - **v3.1 格式化**（2026-07-07）：
>   - 全部 18 agent 文件移除 `steps` 硬编码，改为自然语言 STUCK 防卡死机制
>   - 命令统一 `/moa-*` 前缀（`describe` → `moa-describe`），description 精简为中文单句
>   - 前端 MoA 更新为四覆盖：还原(MiMo) + 逻辑(Qwen3.7P) + 动效(MiMoPro) → 总工(Kimi)
>   - skills 同步更新为三重 MoA 流程
