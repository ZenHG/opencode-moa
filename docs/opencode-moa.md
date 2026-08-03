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

该降级链已在门童 prompt 中实现。用户选择后才会继续执行，不会跳过 ask 自动路由。

---

默认 opencode 只有一个模型从头处理到尾。改一行字和设计一套系统架构用的是同一个 prompt、同一个温度、同一个上下文。没有分工。

这套方案部署一个 **门童 + 21 个专业 agent** 的 Cost-Optimal MoA 架构。核心设计原则只有一条：

> **搬砖用 flash 和 MiMo，意见用中端，融合用旗舰。** 每个模型只干自己最擅长的事，不浪费一次调用。

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
| deepseek-v4-flash | 400 | 400    | OK   | OK   | 400   | 400  | 400     | 仅 high/max 支持，其余 400（0731 起） |
| mimo-v2.5         | OK  | OK     | OK   | 500* | 500*  | 500* | 500*    | max/xhigh 偶发 500，建议用 high |
| mimo-v2.5-pro     | OK  | OK     | OK   | OK   | OK    | OK   | OK      | 全档支持                      |
| minimax-m3        | OK  | OK     | OK   | OK   | OK    | OK   | OK      | 全档支持                      |
| glm-5.2           | OK  | OK     | OK   | OK   | OK    | OK   | 400     | 已退役，被 deepseek-v4-flash 替代 |
| qwen3.7-max       | OK  | OK     | OK   | 400  | OK    | OK   | OK      | `max` 反而 400，最高用 `xhigh`  |
| qwen3.7-plus      | OK  | OK     | OK   | 400  | OK    | OK   | OK      | `max` 反而 400，最高用 `xhigh`  |
| kimi-k2.7-code    | OK  | OK     | OK   | 400  | 400   | 400  | OK      | 最高只到 `high`               |
| deepseek-v4-pro   | OK  | OK     | OK   | OK   | OK    | 400  | 400     | 全档支持                      |

**规则：**

1. 取值必须小写：`low` / `medium` / `high` / `max` / `xhigh` / `none` / `minimal`。大写 `Medium`/`High` 一律 400。
2. `extreme` / `extended` / `xmedium` / `adaptive` / `auto` 在所有模型上均 400，不可用。
3. 某模型不支持的取值 → 该 agent 直接 400（`Upstream request failed`），**不会回退默认强度**。默认值仅在完全不写 `reasoningEffort` 时生效。
4. 本方案参数：工具/快任务层用 `high`（flash 体系仅 high/max，高调用量、控成本）；保底/特殊工具位可保留 `medium`；意见层/融合层按模型最高支持档提档（minimax/pro/mimo-pro→`max`，qwen-max→`xhigh`，kimi→`high`），最大化推理质量。

> ⚠️ **不要在 TUI 里手动切「变体 / 推理档」**：OpenCode 的变体选择（桌面端 `Ctrl+t`、或模型列表里手选）会**覆盖** agent 在 `opencode.json` / agent `.md` 里配的 `reasoningEffort`，并写入 model 选择缓存——Linux / macOS / **WSL** `~/.local/state/opencode/model.json`（WSL 虽跑在 Windows 上，但走 Linux 路径，不是 Windows 路径）、Windows `%USERPROFILE%\.local\state\opencode\model.json`——**重启仍生效（两种路径形态已覆盖全部平台，跨平台一致）**。注：Unix 下该路径受 `XDG_STATE_HOME` 影响可重定向。一旦手切过，本矩阵的 low→xhigh 档位会被静默顶掉且难察觉。要改推理强度，请改 agent 的 `reasoningEffort` 字段并重启，而不是在 TUI 手切变体。

### @ 菜单显示上限与 hidden 约定

OpenCode 的 `@` 自动补全菜单有**显示行数上限**（约 10 行），agent 超过后会被截断、不再显示。排序按名称，与类别无关。

应对：把**只由门童通过 Task 工具编排、用户几乎不手敲 @ 调用**的 agent 设为 `hidden: true`。该字段**仅隐藏 @ 菜单项，不阻止 Task 调用**（门童正是用 Task 调它们），行为与融合链不受影响。

