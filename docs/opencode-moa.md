---
name: opencode-moa
description: 19-agent Cost-Optimal MoA 配置。性价比模型充当工具人，中端模型出意见，旗舰模型做融合。一次性部署，部署后可删除。
---

# OpenCode MoA 部署手册 v0.0.3

---

## 前置条件

### 必需

| 条件                  | 检查命令                 | 说明                                            |
| ------------------- | -------------------- | --------------------------------------------- |
| OpenCode 已安装        | `opencode --version` | 版本 ≥ 1.1.1，[安装](https://opencode.ai/install)  |
| OpenCode Go 订阅      | opencode.ai 控制台查看 | [订阅](https://opencode.ai/auth)，首月 $5，之后 $10/月 |
| Git 已安装             | `git --version`      | 用于克隆仓库                                        |
| OpenCode Go API Key | opencode.ai 控制台创建 | 在 Zen 控制台（opencode.ai）创建                     |

### 可选（安装脚本需要）

| 条件              | 检查命令             | 说明                                                         |
| --------------- | ---------------- | ---------------------------------------------------------- |
| PowerShell Core | `pwsh --version` | install.ps1 需要，Windows 自带或 `brew install powershell`       |
| jq              | `jq --version`   | install.sh 合并 JSON 需要，`apt install jq` / `brew install jq` |

> 没有 pwsh/jq 也没关系，可以用方式一（AI 自动部署）或方式三（手动合并）。

### Provider 配置（必需）

19 个 agent 全部用 **`opencode-go/<model-id>`**（官方 Go 模型 ID 格式）。子代理通过 provider 注册表解析该前缀。**必须有一个带凭证的 `opencode-go` provider**（否则内置 `opencode` provider 无 key 会降级 `public`，Go 付费模型被禁用 → `OpenCode Go provider error` / `Upstream request failed`）。

两种鉴权方式，二选一：

---

**方式 A（推荐）：配置文件直接写 key**

把以下代码段放入系统级 `~/.config/opencode/opencode.json`（全平台生效，仓库外，所有项目共用）或项目 `user_config.json`（只对本项目生效，需 `.gitignore`）：

```jsonc
{
  "provider": {
    "opencode-go": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "OpenCode Go (MoA)",
      "options": {
        "baseURL": "https://opencode.ai/zen/go/v1",
        "apiKey": "<你的 Go API Key>"
      },
      "models": {
        "deepseek-v4-flash": { "name": "DeepSeek V4 Flash" },
        "mimo-v2.5":        { "name": "MiMo V2.5" },
        "mimo-v2.5-pro":    { "name": "MiMo V2.5 Pro" },
        "minimax-m3":       { "name": "MiniMax M3" },
        "glm-5.2":          { "name": "GLM 5.2" },
        "qwen3.7-max":      { "name": "Qwen3.7 Max" },
        "qwen3.7-plus":     { "name": "Qwen3.7 Plus" },
        "kimi-k2.7-code":   { "name": "Kimi K2.7 Code" },
        "deepseek-v4-pro":  { "name": "DeepSeek V4 Pro" }
      }
    }
  }
}
```

- 无需 TUI 交互，**桌面端 / headless / CI / WSL 全可用**。
- `opencode-go` 不与内置 Zen provider（`opencode`）冲突，Zen 和 @explore 等内置 agent 不受影响。
- 9 个模型已实测在 `zen/go/v1` 端点全部 200 OK。

---

**方式 B（备选）：TUI 内 `/connect`**

仅限终端 GUI 用户。TUI 内按 Ctrl+K 打开命令面板 → 输入 `/connect` → 选 OpenCode Go → 登录 opencode.ai → 贴 API key。key 存入 `~/.local/share/opencode/auth.json`，效果同上。

> `/connect` 是 TUI 命令，在桌面端 / headless 环境不可用。方式 A 配置文件和方式 B 鉴权可以并存，以方式 A 为准。

---

**验证：**

- 重启 OpenCode → `/models` 能看到 `opencode-go/deepseek-v4-flash` 等（非 `Free` 标记）。
- `@工具人` 能正常响应。
- `pwsh .opencode/tests/T0-static-verify.ps1` → 40 PASS。

> ⚠️ 含 `apiKey` 的文件不要提交到仓库。系统级 `~/.config/opencode/` 在仓库外；项目 `user_config.json` 被 `.gitignore` 排除。

---

### 错误兜底

如果 `/connect` 或配置文件均未配置 `opencode-go` provider，工具层调用将报 `Upstream request failed`：

```
工具人 (opencode-go/deepseek-v4-flash) 失败
  → 自动重试 1 次
  → 再失败 → ask 用户：
    A. 配置 provider 后重试
    B. 跳过工具层，直接出方案（成本较高，无代码材料）
    C. 切免费模型处理（/models 选 Free 模型）
```

该降级链已在门童路由员 prompt 中实现。用户选择后才会继续执行，不会跳过 ask 自动路由。

---

默认 opencode 只有一个模型从头处理到尾。改一行字和设计一套系统架构用的是同一个 prompt、同一个温度、同一个上下文。没有分工。

这套方案部署一个 **门童 + 18 个专业 agent** 的 Cost-Optimal MoA 架构。核心设计原则只有一条：

> **搬砖用 flash 和 MiMo，意见用中端，融合用旗舰。** 每个模型只干自己最擅长的事，不浪费一次调用。

### 成本分层

```
月配额对比（OpenCode Go 订阅 $10/月）：
  DeepSeek V4 Flash   158,000 次  → 工具层（随便调）
  MiMo-V2.5           150,400 次  → 工具层（随便调）
  ──── 以上是工具人模型，占比 ~80% 调用量 ────
  MiniMax M3           16,000 次
  DeepSeek V4 Pro      17,150 次
  Qwen3.7 Plus         21,600 次
  ──── 以上是中端意见模型，占比 ~18% ────
  Kimi K2.7 Code        9,250 次
  Qwen3.7 Max           4,770 次
  GLM-5.2               4,300 次
  ──── 以上是旗舰融合模型，占比 ~2% ────
```

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

### 降级链

```
工具人 (Flash) 失败 → 立即重试1次
  → 重试成功 → 正常返回
  → 重试失败 → 工具人-mimo (MiMo) 失败 → 立即重试1次
    → 重试成功 → 正常返回
    → 重试失败 → ask 用户：
      A. 等几分钟再试
      B. 跳过工具层，直接调意见层（成本较高）
      C. 切换到免费模型处理
```

> 大多数 provider 错误（502/503/timeout）是瞬时的，快速重试一次通常能成功。

---

## AI 执行

### 执行规则

- **先读再写**：写文件前先检查目标路径下已有文件，避免覆盖
- **每块自检**：每完成一个 Block，自检确认文件存在、内容完整，再走下一块
- **降级兜底**：如果某个模型的 provider 在 `opencode.json` 中未配置，对应 agent 的 `model` 字段改为 `default`

---

### Block 0：环境检查

```bash
# 检测运行模式
if [ -n "$OPENCODE_CLIENT" ]; then
    echo "运行模式: $([ "$OPENCODE_CLIENT" = "desktop" ] && echo "桌面版" || echo "CLI")"
else
    if command -v opencode >/dev/null 2>&1; then
        echo "运行模式: CLI"
        opencode --version || exit 1
    else
        echo "未检测到 opencode，请安装：https://opencode.ai/install"
        exit 1
    fi
fi
```

---

### Block 1：目录结构

```bash
mkdir -p .opencode/agents .opencode/commands .opencode/skills .opencode/tests
```

---

### Block 2：19 个 Agent 文件

所有 agent 写到 `.opencode/agents/`。写前先检查目录已有文件，避免覆盖同名文件。

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

       提示：选 C 需要手动操作——按 Ctrl+. 切换模型到免费模型，然后直接输入需求。"

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

失败 → 立即重试1次
  → 重试成功 → 正常返回结果
  → 重试失败 → 输出 ERROR类别: 原因，然后终止
    ERROR_PROVIDER: provider返回502/503/timeout（连接瞬断）
    ERROR_AUTH: 认证失败
    ERROR_UNKNOWN: 其他错误
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

失败 → 立即重试1次
  → 重试成功 → 正常返回结果
  → 重试失败 → 输出 ERROR类别: 原因，然后终止
    ERROR_PROVIDER: provider返回502/503/timeout（连接瞬断）
    ERROR_AUTH: 认证失败
    ERROR_UNKNOWN: 其他错误
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
失败 → 立即重试1次
  → 重试成功 → 正常返回
  → 重试失败 → 卡住 → STUCK: 说明原因
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

失败 → 立即重试1次
  → 重试成功 → 正常返回
  → 重试失败 → 卡住 → STUCK: 说明原因
```

#### 中级·工程

`.opencode/agents/中级·工程.md`：

```markdown
---
description: 工程视角方案
mode: subagent
model: opencode-go/minimax-m3
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

被调用时如果没有材料（工具层失败的情况）：
  → ask 用户："没有收到材料，要我直接出方案还是等工具层恢复？"
  → 用户选直接出 → 基于需求描述出方案（不读代码，不调MCP，纯逻辑推演）
  → 用户选等待 → 输出 "WAITING: 等待工具层恢复"

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
model: opencode-go/deepseek-v4-pro
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

被调用时如果没有材料（工具层失败的情况）：
  → ask 用户："没有收到材料，要我直接出方案还是等工具层恢复？"
  → 用户选直接出 → 基于需求描述出方案（不读代码，不调MCP，纯逻辑推演）
  → 用户选等待 → 输出 "WAITING: 等待工具层恢复"

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

被调用时如果没有材料（工具层失败的情况）：
  → ask 用户："没有收到材料，要我直接出方案还是等工具层恢复？"
  → 用户选直接出 → 基于需求描述出方案（不读代码，不调MCP，纯逻辑推演）
  → 用户选等待 → 输出 "WAITING: 等待工具层恢复"

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

被调用时如果没有材料（工具层失败的情况）：
  → ask 用户："没有收到材料，要我直接出方案还是等工具层恢复？"
  → 用户选直接出 → 基于需求描述出方案（不读代码，不调MCP，纯逻辑推演）
  → 用户选等待 → 输出 "WAITING: 等待工具层恢复"

---规划方案---
问题域分析 | 方案结构 | 实施路径 | 风险与应对
```

#### 旗舰·工程

`.opencode/agents/旗舰·工程.md`：

```markdown
---
description: 大规模实现视角方案
mode: subagent
model: opencode-go/minimax-m3
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

被调用时如果没有材料（工具层失败的情况）：
  → ask 用户："没有收到材料，要我直接出方案还是等工具层恢复？"
  → 用户选直接出 → 基于需求描述出方案（不读代码，不调MCP，纯逻辑推演）
  → 用户选等待 → 输出 "WAITING: 等待工具层恢复"

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

失败 → 立即重试1次
  → 重试成功 → 正常返回
  → 重试失败 → 卡住 → STUCK: 说明原因

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

失败 → 立即重试1次
  → 重试成功 → 正常返回
  → 重试失败 → 卡住 → STUCK: 说明原因

通过 / 有条件通过 / 打回
```

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

被调用时如果没有材料（工具层失败的情况）：
  → ask 用户："没有收到材料，要我直接出方案还是等工具层恢复？"
  → 用户选直接出 → 基于需求描述出方案（不读代码，不调MCP，纯逻辑推演）
  → 用户选等待 → 输出 "WAITING: 等待工具层恢复"

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

被调用时如果没有材料（工具层失败的情况）：
  → ask 用户："没有收到材料，要我直接出方案还是等工具层恢复？"
  → 用户选直接出 → 基于需求描述出方案（不读代码，不调MCP，纯逻辑推演）
  → 用户选等待 → 输出 "WAITING: 等待工具层恢复"
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

---

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

---

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

---

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

> **完成部署**：以上全部验证通过后，**重启 opencode 使所有配置生效**。

### 部署成功怎么判断？

1. 重启 OpenCode 后，按 `Ctrl+.` 切换 agent，看到「门童路由员」
2. 输入 `@工具人` 能正常响应
3. 运行验证脚本：`pwsh .opencode/tests/T0-static-verify.ps1`，预期 40 PASS

### 一键回滚

```bash
rm -rf your-project/.opencode/
# 手动恢复你的 opencode.json（安装脚本会自动备份 .bak 文件）
```

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
A: 方式一最方便——把本文件拖进对话框，让 AI 自动部署。方式二/三需要先在终端（CMD/PowerShell/Terminal）操作。

### 使用相关

**Q: 看不到「门童路由员」？**
A: 检查三点：

1. `opencode.json` 是否在项目根目录（不是子目录）
2. `.opencode/agents/` 下是否有 19 个 .md 文件
3. 重启 OpenCode 后按 `Ctrl+.` 切换 agent

**Q: `@工具人` 无响应？**
A: 确认 `.opencode/agents/工具人.md` 存在且 frontmatter 格式正确。

**Q: 报错 "model not found"？**
A: 模型 ID 不对或未订阅 OpenCode Go。运行 `/models` 检查模型列表。

**Q: MCP 工具被拦截？**
A: 正常行为。意见层被 `*_*:deny` 限制，防止绕过工具层自行获取材料。工具层正常可用。

**Q: 工具人报 Upstream request failed？**
A: provider 瞬时抖动，MoA 会自动重试 1 次。持续失败会 ask 用户选择等/跳过/免费模型。

**Q: 怎么切换回原来的 build/plan agent？**
A: 按 `Ctrl+.` 切换，或输入 `/build`、`/plan`。MoA 不影响内置 agent。

**Q: 我想用自己的模型，不走 Go 订阅？**
A: 修改 agent 的 `model` 字段即可：

```yaml
# .opencode/agents/中级·工程.md
model: anthropic/claude-sonnet-4-20250514
```

**Q: 部署后能删掉仓库吗？**
A: 可以。MoA 已复制到你的项目 `.opencode/` 目录，原仓库可以删除。

**Q: 多个项目怎么部署？**
A: 每个项目单独部署。`.opencode/` 是项目级配置，不影响其他项目。

### 降级相关

**Q: 工具层全部挂了怎么办？**
A: MoA 会 ask 用户：

- A. 等几分钟再试
- B. 跳过工具层，直接调意见层（成本较高）
- C. 切换到免费模型（需手动操作）

**Q: 免费模型在哪？**
A: 按 `Ctrl+.` 切换到免费模型（DeepSeek V4 Flash Free 等）。免费模型上下文有限、可能较慢、数据可能被用于训练。

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
# .opencode/agents/中级·码农.md
model: ollama-local/qwen3-coder
```

---

## 附录 B：安全边界说明

| 防护层              | 位置                               | 效果                    |
| ---------------- | -------------------------------- | --------------------- |
| 全局 catch-all     | opencode.json                    | 未显式声明的工具→"ask"弹窗      |
| agent permission | 各 agent 文件 frontmatter           | 工具级 allow/deny 硬限制    |
| MCP 权限隔离         | opencode.json agent.*.permission | `*_*: deny` 禁用意见层 MCP |
| task 权限白名单       | opencode.json + 门童 frontmatter   | 只能 task 指定 agent      |
| 降级链              | 工具人/门童 prompt                    | 快速重试 → ask 用户 → 降级    |

---

> **文档版本**：v0.0.2 | **对应 opencode**：>= 1.1.1

