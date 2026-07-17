---
name: opencode-moa
description: 22-agent Cost-Optimal MoA 配置。性价比模型充当工具人，中端模型出意见，旗舰模型做融合。一次性部署，部署后可删除。
---

# OpenCode MoA 部署手册

---

## 前置条件

### 必需

| 条件                  | 检查命令                 | 说明                                                                                                                                                                                                  |
| ------------------- | -------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| OpenCode 已安装        | `opencode --version` | **≥ 1.3.4**（agent 级 `reasoningEffort`/`hidden`/`task` 支持；`@ai-sdk/openai-compatible` 原生透传 reasoning 参数，**无需** `forceReasoning`；仅 `@ai-sdk/openai` 在 ≥1.3.4 有透传回归），[安装](https://opencode.ai/install) |
| OpenCode Go 订阅      | opencode.ai 控制台查看    | [订阅](https://opencode.ai/auth)，首月 $5，之后 $10/月                                                                                                                                                       |
| Git 已安装             | `git --version`      | 用于克隆仓库                                                                                                                                                                                              |
| OpenCode Go API Key | opencode.ai 控制台创建    | 在 Zen 控制台（opencode.ai）创建                                                                                                                                                                            |

### 可选（安装脚本需要）

| 条件              | 检查命令             | 说明                                                         |
| --------------- | ---------------- | ---------------------------------------------------------- |
| PowerShell Core | `pwsh --version` | install.ps1 需要，Windows 自带或 `brew install powershell`       |
| jq              | `jq --version`   | install.sh 合并 JSON 需要，`apt install jq` / `brew install jq` |

> 没有 pwsh/jq 也没关系，可以用方式一（AI 自动部署）或方式三（手动合并）。

### Provider 配置（必需）

22 个 agent 全部用 **`opencode-go/<model-id>`**（官方 Go 模型 ID 格式）。子代理通过 provider 注册表解析该前缀。**必须有一个带凭证的 `opencode-go` provider**（否则内置 `opencode` provider 无 key 会降级 `public`，Go 付费模型被禁用 → `OpenCode Go provider error` / `Upstream request failed`）。

两种鉴权方式，二选一：

> **AI 部署指令（必选其一）**  
> 
> **方式 A（推荐，AI 直接写入）**：  
> 
> 1. 向用户提问："请输入你的 OpenCode Go API Key（在 opencode.ai/auth 创建）。"  
> 2. 确保目录存在，并把**真实 key 单独**写入 `.opencode/local/opencode-go.key`（一行，无多余换行/空格；该文件已被 git 忽略，不会入库）：  
>    ```bash
>    mkdir -p .opencode/local
>    printf '%s' "<用户的KEY>" > .opencode/local/opencode-go.key
>    ```
> 3. 在项目 `opencode.json` 中加入下方 provider 配置块，`apiKey` 设为 `{file:.opencode/local/opencode-go.key}`（**引用** key 文件——不要直接把原始 key 贴进 `apiKey`）。  
> 4. 确认完成，通知用户重启 OpenCode。  
> 
> **方式 B（占位符，不通过对话传 key）**：  
> 
> 1. 在项目 `opencode.json` 中加入下方 provider 配置块，`apiKey` 字段值写 `<YOUR_GO_API_KEY>`（占位符）。  
> 2. 告诉用户：打开 `opencode.json`，把 `<YOUR_GO_API_KEY>` 替换成你在 opencode.ai/auth 创建的真实 key，保存后重启 OpenCode。  
> 3. key 不走对话，用户本地操作。  
> 
> **不可跳过此步骤**。否则 22 个 agent 全部静默失败。

---

**方式 A（推荐，默认项目级）：配置文件直接写 key**

**默认写入项目 `opencode.json`**——自包含部署：provider + key 都在项目内，即使系统级目录被删/为空也不影响。**必须先创建含真实 key 的 `.opencode/local/opencode-go.key`（见上方方式 A）**；`apiKey` 再经 `{file:}` 引用该文件（`.opencode/local/opencode-go.key`，已被 `.gitignore` 排除，不入库）。仅当你要在**多个项目共享一份 key** 时才改放系统级配置（仓库外；各平台真实路径见下方「系统级路径」）。

> ⚠️ **`forceReasoning` 仅对 `@ai-sdk/openai` 需要——本项目默认 `@ai-sdk/openai-compatible`，不要加**：opencode ≥ 1.3.4 的 reasoning 透传回归（[issue #20815](https://github.com/anomalyco/opencode/issues/20815)）**只影响 `"npm": "@ai-sdk/openai"` 的自定义 provider**（AI SDK v6 起按「已知推理模型列表」校验，不在表中就吞掉 `reasoningEffort`）。该 issue 实测确认 **`@ai-sdk/openai-compatible` 不受影响**，`reasoningEffort` 会正确透传为 `reasoning_effort`。本项目 provider 用的就是 `openai-compatible`，所以 **无需、也不应加 `forceReasoning`**（加了是 no-op，且会误导后人以为缺它不行）。只有把 `npm` 改成 `@ai-sdk/openai`（如要用 responses API）时，才必须在 `options` 里加 `forceReasoning: true`（仅 ≥1.3.4 需要，低版本忽略此字段）。

**系统级路径（全平台都认，但写法不同）：**

| 平台            | 真实路径                                          | 等价 `~` 写法                                      |
| ------------- | --------------------------------------------- | ---------------------------------------------- |
| Linux / macOS | `~/.config/opencode/opencode.json`            | 同左                                             |
| Windows       | `C:\Users\<你>\.config\opencode\opencode.json` | `%USERPROFILE%\.config\opencode\opencode.json` |

> 🔴 **辟谣**：网上很多第三方文档把 Windows 路径写成 `%APPDATA%\opencode\`（如某些 MCP 插件 README）。**那是错的**——OpenCode 在 Windows 上走的是 `%USERPROFILE%\.config\opencode`，不是 `%APPDATA%\opencode`。按错路径放配置会导致「部署成功但全 agent 连不上」且无明显报错。

> 🔴 **同层双文件警告**：OpenCode 官方确认**同时支持 `.json` 和 `.jsonc`** 两种格式，但**同一目录里同时留 `opencode.json` 和 `opencode.jsonc` 的优先级是未定义的**——官方配置文档只说「两种格式都支持」并列出全局路径为 `opencode.json`，并未规定同目录双文件谁优先。两份内容还可能相互冲突（例如一个启用某 provider、另一个禁用它）。**安全做法：同目录只保留一个**，且让保留的那份含有效 `opencode-go` provider + 真实 key，不要靠「两个都有」兜底。

> 🔴 **`apiKey` 不能是占位符 / 空**：写 `<YOUR_GO_API_KEY>`、空串或缺失，部署看似完成，运行时 22 agent 全会 401/403 `Upstream request failed`。本项目硬门与 T0 都会拦截这种情况。

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

- 无需 TUI 交互，**桌面端 / headless / CI / WSL 全可用**。
- `opencode-go` 不与内置 Zen provider（`opencode`）冲突，Zen 和 @explore 等内置 agent 不受影响。
- 9 个模型已实测在 `zen/go/v1` 端点全部 200 OK。
- **改完 provider 后必须重启 OpenCode** 才会重新读取 `apiKey`（以及 provider options 的任何改动），热改不生效。

---

**方式 B（备选）：TUI 内 `/connect`**

 仅限终端 GUI 用户。TUI 内输入 `/connect`（或按 Ctrl+P 打开命令面板） → 选 OpenCode Go → 登录 opencode.ai → 贴 API key。key 存入 `~/.local/share/opencode/auth.json`，效果同上。

> `/connect` 是 TUI 命令，在桌面端 / headless 环境不可用。方式 A 配置文件和方式 B 鉴权可以并存，以方式 A 为准。

---

**验证：**

- 重启 OpenCode → `/models` 能看到 `opencode-go/deepseek-v4-flash` 等（非 `Free` 标记）。
- `@工具人` 能正常响应。
- `pwsh .opencode/tests/T0-static-verify.ps1` → 全部 PASS（key 走系统级时 WARN 也算过，FAIL=0）。

> ⚠️ 含真实 key 的文件（`.opencode/local/opencode-go.key`）不被 git 跟踪（`*.key` 和 `.opencode/local/` 已被 `.gitignore` 排除）。系统级 `~/.config/opencode/` 在仓库外。

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

这套方案部署一个 **门童 + 21 个专业 agent** 的 Cost-Optimal MoA 架构。核心设计原则只有一条：

> **搬砖用 flash 和 MiMo，意见用中端，融合用旗舰。** 每个模型只干自己最擅长的事，不浪费一次调用。

### 成本分层

```
月配额对比（OpenCode Go 订阅 $10/月）：
  DeepSeek V4 Flash   158,000 次  → 工具层（随便调）
  MiMo-V2.5           150,400 次  → 工具层（随便调）
  ──── 以上是工具人模型，占比 ~80% 调用量（设计值，非实测） ────
  MiniMax M3           16,000 次
  DeepSeek V4 Pro      17,150 次
  Qwen3.7 Plus         21,600 次
  ──── 以上是中端意见模型，占比 ~18%（设计值，非实测） ────
  Kimi K2.7 Code        9,250 次
  Kimi K3               280 次（截至 7/24 翻倍，之后回 140）
  GLM-5.2               4,300 次
  ──── 以上是旗舰融合模型，占比 ~2%（设计值，非实测） ────
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

> ⚠️ **前置检查**：开始部署前，确认已按上方 **「Provider 配置」** 节完成 key 配置（系统级 `~/.config/opencode/opencode.json` 已注册 `provider.opencode-go` 且含有效 key）。OpenCode 仅加载项目级 `opencode.json` 与系统级 `~/.config/opencode/opencode.json`，**不加载 `user_config.json`**。如果还没配，翻回上方先处理，否则 22 个 agent 部署后全连不上。

```bash
# 检测运行模式
if [ -n "$OPENCODE_CLIENT" ]; then
    echo "运行模式: $([ "$OPENCODE_CLIENT" = "desktop" ] && echo "桌面版" || echo "CLI")"
else
    if command -v opencode >/dev/null 2>&1; then
        echo "运行模式: CLI"
        opencode --version || true
    else
        # 桌面端子 shell / 沙箱常因 PATH 不同报 not found，即便已安装——仅告警，不阻断文件部署、更不因此跳过 provider 配置
        echo "⚠️ 当前 shell 未找到 opencode（可能 PATH 不同），文件仍可部署；验证请在含 opencode 的 shell 或重启桌面端后做"
    fi
fi
```

> 🔴 **Provider 硬门（部署后必查）**：文件部署完成后，必须断言 **项目 `opencode.json` 或系统级 `~/.config/opencode/opencode.json`（二选一，同目录只留一个）** 中存在 `provider.opencode-go` 且 `apiKey` 为**真实 key**（既非 `<YOUR_GO_API_KEY>` 占位符、也非空/缺失）。不满足则 AI **必须执行上方 Provider 步重建 provider**，不许宣布「部署成功」——否则会生成「文件齐全但 22 agent 全连不上」的空壳。

---

### Block 1：目录结构

```bash
mkdir -p .opencode/agents .opencode/commands .opencode/skills .opencode/tests
```

---

### reasoning_effort 支持矩阵（实测）

`reasoningEffort` 是合法透传参数（agents 文档 *Additional* 段），但 **OpenCode Go 网关只认小写取值，且不支持的取值会直接 400 硬失败（不会自动降级到默认）**。下方为对 `zen/go/v1` 端点逐模型实测结果（`OK`=正常返回，`400`=请求被拒，`500*`=后端瞬断不稳）：

> ⚠️ **前置依赖**：本矩阵的 `reasoningEffort` 取值要真正生效，需满足两条：
> 
> 1. provider 用的是 `@ai-sdk/openai-compatible`（本项目默认）：该 SDK **原生透传** `reasoningEffort`，无需任何开关——下方矩阵取值直接生效。透传回归只发生在 `@ai-sdk/openai`（≥1.3.4），届时才需 `forceReasoning: true`。
> 2. agent 的 `reasoningEffort` 字段拼写全小写（`medium` 而非 `Medium`）。大写会被网关 400 拒绝。
>    若某 agent 报 `Upstream request failed` 且日志含 400，优先怀疑这两点而不是模型挂了。

| 模型                | low | medium | high | max  | xhigh | none | minimal | 备注                        |
| ----------------- | --- | ------ | ---- | ---- | ----- | ---- | ------- | ------------------------- |
| deepseek-v4-flash | OK  | OK     | OK   | OK   | OK    | 400  | 400     | 全档支持                      |
| mimo-v2.5         | OK  | OK     | OK   | 500* | 500*  | 500* | 500*    | max/xhigh 偶发 500，建议用 high |
| mimo-v2.5-pro     | OK  | OK     | OK   | OK   | OK    | OK   | OK      | 全档支持                      |
| minimax-m3        | OK  | OK     | OK   | OK   | OK    | OK   | OK      | 全档支持                      |
| glm-5.2           | OK  | OK     | OK   | OK   | OK    | OK   | 400     | 全档支持                      |
| qwen3.7-max       | OK  | OK     | OK   | 400  | OK    | OK   | OK      | `max` 反而 400，最高用 `xhigh`  |
| qwen3.7-plus      | OK  | OK     | OK   | 400  | OK    | OK   | OK      | `max` 反而 400，最高用 `xhigh`  |
| kimi-k2.7-code    | OK  | OK     | OK   | 400  | 400   | 400  | OK      | 最高只到 `high`               |
| deepseek-v4-pro   | OK  | OK     | OK   | OK   | OK    | 400  | 400     | 全档支持                      |

**规则：**

1. 取值必须小写：`low` / `medium` / `high` / `max` / `xhigh` / `none` / `minimal`。大写 `Medium`/`High` 一律 400。
2. `extreme` / `extended` / `xmedium` / `adaptive` / `auto` 在所有模型上均 400，不可用。
3. 某模型不支持的取值 → 该 agent 直接 400（`Upstream request failed`），**不会回退默认强度**。默认值仅在完全不写 `reasoningEffort` 时生效。
4. 本方案参数：工具/快任务层用 `medium`（高调用量、控成本）；意见层/融合层按模型最高支持档提档（minimax/glm/pro/mimo-pro→`max`，qwen-max→`xhigh`，kimi→`high`），最大化推理质量。

> ⚠️ **不要在 TUI 里手动切「变体 / 推理档」**：OpenCode 的变体选择（桌面端 `Ctrl+t`、或模型列表里手选）会**覆盖** agent 在 `opencode.json` / agent `.md` 里配的 `reasoningEffort`，并写入 model 选择缓存——Linux / macOS / **WSL** `~/.local/state/opencode/model.json`（WSL 虽跑在 Windows 上，但走 Linux 路径，不是 Windows 路径）、Windows `%USERPROFILE%\.local\state\opencode\model.json`——**重启仍生效（两种路径形态已覆盖全部平台，跨平台一致）**。注：Unix 下该路径受 `XDG_STATE_HOME` 影响可重定向。一旦手切过，本矩阵的 low→xhigh 档位会被静默顶掉且难察觉。要改推理强度，请改 agent 的 `reasoningEffort` 字段并重启，而不是在 TUI 手切变体。

### @ 菜单显示上限与 hidden 约定

OpenCode 的 `@` 自动补全菜单有**显示行数上限**（约 10 行），agent 超过后会被截断、不再显示。排序按名称，与类别无关。

应对：把**只由门童通过 Task 工具编排、用户几乎不手敲 @ 调用**的 agent 设为 `hidden: true`。该字段**仅隐藏 @ 菜单项，不阻止 Task 调用**（门童正是用 Task 调它们），行为与融合链不受影响。

**设为 `hidden: true` 的 18 个 agent（仅隐藏 @ 菜单，不阻止门童用 Task 调用）：**

- 残差提取者 / 置信度评估者 / 融合·保底（分析 / 保底层，门童驱动）
- 工具人-mimo（工具人保底，门童重试链驱动）
- 中级·工程 / 中级·创意 / 中级·码农 / 中级·融合（中级意见 + 融合链）
- 旗舰·架构 / 旗舰·规划 / 旗舰·工程 / 旗舰·融合 / 旗舰·实现 / 旗舰·质检（旗舰融合链）
- 前端·还原 / 前端·逻辑 / 前端·动效 / 前端·总工（前端融合链）

**保持可见（用户常手 @）：** 工具人、视觉翻译官、闪电侠，加内置 explore / general。

> `hidden` 仅对 `mode: subagent` 生效；primary agent（门童路由员）不在 @ 菜单中，无需设置。

> 🔧 **自定义 —— 一切都不捆绑死。** agent 名称与各自的 `model` 都是「起始建议」，不是契约：
> - **模型**：把任意 agent 的 `model:` 改成你有权限的任何模型/provider 即可。provider 块里那 9 个 `opencode-go` 模型 ID 仅是声明，随便换（比如不用 Go，改用你自己的 Anthropic/OpenAI key）。
> - **agent 名称**：可以改名，但改名是「全局替换」——必须同步更新**每一处**引用，否则部署会坏：门童路由员的 `task:` 白名单、`opencode.json` 的 `permission.task` 白名单，以及所有跨 agent 的 `@`/task 调用。漏改一处，该 agent 就失联（task 调用被拒）。
> - **路由员本身**：`门童路由员` 要在它自己的 frontmatter、上面的 `task:` 白名单、`opencode.json` 的 `default_agent` 三处保持一致。

### Block 2：22 个 Agent 文件

所有 agent 写到 `.opencode/agents/`。写前先检查目录已有文件，避免覆盖同名文件。

写文件顺序：

1. 门童路由员（primary）
2. 工具人 → 工具人-mimo → 闪电侠 → 视觉翻译官
3. 中级·工程 → 中级·创意 → 中级·码农 → 中级·融合
4. 旗舰·架构 → 旗舰·规划 → 旗舰·工程 → 旗舰·融合 → 旗舰·实现 → 旗舰·质检
5. 前端·还原 → 前端·逻辑 → 前端·动效 → 前端·总工
6. 残差提取者 → 置信度评估者 → 融合·保底（hidden，门童驱动）

**自检**：`Get-ChildItem .opencode/agents/*.md` 计数应为 22。

#### 门童路由员

.opencode/agents/门童路由员.md：

```markdown
---
description: 智能路由引擎，负责任务理解、路由决策和链路组装
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
    "融合·保底": allow
    "残差提取者": allow
    "置信度评估者": allow
---

# 门童路由员 v2

## 置信度（0-100，共享6维度加权）
= 100×(0.25清晰度+0.20模型匹配+0.15复杂度+0.10技术熟悉+0.10上下文+0.10风险)
路由: ≥85→闪电侠/中级链 | 60-84→@置信度评估者二次确认 | <60→旗舰链

## 执行链
小→@闪电侠 | 中→@工具人→[@中级·工程 @中级·创意 @中级·码农]→@中级·融合
大→@工具人→[@旗舰·架构 @旗舰·规划 @旗舰·工程]→@残差→@旗舰·融合→@旗舰·质检→@旗舰·实现→@旗舰·质检
前端→[@前端·还原 @前端·逻辑 @前端·动效]→@前端·总工 | 融合失败→@融合·保底

## 修正因子
前端任务→强制前端链 | 有截图→+@视觉翻译官 | 高风险(支付/安全/数据)→升级一级
工具层失败→@工具人-mimo→仍失败→ask: A.等30秒重试 B.跳过工具层

## 复杂度×专业深度矩阵
| | D1通用 | D2特定框架 | D3架构设计 | D4跨领域 |
|---|---|---|---|---|
| C1<50行 | 闪电侠 | 闪+1 | 中级链 | 旗舰链 |
| C2<200行 | 中级链 | 中+1 | 旗舰链 | 旗舰+人工 |
| C3<500行 | 中级链 | 旗舰链 | 旗舰+人工 | 旗舰+人工 |
| C4跨系统 | 旗舰链 | 旗舰+人工 | 旗舰+人工 | 旗舰+人工 |

## VOC: 质量增益/额外成本 → 多模块/安全关键→旗舰 | 简单配置→闪电侠 | 不确定→中级
最终结果转发用户，中间结果不暴露。某agent失败→跳过。全部失败→STUCK: 提示用户Tab切换（Win: Ctrl+.）
```

#### 工具人

.opencode/agents/工具人.md：

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

## 材料自检（返回结果前执行）
1. 文件路径是否正确？
2. 内容与用户需求是否相关？
3. 是否遗漏关键文件？
如有疑虑，在结果末尾注明："⚠️ 注意：材料可能不完整，请谨慎参考。"

## 输出格式：<<材料包>>
返回结果时按以下格式打包：
- **文件名清单**: [列出所有读取的文件路径]
- **关键内容摘要**: [每个文件的核心内容概要，2-3句话]
- **相关性评分**: [高/中/低 — 与用户需求的匹配程度]

示例：
```
<<材料包>>
文件名清单: src/main.py, src/config.yaml
关键内容摘要: main.py 包含主入口函数和路由定义；config.yaml 定义数据库连接参数
相关性评分: 高 — 直接对应需求中的配置和入口点
```

失败 → 立即重试1次
  → 重试成功 → 正常返回结果
  → 重试失败 → 输出 ERROR类别: 原因，然后终止
    ERROR_PROVIDER: provider返回502/503/timeout（连接瞬断）
    ERROR_AUTH: 认证失败
    ERROR_UNKNOWN: 其他错误
    ERROR_QUOTA_FREE: 免费模型调用次数已达上限
```

#### 工具人-mimo

.opencode/agents/工具人-mimo.md：

```markdown
---
description: 工具人，MiMo模型保底
mode: subagent
model: opencode-go/mimo-v2.5
temperature: 0.1
reasoningEffort: medium
max_tokens: 2048
hidden: true
permission:
  edit: deny
  bash: deny
---
只执行读取/搜索任务。返回文件路径+原文或摘要。不做分析不给方案。

## 输出格式：<<材料包>>
返回结果时按以下格式打包：
- **文件名清单**: [列出所有读取的文件路径]
- **关键内容摘要**: [每个文件的核心内容概要，2-3句话]
- **相关性评分**: [高/中/低 — 与用户需求的匹配程度]

失败 → 立即重试1次
  → 重试成功 → 正常返回结果
  → 重试失败 → 输出 ERROR类别: 原因，然后终止
    ERROR_PROVIDER: provider返回502/503/timeout（连接瞬断）
    ERROR_AUTH: 认证失败
    ERROR_UNKNOWN: 其他错误
    ERROR_QUOTA_FREE: 免费模型调用次数已达上限
```

#### 闪电侠

.opencode/agents/闪电侠.md：

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

.opencode/agents/视觉翻译官.md：

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

.opencode/agents/中级·工程.md：

```markdown
---
description: 工程视角方案
mode: subagent
model: opencode-go/kimi-k2.6
temperature: 0.4
reasoningEffort: high
max_tokens: 16384
hidden: true
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

.opencode/agents/中级·创意.md：

```markdown
---
description: 创意视角方案
mode: subagent
model: opencode-go/qwen3.7-plus
temperature: 0.5
reasoningEffort: medium
max_tokens: 16384
hidden: true
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

.opencode/agents/中级·码农.md：

```markdown
---
description: 实战视角方案
mode: subagent
model: opencode-go/deepseek-v4-flash
temperature: 0.3
reasoningEffort: medium
max_tokens: 16384
hidden: true
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

被调用时如果没有材料（工具层失败的情况）：
  → ask 用户："没有收到材料，要我直接出方案还是等工具层恢复？"
  → 用户选直接出 → 基于需求描述出方案（不读代码，不调MCP，纯逻辑推演）
  → 用户选等待 → 输出 "WAITING: 等待工具层恢复"

---记忆层---
（与另两方案的核心差异）
---方案---
```

#### 中级·融合

.opencode/agents/中级·融合.md：

```markdown
---
description: 三份中级方案取长补短（残差增强融合）
mode: subagent
model: opencode-go/kimi-k2.7-code
temperature: 0.3
reasoningEffort: high
max_tokens: 16384
hidden: true
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
---
你是中级融合专家。对比工程、创意、码农三份方案，输出一份融合方案。

## 融合流程

### 阶段1: 共识识别
- 识别三份方案共同认可的核心决策
- 计算共识覆盖率 = 共识决策数 / 总决策数

### 阶段2: 分歧处理
- 互补型 → 合并
- 矛盾型 → 择一（旗舰链优先架构方案，中级链优先工程方案）
- 冗余型 → 保留最优表述

### 阶段3: 幻觉过滤
- 标记疑似幻觉：编造的技术选型、不存在的 API、虚构的库
- 幻觉标记的部分直接丢弃

### 快速融合
如果共识覆盖率 ≥ 95%，跳过详细分析直接整合共识部分。

## 输出格式

---融合决策理由---
【共识覆盖率】XX%
【分歧处理】X 项互补 / X 项矛盾 / X 项冗余
【幻觉过滤】X 项疑似幻觉已排除

---融合方案---
（完整融合方案）
```

#### 旗舰·架构

.opencode/agents/旗舰·架构.md：

```markdown
---
description: 顶层架构设计
mode: subagent
model: opencode-go/qwen3.7-max
temperature: 0.4
reasoningEffort: xhigh
max_tokens: 16384
hidden: true
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

.opencode/agents/旗舰·规划.md：

```markdown
---
description: 结构化方案设计
mode: subagent
model: opencode-go/glm-5.2
temperature: 0.4
reasoningEffort: max
max_tokens: 16384
hidden: true
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

.opencode/agents/旗舰·工程.md：

```markdown
---
description: 大规模实现视角方案
mode: subagent
model: opencode-go/minimax-m3
temperature: 0.5
reasoningEffort: max
max_tokens: 16384
hidden: true
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

.opencode/agents/旗舰·融合.md：

```markdown
---
description: 三份架构方案取长补短（残差增强融合）
mode: subagent
model: opencode-go/kimi-k3
temperature: 0.3
reasoningEffort: high
max_tokens: 16384
hidden: true
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
---
你是旗舰融合专家。对比架构、规划、工程三份方案，输出一份融合方案。

## 融合流程

### 阶段1: 共识识别
- 识别三份方案共同认可的核心决策
- 计算共识覆盖率 = 共识决策数 / 总决策数

### 阶段2: 分歧处理
- 互补型 → 合并到最终方案
- 矛盾型 → 优先采纳架构方案的建议（长期可维护性优先）
- 冗余型 → 保留表述最清晰、论证最充分的版本

### 阶段3: 幻觉过滤
- 标记疑似幻觉：编造的技术选型、不存在的 API、虚构的库
- 幻觉标记的部分直接丢弃

### 残差处理
- 如果收到残差提取者报告：直接使用其分析结果
- 如果没有残差报告：自行执行残差分析

### 快速融合
如果共识覆盖率 ≥ 95%，跳过详细残差分析，直接整合共识部分。

## 输出格式

---融合决策理由---
【共识覆盖率】XX%
【分歧处理】X 项互补 / X 项矛盾 / X 项冗余
【幻觉过滤】X 项疑似幻觉已排除

---融合方案---
（完整融合方案，包含共识部分和残差补偿建议）
```

#### 旗舰·实现

.opencode/agents/旗舰·实现.md：

```markdown
---
description: 按融合方案编码落地
mode: subagent
model: opencode-go/deepseek-v4-flash
temperature: 0.2
reasoningEffort: medium
max_tokens: 16384
hidden: true
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

.opencode/agents/旗舰·质检.md：

```markdown
---
description: 对比方案和代码全维度验收（含方案审查 + 学习记录）
mode: subagent
model: opencode-go/deepseek-v4-pro
temperature: 0.2
reasoningEffort: max
max_tokens: 16384
hidden: true
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
---
你是 MoA 质检员。你有双重职责：

## 职责1: 方案审查（融合后、实现前）
对比融合方案和用户原始需求：
1. 幻觉检测 — 是否有编造的 API/库/技术选型
2. 要求对齐 — 是否满足所有用户约束
3. 规范冲突 — 是否与项目规范/官方文档冲突
4. 可行性 — 在当前上下文中是否可落地

输出置信度评分（0-100，与门童/置信度评估者共享6维度加权标准）：
  ≥ 85: 通过 → 进入实现层
  60-84: 有条件通过 → 指出需修正的点
  < 60: 打回 → 返回融合层重新融合

## 职责2: 代码验收（实现后）
对比方案和实现代码：
1. 完整性 — 是否实现了方案中的所有要点
2. 正确性 — 代码逻辑是否正确
3. 规范性 — 是否符合项目规范

输出: 通过 / 有条件通过 / 打回

## 职责3: 学习记录
每次审查记录典型问题标签（用于后续改进）：
- 幻觉类: [具体描述]
- 规范冲突类: [具体描述]
- 可行性类: [具体描述]

失败 → 立即重试1次
  → 重试成功 → 正常返回
  → 重试失败 → 卡住 → STUCK: 说明原因

通过 / 有条件通过 / 打回
```

#### 前端·还原

.opencode/agents/前端·还原.md：

```markdown
---
description: 像素级还原UI设计稿
mode: subagent
model: opencode-go/mimo-v2.5
temperature: 0.3
reasoningEffort: medium
max_tokens: 16384
hidden: true
permission:
  edit: allow
  bash: allow
---

严格按布局、颜色、文字精确还原UI。组件化、响应式。输出完整代码。
```

#### 前端·逻辑

.opencode/agents/前端·逻辑.md：

```markdown
---
description: 前端组件架构与状态管理方案
mode: subagent
model: opencode-go/qwen3.7-plus
temperature: 0.4
reasoningEffort: medium
max_tokens: 16384
hidden: true
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

.opencode/agents/前端·动效.md：

```markdown
---
description: 前端交互体验与动效方案
mode: subagent
model: opencode-go/mimo-v2.5-pro
temperature: 0.5
reasoningEffort: max
max_tokens: 16384
hidden: true
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

.opencode/agents/前端·总工.md：

```markdown
---
description: 三份前端方案择优融合（含置信度评分）
mode: subagent
model: opencode-go/glm-5.2
temperature: 0.3
reasoningEffort: high
max_tokens: 16384
hidden: true
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
---
你是前端总工。对比还原、逻辑、动效三份代码，选最优或融合。不得模棱两可。

## 评分维度（每项 0-20 分，满分 100）

1. **布局还原** — 像素级还原 UI 设计稿
2. **代码质量** — 组件化、响应式、TypeScript 类型安全
3. **交互体验** — 过渡动画和微交互
4. **视觉还原** — 颜色风格、间距、排版
5. **类型安全** — TS 类型定义完整性
6. **置信度** — 方案是否可行、有无幻觉、是否符合项目规范（新增）
   - 幻觉定义：编造的技术选型、不存在的 API、虚构的库

## 输出格式

评分(布局/代码质量/交互/视觉/TS/置信度) | 总分
对比结论: 最优方案是 X，理由:...
---最终代码---
（完整代码）
```

#### 残差提取者

.opencode/agents/残差提取者.md：

```markdown
---
description: 提取多方案间的残差信息，识别共识与分歧
mode: subagent
model: opencode-go/deepseek-v4-flash
temperature: 0.3
reasoningEffort: medium
max_tokens: 4096
hidden: true
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
---
你是残差提取专家。你的唯一任务是分析多个输入方案之间的差异，
找出共识之外的增量信息。

## 工作流程

1. **共识识别**：找出所有方案共同认可的核心决策
2. **分歧提取**：识别方案之间的矛盾点和不同点
3. **差异分类**：
   - 互补型：不同方案关注不同方面，可合并
   - 矛盾型：方案之间存在根本冲突，需择一
   - 冗余型：不同方案表达相同意思，保留最优表述
4. **幻觉标记**：标记可疑的技术选型、不存在的 API、虚构的库

## 输出格式

---残差报告---
【共识覆盖率】XX%

【共识部分】
- 决策1: ...
- 决策2: ...

【分歧处理】
分歧1:
  - 方案A: ...
  - 方案B: ...
  - 类型: 互补/矛盾/冗余
  - 处理: 融合/择一/舍弃

【疑似幻觉】
- 位置: 方案X
- 问题: 描述
- 置信度: 高/中/低

【残差补偿建议】
（共识之外的增量信息，建议补充的内容）
```

#### 置信度评估者

.opencode/agents/置信度评估者.md：

```markdown
---
description: 评估 MoA 融合结果的置信度和合规性
mode: subagent
model: opencode-go/deepseek-v4-pro
temperature: 0.2
reasoningEffort: max
max_tokens: 4096
hidden: true
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
---
你是置信度评估者。对 MoA 融合结果进行可信度审查。

## 评分标准（0-100，与门童路由员/旗舰·质检共享维度）

| 维度 | 权重 | 评分要点 |
|------|------|---------|
| 需求清晰度 | 0.25 | 输出是否回应了具体的用户约束 |
| 模型匹配度 | 0.20 | 所选技术方案是否匹配模型能力范围 |
| 任务复杂度 | 0.15 | 方案是否覆盖了任务的复杂度 |
| 技术熟悉度 | 0.10 | 是否使用了团队熟悉的成熟技术 |
| 上下文充分性 | 0.10 | 是否利用了已有材料和上下文 |
| 风险等级 | 0.10 | 是否识别了潜在风险 |

综合置信度 = 100 × Σ(维度得分 × 权重)

## 审查维度

1. **幻觉检测** — 编造的技术选型、不存在的 API、虚构的库
2. **要求对齐** — 是否满足用户原始需求的所有约束
3. **规范冲突** — 是否与项目已有规范/官方文档冲突
4. **可行性评估** — 在当前项目上下文中是否可落地

## 输出格式

---置信度报告---
综合置信度: X/100

幻觉风险: 高/中/低
  - [具体说明]

要求对齐度: X%
  - 未满足的约束: [...]

规范冲突: 有/无
  - [如有，列出冲突点]

可行性: 高/中/低
  - [理由]

---处置建议---
置信度 ≥ 85: 直接采纳
置信度 60-84: 有条件采纳 — [需修正的点]
置信度 < 60: 打回重做 — [主要原因]
```

#### 融合·保底

.opencode/agents/融合·保底.md：

```markdown
---
description: 融合层失败保底，对比三份输入输出一份（继承残差融合流程）
mode: subagent
model: opencode-go/deepseek-v4-pro
temperature: 0.3
reasoningEffort: max
max_tokens: 16384
hidden: true
permission:
  edit: deny
  bash: deny
  read: deny
  webfetch: deny
---
你是融合层保底 agent。你会收到三份方案/代码/意见，可能来自工程/创意/码农、架构/规划/工程、或还原/逻辑/动效视角。

## 融合流程

### 阶段1: 共识识别
- 识别三份方案共同认可的核心决策
- 计算共识覆盖率 = 共识决策数 / 总决策数

### 阶段2: 分歧处理
- 互补型 → 合并
- 矛盾型 → 择一
- 冗余型 → 保留最优表述

### 阶段3: 幻觉过滤
- 标记疑似幻觉：编造的技术选型、不存在的 API、虚构的库
- 幻觉标记的部分直接丢弃

## 输出格式

简述融合决策理由
---融合方案---
```
### Block 3：5 个 `/moa-*` 命令

每个命令一个文件在 `.opencode/commands/`。文件名统一 `moa-` 前缀。

**自检**：`Get-ChildItem .opencode/commands/*.md` 计数应为 5，全部以 `moa-` 开头。

```markdown
# moa-quick.md
---
description: 闪电侠快速处理简单任务（等价于直接说小任务）
---
执行闪电侠快速处理以下需求：
$ARGUMENTS
说明：此命令等价于直接说小任务。简单明确的任务直接由闪电侠处理。
复杂任务请使用 /moa-medium 或 /moa-flagship。
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
# moa-medium.md
---
description: 中级三重 MoA——3 意见并行 + 残差分析 + 融合
---
执行中级三重 MoA 处理以下需求：
$ARGUMENTS
流程：
1. @工具人 + @视觉翻译官 搜集材料（工具人需自检材料完整性）
2. @中级·工程 + @中级·创意 + @中级·码农 并行出方案
3. @残差提取者 分析三份方案的差异（共识覆盖率 < 95% 时执行）
4. @中级·融合 两阶段融合（共识+残差→融合输出）
5. @旗舰·质检 方案审查（可选，置信度 < 60 打回重做）
```

```markdown
# moa-flagship.md
---
description: 旗舰三重 MoA——3 架构意见 + 残差分析 + 融合 + 方案审查 + 实现 + 质检
---
执行旗舰三重 MoA 处理以下需求：
$ARGUMENTS
流程：
1. @工具人 + @视觉翻译官 搜集材料（工具人需自检材料完整性）
2. @旗舰·架构 + @旗舰·规划 + @旗舰·工程 并行出架构方案
3. @残差提取者 分析三份方案的差异（共识覆盖率 < 95% 时执行）
4. @旗舰·融合 三阶段融合（共识→残差→整合，幻觉过滤）
5. @旗舰·质检 方案审查（置信度评估，< 60 打回重做）
6. （按需求）@旗舰·实现 编码
7. @旗舰·质检 代码验收
8. @旗舰·质检 学习记录（记录典型问题标签）
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
description: 旗舰 MoA——三重架构意见 → 残差分析 → 融合 → 方案审查 → 实现 → 质检
---
<flow>
1. task(@工具人) + task(@视觉翻译官) 搜集材料（工具人自检）
2. task(@旗舰·架构) + task(@旗舰·规划) + task(@旗舰·工程) 并行
3. task(@残差提取者) 分析差异（共识 < 95% 时）
4. task(@旗舰·融合) 三阶段融合
5. task(@旗舰·质检) 方案审查（置信度评估）
6. task(@旗舰·实现) 编码
7. task(@旗舰·质检) 代码验收 + 学习记录
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

> ⚠️ provider 配置块已由 AI 在 Provider 节加入 `opencode.json`（`apiKey` 用 `{file:}` 引用外部文件），**不要重复写入**。

先读现有 `opencode.json`，合并 permissions.task 而不是覆盖。

> ✅ **`instructions` 不要写死**：下方 JSON 里 `instructions` 是**可选**的，默认注释掉。OpenCode 引用了不存在的 `AGENTS.md` 会在启动时报告警。
> 
> - 仅当**项目根目录已存在** `AGENTS.md` 时，才取消注释启用 `"instructions": ["AGENTS.md"]`。
> - 项目没有 `AGENTS.md` 就保持注释/省略——MoA 不替项目强加约定文件。
> - 想用自定义项目指引：自己建 `AGENTS.md` 后取消注释即可，无需改 agent。

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
      "前端·总工": "allow",
      "融合·保底": "allow",
      "残差提取者": "allow",
      "置信度评估者": "allow"
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
  // "instructions": ["AGENTS.md"],   // 可选：仅当项目根已有 AGENTS.md 才启用，否则留注释避免启动告警
  "compaction": {
    "auto": true,
    "reserved": 10000
  },
  "share": "manual",
  "snapshot": true
}
```

### Block 5.5：验证脚本 T0-static-verify.ps1（随部署生成）

> 手册前文与「部署成功判断」都引用 `pwsh .opencode/tests/T0-static-verify.ps1`。该脚本**不随仓库分发**，必须由部署过程在本步生成，否则其他用户照手册跑会找不到文件。把它写入 `.opencode/tests/T0-static-verify.ps1`：

```powershell
# T0-static-verify.ps1 — OpenCode MoA 静态部署校验
# 用法：pwsh .opencode/tests/T0-static-verify.ps1
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
Check "agents == 22 (got $($agents.Count))" ($agents.Count -eq 22)

$cmds = @(Get-ChildItem .opencode/commands/moa-*.md -ErrorAction SilentlyContinue)
Check "commands == 5 (got $($cmds.Count))" ($cmds.Count -eq 5)

$needSkills = 'code-review-moa','architecture-moa','frontend-moa'
$missing = $needSkills | Where-Object { -not (Test-Path ".opencode/skills/$_/SKILL.md") }
Check "3 个指定 skill 存在(缺: $($missing -join ','))" ($missing.Count -eq 0)

Check "opencode.json exists" (Test-Path opencode.json)

# provider 硬门：项目 或 系统级(.json/.jsonc) 需注册 opencode-go 且 apiKey 真实（非占位符/空）
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
Check "reasoningEffort x22 (got $re)" ($re -eq 22)

$task = (Select-String -Path .opencode/agents/*.md -Pattern 'task:' -ErrorAction SilentlyContinue).Count
Check "task: x9 (got $task)" ($task -eq 9)

Write-Host "`n== 结果：PASS=$pass FAIL=$fail WARN=$warn =="
if ($fail -gt 0) { exit 1 } else { exit 0 }
```

预期输出：全部 `PASS`（key 走系统级时 `WARN` 也视为通过），`FAIL=0` 即部署成功。

---

### Block 6：验证

> ⚠️ 下方 `bash` 验证脚本用了 `ls` / `wc` / `grep` / `find`，**只在 Linux / macOS / WSL / Git Bash 里能跑**。Windows 原生 CMD / PowerShell 没有这些命令，会直接报错。Windows 请用下面的 PowerShell 版。

**Linux / macOS / WSL / Git Bash：**

```bash
echo "=== 数量检查 ==="
ls .opencode/agents/*.md 2>/dev/null | wc -l
ls .opencode/commands/*.md 2>/dev/null | wc -l
find .opencode/skills -name "SKILL.md" 2>/dev/null | wc -l
test -f opencode.json && echo "Config ok" || echo "Config missing"
test -f .opencode/local/opencode-go.key && echo "Key file ok" || echo "Key file MISSING"
```

预期：Agent 22，Commands 5，Skills 3，Config ok。Key file 行：项目级放 key 时显示 `Key file ok`；**走系统级 `~/.config/opencode/` 时这里会显示 `Key file MISSING`——属正常**，只要系统级 provider 配了真实 key 即可（或用下方 T0 脚本校验，它对系统级 key 判定为 PASS）。

```bash
echo "=== 内容检查 ==="
grep "reasoningEffort:" .opencode/agents/*.md 2>/dev/null | wc -l
grep "task:" .opencode/agents/*.md 2>/dev/null | wc -l
ls .opencode/commands/moa-*.md 2>/dev/null | wc -l
```

预期：reasoningEffort 出现 22 次（全 agent），task: 出现 9 次（门童+8意见层），moa- 命令文件名匹配 5 个。

**Windows（PowerShell，原生可用）：**

```powershell
Write-Host "=== 数量检查 ==="
(Get-ChildItem .opencode/agents/*.md -ErrorAction SilentlyContinue).Count
(Get-ChildItem .opencode/commands/*.md -ErrorAction SilentlyContinue).Count
(Get-ChildItem .opencode/skills/*/SKILL.md -ErrorAction SilentlyContinue).Count
if (Test-Path opencode.json) { "Config ok" } else { "Config missing" }
if (Test-Path .opencode/local/opencode-go.key) { "Key file ok" } else { "Key file MISSING" }

Write-Host "=== 内容检查 ==="
(Select-String -Path .opencode/agents/*.md -Pattern "reasoningEffort:" -ErrorAction SilentlyContinue).Count
(Select-String -Path .opencode/agents/*.md -Pattern "task:" -ErrorAction SilentlyContinue).Count
(Get-ChildItem .opencode/commands/moa-*.md -ErrorAction SilentlyContinue).Count
```

预期同上。若 `Select-String` 计数偏高，是因为 `task:` 在门童和意见层 frontmatter 里都出现——正常，总数为 9（门童 1 + 8 个意见层各 1）。

> **完成部署**：以上全部验证通过后，**重启 opencode 使所有配置生效**。

### 部署成功怎么判断？

1. 重启 OpenCode 后，按 `Tab` 循环切换 agent（Win 桌面端亦可用 `Ctrl+.`），看到「门童路由员」
2. 输入 `@工具人` 能正常响应（如果无响应，检查 `.opencode/local/opencode-go.key` 的 key 是否正确）
3. 运行验证脚本：`pwsh .opencode/tests/T0-static-verify.ps1`，预期全部 PASS（FAIL=0）

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
2. `.opencode/agents/` 下是否有 22 个 .md 文件
3. 重启 OpenCode 后按 `Tab` 循环切换 agent（Win 桌面端亦可用 `Ctrl+.`）

**Q: `@工具人` 无响应？**
A: 确认 `.opencode/agents/工具人.md` 存在且 frontmatter 格式正确。

**Q: 报错 "model not found"？**
A: 模型 ID 不对或未订阅 OpenCode Go。运行 `/models` 检查模型列表。

**Q: MCP 工具被拦截？**
A: 正常行为。意见层被 `*_*:deny` 限制，防止绕过工具层自行获取材料。工具层正常可用。

**Q: 工具人报 Upstream request failed？**
A: provider 瞬时抖动，MoA 会自动重试 1 次。持续失败会 ask 用户选择等/跳过/免费模型。

**Q: 怎么切换回原来的 build/plan agent？**
A: 按 `Tab` 切换（Win 桌面端亦可用 `Ctrl+.`），或输入 `/build`、`/plan`。MoA 不影响内置 agent。

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
A: 用 `/models` 打开模型列表选免费模型（Win 桌面端亦可用 `Ctrl+'`）（DeepSeek V4 Flash Free 等）。免费模型上下文有限、可能较慢、数据可能被用于训练。

---

## 部署失败原因速查

按「部署能不能跑起来」分两类。**多数情况是「文件部署成功，但运行时全 agent 不可用」**——别被「文件都生成了」骗了，必须跑到步骤验证那一步才算数。

### A. 部署期就失败（文件没生成 / 配置报错）

| 现象                           | 根因                                                | 排查                                                                                    |
| ---------------------------- | ------------------------------------------------- | ------------------------------------------------------------------------------------- |
| `opencode --version` 报错 / 没装 | 没装或 PATH 没配（桌面端子 shell 常因 PATH 不同**误报**）          | 文件仍可部署；验证/运行需装 opencode：<https://opencode.ai/install>，重启桌面端                           |
| 启动报 `JSON parse error`       | `opencode.json` 多了逗号 / 注释写在 `.json` 而非 `.jsonc`   | 改名为 `.jsonc`，或去 [jsonlint](https://jsonlint.com) 校验                                   |
| 22 个 agent 文件数不对             | Block 2 写漏或被覆盖                                    | 按 Block 6 计数：agents=22                                                                |
| 版本 < 1.1.1                   | `hidden` / `task` / agent 级 `reasoningEffort` 不支持 | 升级 opencode 到 ≥ 1.3.4（`@ai-sdk/openai-compatible` 原生透传 reasoning，无需 `forceReasoning`） |
| `Tab` 循环切不到「门童路由员」（Win 桌面端: `Ctrl+.`）| `opencode.json` 不在项目根、或没重启                        | 见上方 Q「看不到门童」三点                                                                        |

### B. 运行时失败（文件齐全，但 agent 报错）

| 现象                                               | 根因                                                                                                                                                                  | 处理                                                                                           |
| ------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| 22 个 agent 全部 `Upstream request failed` / 静默失败   | **系统级和项目级都没配 `opencode-go` provider 或 key 无效**                                                                                                                      | 回 Provider 节配 key，重启                                                                         |
| 系统级 `opencode.json` 被删 / 目录为空，且项目也没 provider     | provider 只在被删文件里 → 任何处都无 provider 可解析                                                                                                                               | 重建 provider（默认写项目 `opencode.json`，或系统级），重启；T0 现会 `FAIL` 提示                                   |
| 同目录同时有 `opencode.json` 和 `opencode.jsonc`        | 官方未定义双文件优先级、内容还可能冲突                                                                                                                                                 | 同目录**只留一个**，且让保留那份含有效 `opencode-go` provider + 真实 key                                        |
| `apiKey` 是 `<YOUR_GO_API_KEY>` 占位符 / 空           | 看似配了，实则 401/403                                                                                                                                                     | 替换为真实 key；T0 现会 `FAIL` 拦截                                                                    |
| `@工具人` 无响应、日志 401/403                            | key 文件路径不对 / 占位符没替换 / key 失效                                                                                                                                        | 检查 `.opencode/local/opencode-go.key` 真实存在且内容正确                                               |
| 某 agent 突然 `Upstream request failed` + 日志含 `400` | `reasoningEffort` 取值非法（大写 / `max` 用到不支持的模型 / `extreme` 等）                                                                                                           | 对照下方矩阵改回小写合法值                                                                                |
| 推理强度「感觉没变」（始终默认档）                                | ①`reasoningEffort` 大写/非法值被网关 400 降级到默认；②模型不支持所选档位被 400；③`npm` 改成 `@ai-sdk/openai` 却没加 `forceReasoning`（仅此情况需要，且 ≥1.3.4）；④opencode 版本过低不支持 agent 级 `reasoningEffort`；⑤在 TUI 手切过「变体/推理档」，`model.json` 缓存的变体覆盖 agent 的 `reasoningEffort`（跨平台；WSL 走 Linux 路径；清缓存或改 agent 字段并重启才恢复） | 对照矩阵改回小写合法值；若确用 `@ai-sdk/openai` 才补 `forceReasoning: true` 并重启（本项目默认 `openai-compatible` 无需）；若踩 ⑤：删 model 选择缓存（Linux/macOS/WSL `~/.local/state/opencode/model.json`、Windows `%USERPROFILE%\.local\state\opencode\model.json`，Unix 下受 `XDG_STATE_HOME` 影响可重定向）或改 agent 的 `reasoningEffort` 字段并重启 |
| 门童编排时 `task` 调用被拒                                | `opencode.json` 的 `permission.task` 白名单漏了 agent 名 / 中文名/· 不匹配                                                                                                       | 对照 Block 5 白名单补全                                                                             |
| 意见层想用 MCP 被拦                                     | 设计如此（`*_*: deny`）                                                                                                                                                   | 正常；材料必须经工具人层                                                                                 |
| 免费模型上下文不够、丢信息                                    | 免费模型窗口小                                                                                                                                                             | 选 C 降级时要有心理预期                                                                                |

### 跨平台注意事项

- **CLI / 桌面 GUI**：同一引擎、同配置路径，都可用。唯一区别：桌面端无 TUI，`/connect`（方式 B）用不了，只能用方式 A 写配置文件。
- **Linux / macOS**：`install.sh` + Block 6 的 bash 验证脚本原生可跑，需 `jq`（可选）。
- **Windows**：
  - 系统级路径是 `C:\Users\<你>\.config\opencode\opencode.json`（**不是** `%APPDATA%\opencode`，那是别的工具，别混）。
  - 没有原生命令 `cp` / `ls` / `wc` / `grep` / `find`。复制用 `Copy-Item`/`xcopy`（见上方 Q），验证用上方 **PowerShell 版 Block 6**。
  - `pwsh`（PowerShell Core）不是默认，没装也能用方式一/三部署；验证脚本改用原生 PowerShell 即可。
- **headless / CI / WSL**：纯配置文件方式（方式 A）全可用，无需 TUI、无需交互。
- **模型行为（reasoningEffort 矩阵、配额）与平台无关**，只看 OpenCode Go 网关，三平台一致。

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

> **文档版本**：v0.0.9 | **对应 opencode**：>= 1.3.4（agent 级 reasoningEffort/hidden/task 支持；`@ai-sdk/openai-compatible` 原生透传 reasoning，无需 `forceReasoning`）