**设为 `hidden: true` 的 18 个 agent（仅隐藏 @ 菜单，不阻止门童用 Task 调用）：**

- 残差提取 / 置信度评估 / 融合·保底（分析 / 保底层，门童驱动）
- 工具人-mimo（工具人保底，门童重试链驱动）
- 中级·工程 / 中级·创意 / 中级·码农 / 中级·融合（中级意见 + 融合链）
- 旗舰·架构 / 旗舰·规划 / 旗舰·工程 / 旗舰·融合 / 旗舰·执行 / 旗舰·质检（旗舰融合链）
- 前端·还原 / 前端·逻辑 / 前端·动效 / 前端·总工（前端融合链）

**保持可见（用户常手 @）：** 工具人、视觉翻译、闪电侠，加内置 explore / general。

> `hidden` 仅对 `mode: subagent` 生效；primary agent（门童）不在 @ 菜单中，无需设置。

> 🔧 **自定义 —— 一切都不捆绑死。** agent 名称与各自的 `model` 都是「起始建议」，不是契约：
> - **模型**：把任意 agent 的 `model:` 改成你有权限的任何模型/provider 即可。provider 块里那 9 个 `opencode-go` 模型 ID 仅是声明，随便换（比如不用 Go，改用你自己的 Anthropic/OpenAI key）。
> - **agent 名称**：可以改名，但改名是「全局替换」——必须同步更新**每一处**引用，否则部署会坏：门童的 `task:` 白名单、`opencode.json` 的 `permission.task` 白名单，以及所有跨 agent 的 `@`/task 调用。漏改一处，该 agent 就失联（task 调用被拒）。
> - **路由员本身**：`门童` 要在它自己的 frontmatter、上面的 `task:` 白名单、`opencode.json` 的 `default_agent` 三处保持一致。

### Block 2：22 个 Agent 文件

所有 agent 写到 `.opencode/agents/`。写前先检查目录已有文件，避免覆盖同名文件。

写文件顺序：

1. 门童（primary）
2. 工具人 → 工具人-mimo → 闪电侠 → 视觉翻译
3. 中级·工程 → 中级·创意 → 中级·码农 → 中级·融合
4. 旗舰·架构 → 旗舰·规划 → 旗舰·工程 → 旗舰·融合 → 旗舰·执行 → 旗舰·质检
5. 前端·还原 → 前端·逻辑 → 前端·动效 → 前端·总工
6. 残差提取 → 置信度评估 → 融合·保底（hidden，门童驱动）

**自检**：`Get-ChildItem .opencode/agents/*.md` 计数应为 22。

#### Agent 清单（22 个）

全部文件在 `.opencode/agents/`，**部署时从仓库复制即可，无需重写**；frontmatter 与提示词以仓库文件为准。

| Agent | 文件 | model | hidden | 说明 |
|-------|------|-------|--------|------|
| 残差提取 | 残差提取.md | model: opencode-go/deepseek-v4-flash | hidden | 提取多方案间的残差信息，识别共识与分歧 |
| 工具人-mimo | 工具人-mimo.md | model: opencode-go/mimo-v2.5 | hidden | 工具人，MiMo模型保底 |
| 工具人 | 工具人.md | model: opencode-go/deepseek-v4-flash |  | 读代码搜文件调MCP，不给意见 |
| 门童 | 门童.md | model: opencode-go/deepseek-v4-flash |  | 智能路由引擎，负责任务理解、条件激活与流水线编排 |
| 旗舰·工程 | 旗舰·工程.md | model: opencode-go/deepseek-v4-flash | hidden | 大规模实现视角方案 |
| 旗舰·规划 | 旗舰·规划.md | model: opencode-go/deepseek-v4-flash | hidden | 结构化方案设计 |
| 旗舰·架构 | 旗舰·架构.md | model: opencode-go/qwen3.7-max | hidden | 顶层架构设计 |
| 旗舰·融合 | 旗舰·融合.md | model: opencode-go/kimi-k3 | hidden | 三份架构方案取长补短（残差增强融合） |
| 旗舰·执行 | 旗舰·执行.md | model: opencode-go/deepseek-v4-flash | hidden | 按融合方案编码落地 |
| 旗舰·质检 | 旗舰·质检.md | model: opencode-go/deepseek-v4-pro | hidden | 对比方案和代码全维度验收（含方案审查 + 学习记录） |
| 前端·动效 | 前端·动效.md | model: opencode-go/mimo-v2.5-pro | hidden | 前端交互体验与动效方案 |
| 前端·还原 | 前端·还原.md | model: opencode-go/qwen3.7-plus | hidden | 像素级还原UI设计稿 |
| 前端·逻辑 | 前端·逻辑.md | model: opencode-go/qwen3.7-plus | hidden | 前端组件架构与状态管理方案 |
| 前端·总工 | 前端·总工.md | model: opencode-go/deepseek-v4-flash | hidden | 三份前端方案择优融合（含置信度评分） |
| 融合·保底 | 融合·保底.md | model: opencode-go/deepseek-v4-pro | hidden | 融合层失败保底，对比多份输入输出一份（继承残差融合流程，支持部分输入降级） |
| 闪电侠 | 闪电侠.md | model: opencode-go/deepseek-v4-flash |  | 快速处理简单零碎任务 |
| 视觉翻译 | 视觉翻译.md | model: opencode-go/qwen3.7-plus |  | 截图/UI图/报错图转文字描述；无截图时降级为复杂内容解构 |
| 置信度评估 | 置信度评估.md | model: opencode-go/deepseek-v4-flash | hidden | 评估 MoA 融合结果的置信度和合规性 |
| 中级·创意 | 中级·创意.md | model: opencode-go/qwen3.7-plus | hidden | 创意视角方案 |
| 中级·工程 | 中级·工程.md | model: opencode-go/kimi-k2.6 | hidden | 工程视角方案 |
| 中级·码农 | 中级·码农.md | model: opencode-go/deepseek-v4-flash | hidden | 实战视角方案 |
| 中级·融合 | 中级·融合.md | model: opencode-go/kimi-k2.7-code | hidden | 三份中级方案取长补短（残差增强融合） |

### Block 3：5 个 `/moa-*` 命令

每个命令一个文件在 `.opencode/commands/`，部署时从仓库复制。文件名统一 `moa-` 前缀。

**自检**：`Get-ChildItem .opencode/commands/*.md` 计数应为 5，全部以 `moa-` 开头。

| 命令 | 作用 |
|------|------|
| `/moa-quick` | 闪电侠快速处理简单任务 |
| `/moa-frontend` | 前端链（还原→逻辑→动效→总工融合） |
| `/moa-medium` | 中级链（三视角→融合→执行→质检） |
| `/moa-flagship` | 旗舰链（三视角→残差融合→执行→质检） |
| `/moa-describe` | 解释 MoA 配置与角色分工 |

### Block 4：3 个 Skill

3 个 skill 在 `.opencode/skills/`，部署时从仓库复制。

| Skill | 作用 |
|-------|------|
| `code-review-moa` | MoA 专用代码审查 |
| `architecture-moa` | MoA 架构设计评审 |
| `frontend-moa` | 前端方案专项审查 |

### Block 5：opencode.json

> ⚠️ provider 配置块已由 AI 在 Provider 节加入 `opencode.json`（`apiKey` 用 `{file:}` 引用外部文件），**不要重复写入**。

先读现有 `opencode.json`，合并 permissions.task 而不是覆盖。

> ✅ **`instructions` 已省略**：下方 JSON 是实际 `opencode.json` 的精确镜像，不包含 `instructions`。OpenCode 引用了不存在的 `AGENTS.md` 会在启动时报告警。
> 
> - 仅当**项目根目录已存在** `AGENTS.md` 时，才自行添加 `"instructions": ["AGENTS.md"]`。
> - 项目没有 `AGENTS.md` 就保持省略——MoA 不替项目强加约定文件。
> - 想用自定义项目指引：自己建 `AGENTS.md` 后自行添加即可，无需改 agent。

```jsonc
<!-- SYNC:BLOCK5 start -->
{
  "$schema": "https://opencode.ai/config.json",
  "default_agent": "门童",
  "subagent_depth": 2,
  "permission": {
    "*": "ask",
    "moa-loop_*": "allow",
    "grep": "allow",
    "glob": "allow",
    "list": "allow",
    "bash": {
      "*": "ask",
      "git status *": "allow",
      "git diff *": "allow",
      "git log *": "allow",
      "grep *": "allow",
      "ls *": "allow",
      "cd *": "allow",
      "npm run *": "allow",
      "rg *": "allow",
      "Select-String *": "allow",
      "Get-ChildItem *": "allow",
      "Get-Content *": "allow",
      "pwsh .opencode/tests/*": "allow",
      "rm *": "ask",
      "del *": "ask",
      "Remove-Item *": "ask",
      "rd *": "ask",
      "rmdir *": "ask"
    },
    "task": {
      "*": "deny",
      "工具人": "allow",
      "工具人-mimo": "allow",
      "闪电侠": "allow",
      "视觉翻译": "allow",
      "中级·工程": "allow",
      "中级·创意": "allow",
      "中级·码农": "allow",
      "中级·融合": "allow",
      "旗舰·架构": "allow",
      "旗舰·规划": "allow",
      "旗舰·工程": "allow",
      "旗舰·融合": "allow",
      "旗舰·执行": "allow",
      "旗舰·质检": "allow",
      "前端·还原": "allow",
      "前端·逻辑": "allow",
      "前端·动效": "allow",
      "前端·总工": "allow",
      "融合·保底": "allow",
      "残差提取": "allow",
      "置信度评估": "allow"
    },
    "webfetch": "allow",
    "read": {
      "*": "allow",
      "*.env": "deny",
      "*.env.*": "deny",
      "*.env.example": "allow"
    },
    "todowrite": "allow"
  },
  "agent": {
    "中级·工程": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    },
    "中级·创意": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    },
    "中级·码农": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    },
    "中级·融合": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    },
    "旗舰·架构": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    },
    "旗舰·规划": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    },
    "旗舰·工程": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    },
    "旗舰·融合": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    },
    "旗舰·执行": {
      "permission": {
        "*_*": "deny"
      }
    },
    "旗舰·质检": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    },
    "前端·逻辑": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    },
    "前端·动效": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    },
    "前端·总工": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    },
    "融合·保底": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    },
    "残差提取": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    },
    "置信度评估": {
      "permission": {
        "*_*": "deny",
        "read": "deny",
        "bash": "deny",
        "grep": "deny",
        "glob": "deny",
        "list": "deny",
        "webfetch": "deny",
        "websearch": "deny",
        "edit": "deny"
      }
    }
  },
  "compaction": {
    "auto": true,
    "reserved": 15000
  },
  "mcp": {
    "moa-loop": {
      "type": "local",
      "command": ["node","mcp/moa-loop/server.js"],
      "enabled": true
    }
  },
  "share": "manual",
  "snapshot": true
}
<!-- SYNC:BLOCK5 end -->
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
Check "task: x11 (got $task)" ($task -eq 11)

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

预期：reasoningEffort 出现 22 次（全 agent），task: 出现 11 次（门童+2工具人+8意见层），moa- 命令文件名匹配 5 个。

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

预期同上。若 `Select-String` 计数偏高，是因为 `task:` 在门童、工具人和意见层 frontmatter 里都出现——正常，总数为 11（门童 1 + 2 工具人 + 8 个意见层各 1）。

### Block 7：.moa/界线.json

> AI 自动部署时若文件已存在则跳过写入。下方内容由 `scripts/sync-docs.ps1` 从 `.moa/界线.json` 同步，勿手改。

`.moa/界线.json`：

```json
<!-- SYNC:MOA_BOUNDARIES start -->
{
  "$schema": "acceptance-criteria",
  "_description": "界线：融合层输出后写入此文件，后续只能追加 bonus 项。",
  "_usage": "旗舰·融合/中级·融合/融合·保底 输出时，将 ---验收标准--- 节内容写入此文件；执行层将进度写入 .moa/足迹.md，未决事项写入 .moa/拦路虎.md",
  "_rules": [
    "输出后冻结，不可修改基础条件",
    "只能追加bonus项",
    "旗舰·质检经 task(工具人) 独立复跑验证——执行者贴的输出不算数",
    "基线值必须标注",
    "暗卷项执行者不可见",
    "完成条件必须含至少 1 条 result 型（度量结果）+ 1 条 constraint 型（守约束）",
    "探索型任务的结论每条须带来源与日期，或可复跑的步骤"
  ],
  "taskId": "",
  "frozenAt": "",
  "pipeline": "旗舰链|中级链|前端链",
  "taskType": "执行型|探索型",

  "priorityOrder": "要求冲突时的让步顺序，如「算得对 > 做得全 > 做得快」",

  "whitelist": [
    "只允许修改的路径（白名单为主，红线兜底）"
  ],

  "decisionLog": [
    {
      "_description": "分歧裁决记录：残差报告的未决分歧",
      "issue": "分歧点",
      "default": "默认值（猜的）",
      "costIfWrong": "猜错的代价",
      "askUser": false
    }
  ],

  "criteria": [
    {
      "name": "验收项名称",
      "command": "可机器判定的验收命令",
      "baseline": "基线值（如 all pass / ≥80% / =3）",
      "type": "test|lint|build|custom",
      "metricType": "result|constraint"
    }
  ],

  "bonuses": [],

  "hiddenCriteria": [
    {
      "_description": "暗卷：执行者不可见的抽查项，管理者自留",
      "name": "抽查项名称",
      "command": "抽查命令",
      "baseline": "基线值",
      "visible": false
    }
  ],

  "notList": [
    "明确排除的范围（不改X、不碰Y、不加Z）"
  ],

  "exploreMode": {
    "_description": "探索型任务专属规格：taskType=探索型 时启用，执行型忽略",
    "conclusionLimit": "结论条数上限，宁收2条实的，不收10条凑的",
    "budget": "可承受损失（时间/来源数上限），烧完即交卷",
    "sourceRequired": "每条结论附来源+日期，或可复跑步骤",
    "deadEndIsPass": "此路不通=合格交付（带死因证据+原始输出）"
  },

  "antiCheating": {
    "_description": "红线·防作弊：反作弊机制，防止执行者作弊达标",
    "baselineNonRegression": {
      "testCount": "≥基线",
      "coverage": "≥基线",
      "skipped": 0
    },
    "forbiddenActions": [
      "skip/todo 跳过测试",
      "放松断言条件",
      "mock 被测对象",
      "删除测试",
      "|| true 吞失败",
      "改阈值或验收脚本"
    ],
    "mutationTest": {
      "_description": "验真试验（变异测试）：故意弄坏一次证明检查真的会报警。凡「坏了没人会知道」的检查都要这一步——贴变红输出，还原后贴全绿。检查失灵=验收全假，比 TDD 更关键（TDD 保证测试先于实现，验真保证检查不是摆设）",
      "required": true,
      "steps": [
        "挑一个验收命令，故意破坏对应实现（如删函数/改常量/跳过分支）",
        "重跑验收命令，必须变红（报警）",
        "还原破坏，重跑必须全绿",
        "把两次输出贴进足迹.md 的验证节"
      ]
    },
    "implementationDiffCheck": {
      "_description": "补测试类任务专用：实现目录 git diff 为空",
      "enabled": false,
      "path": "实现目录"
    }
  },

  "stopLoss": {
    "_description": "止损机制：连败换项，基线退化回滚",
    "maxRetriesPerItem": 3,
    "rollbackOnRegression": true,
    "maxTotalRounds": 10,
    "reportOnStop": "如实汇报卡在哪、还差什么"
  },

  "progressTracking": {
    "_description": "足迹机制：执行层开工前写 ≤10 行开工回执（理解的目标/顺序/最大风险），每完成一项立即更新 .moa/足迹.md；拿不准/受阻写 .moa/拦路虎.md 后跳过继续；收不回的操作停下写 .moa/拦路虎.md 做别的；交付时待裁决随交付提交（空则写「无」）"
  },

  "deliveryRequirements": {
    "_description": "交付要求：必须贴实际输出，只说做完了不算",
    "mustPasteCommandOutput": true,
    "mustIncludeReverseVerification": true
  },

  "status": "frozen|passed|failed",
  "verificationLog": []
}
<!-- SYNC:MOA_BOUNDARIES end -->
```

### Block 7.1：.moa/足迹模板.md（运行时文件模板）

> AI 自动部署时若文件已存在则跳过写入。下方内容由 `scripts/sync-docs.ps1` 从 `.moa/足迹模板.md` 同步，勿手改。

`.moa/足迹模板.md`：

```markdown
<!-- SYNC:MOA_FOOTPRINT start -->
# 足迹

> 运行时文件：旗舰·执行 开工前写开工回执，每完成一项立即更新。
> 格式参考本模板，直接改内容即可。交付时随 .moa/拦路虎.md 一起提交。

## 开工回执（≤10 行）

- 理解的目标：
- 执行顺序：
- 最大风险：

## 进度

| 步骤 | 状态 | 说明 |
|------|------|------|
| 任务0 核验 | 待开始 | 关键命令实测结果： |
| 步骤1 | 待开始 |  |
| 步骤2 | 待开始 |  |

## 记录

（每一步完成后在这里写一句：做了什么 / 结果 / 偏差原因）

## 断点恢复

> 会话中断/续跑时：先读完本文件 + 状态文件再动手，第一句话先复述「做到哪了」，禁止凭记忆续写。

- 上一次做到：
- 下一步动作：
- 未完成的原因：
<!-- SYNC:MOA_FOOTPRINT end -->
```

### Block 7.2：.moa/拦路虎模板.md（运行时文件模板）

> AI 自动部署时若文件已存在则跳过写入。下方内容由 `scripts/sync-docs.ps1` 从 `.moa/拦路虎模板.md` 同步，勿手改。

`.moa/拦路虎模板.md`：

```markdown
<!-- SYNC:MOA_BLOCKER start -->
# 拦路虎

> 运行时文件：旗舰·执行 拿不准/受阻/收不回的操作时写入，写完跳过继续做别的。
> 交付时随足迹一起提交；空文件也提交，写「无」。

## 拦路虎清单

- [ ] 问题：默认值（猜的）｜猜错代价
  背景：
  证据：

## 已裁决记录

（质检/用户裁决后移到这里：问题 → 裁决 → 依据）
<!-- SYNC:MOA_BLOCKER end -->
```

> **完成部署**：以上全部验证通过后，**重启 opencode 使所有配置生效**。

### 部署成功怎么判断？

1. 重启 OpenCode 后，按 `Tab` 循环切换 agent（Win 桌面端亦可用 `Ctrl+.`），看到「门童」
2. 输入 `@工具人` 能正常响应（如果无响应，检查 `.opencode/local/opencode-go.key` 的 key 是否正确）
3. 运行验证脚本：`pwsh .opencode/tests/T0-static-verify.ps1`，预期全部 PASS（FAIL=0）

### 一键回滚

```bash
rm -rf your-project/.opencode/
rm -rf your-project/.moa/
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

**Q: 看不到「门童」？**
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
| `Tab` 循环切不到「门童」（Win 桌面端: `Ctrl+.`）| `opencode.json` 不在项目根、或没重启                        | 见上方 Q「看不到门童」三点                                                                        |

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

> **文档版本**：v0.0.17 | **对应 opencode**：>= 1.3.4（agent 级 reasoningEffort/hidden/task 支持；`@ai-sdk/openai-compatible` 原生透传 reasoning，无需 `forceReasoning`）























