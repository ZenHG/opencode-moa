# OpenCode MoA

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![OpenCode](https://img.shields.io/badge/OpenCode-%3E%3D1.1.1-orange.svg)](https://opencode.ai)

> **一个对话入口，19 个专业模型自动协作。简单任务用 Flash（便宜），复杂任务才调旗舰（贵）。成本降低 90%，代码质量显著提升。**

OpenCode MoA 是 OpenCode 的 Mixture of Agents 配置包。它让多个模型**同时思考同一个问题**，然后融合出单一模型无法达到的输出质量。你不需要换工具、不需要写代码、不需要 API 额度——只需要把文件放进项目，重启 OpenCode。

**19 个 agent · 5 个命令 · 3 个 skill · 30 秒部署**

## 为什么需要这个？

默认 OpenCode 只有一个模型从头处理到尾。改一行字和设计一套系统架构用的是同一个 prompt、同一个温度、同一个上下文。没有分工。

**三个问题：**

1. **成本失控** — 简单任务也用贵模型，月账单居高不下
2. **质量瓶颈** — 单一模型只有一种思维方式，容易陷入盲区
3. **没有容错** — 模型挂了就卡死，没有降级方案

**MoA 的解法：**

```
你：帮我设计一个消息队列方案

    ┌─ 旗舰·架构 (Qwen) ─── 从架构师视角出方案
    ├─ 旗舰·规划 (GLM)  ─── 从产品经理视角出方案
    ├─ 旗舰·工程 (MiniMax) ─ 从实现者视角出方案
    └─ 旗舰·融合 (Kimi) ─── 取长补短，一份最优解
```

三个不同模型的三份独立方案，天然形成"共识 + 分歧"结构。融合模型识别哪些是共识直接保留、哪些是分歧取长补短——这是单一模型做不到的。

## 前置条件

### 必需

| 条件 | 检查命令 | 说明 |
|------|----------|------|
| OpenCode 已安装 | `opencode --version` | 版本 ≥ 1.1.1，[安装](https://opencode.ai/install) |
| OpenCode Go 订阅 | opencode.ai 控制台 | [订阅](https://opencode.ai/auth)，首月 $5，之后 $10/月 |
| Git 已安装 | `git --version` | 用于克隆仓库 |
| OpenCode Go API Key | opencode.ai 控制台创建 | 在 Zen 控制台（opencode.ai）创建 |

### 可选（安装脚本需要）

| 条件 | 检查命令 | 说明 |
|------|----------|------|
| PowerShell Core | `pwsh --version` | install.ps1 需要，Windows 自带或 `brew install powershell` |
| jq | `jq --version` | install.sh 合并 JSON 需要，`apt install jq` / `brew install jq` |

> 没有 pwsh/jq 也没关系，可以用方式一（AI 自动部署）或方式三（手动合并）。

### 桌面端 vs CLI

- **CLI**：所有方式都支持
- **桌面端**：方式一（AI 自动部署）最方便，方式二/三需要先在终端操作

## 30 秒部署

### 方式一：AI 自动部署（推荐）

1. 下载 [`docs/opencode-moa.md`](https://github.com/ZenHG/opencode-moa/blob/master/docs/opencode-moa.md)
2. 在 OpenCode 中上传该文档，发送：

> 请按这份部署手册，帮我把 19 个 agent、5 个命令、3 个 skill 全部部署到当前项目

3. AI 会自动创建所有文件。完成后**重启 OpenCode** 即可。

> 全程不需要手动创建任何文件。部署手册本身就是安装器。

### 方式二：一键安装脚本（推荐）

```bash
# 克隆仓库
git clone https://github.com/ZenHG/opencode-moa.git

# 进入你的项目目录
cd your-project

# 从仓库复制 .opencode 目录
cp -r ../opencode-moa/.opencode/ .

# 运行安装脚本（自动合并配置，保留你的 API key）
# Windows:
pwsh ../opencode-moa/install.ps1
# Linux/macOS:
bash ../opencode-moa/install.sh
```

> 安装脚本会自动备份原 `opencode.json`，只合并 MoA 配置，保留你的 provider 和 API key。

### 方式三：手动安装

```bash
# 1. 克隆仓库
git clone https://github.com/ZenHG/opencode-moa.git

# 2. 复制 .opencode 目录
cp -r opencode-moa/.opencode/ your-project/

# 3. 手动合并 opencode.json（不要直接替换！）
# 打开 opencode.json，将 MoA 的 permission.task 和 agent 部分合并进去
# 保留你已有的 provider 和 model 配置
```

> ⚠️ **不要** 用 `cat >>` 追加，会导致 JSON 格式错误。**不要** 直接替换，会丢失 API key。

### 部署成功怎么判断？

1. 重启 OpenCode 后，按 `Ctrl+.` 切换 agent，看到「门童路由员」
2. 输入 `@工具人` 能正常响应
3. 运行验证脚本：`pwsh .opencode/tests/T0-static-verify.ps1`，预期 41 PASS

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
A: 方式一最方便——把 `docs/opencode-moa.md` 拖进对话框，让 AI 自动部署。方式二/三需要先在终端（CMD/PowerShell/Terminal）操作。

### 使用相关

**Q: 看不到「门童路由员」？**
A: 检查三点：
1. `opencode.json` 是否在项目根目录（不是子目录）
2. `.opencode/agents/` 下是否有 19 个 .md 文件
3. 重启 OpenCode 后按 `Ctrl+.` 切换 agent

**Q: `@工具人` 无响应？**
A: 确认 `.opencode/agents/工具人.md` 存在且 frontmatter 格式正确。

**Q: 报错 "model not found"？**
A: 模型 ID 格式应为 `provider/model-id`（如 `opencode-go/kimi-k2.7-code`）。在配置文件（系统级 `~/.config/opencode/opencode.json` 或项目 `opencode.json`）注册对应的 provider，然后在 TUI 内用 `/models` 查看可用模型。

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
A: 输入 `/models` 选择带 "Free" 标签的模型（如 DeepSeek V4 Flash Free、MiMo-V2.5 Free、Big Pickle 等）。免费模型上下文有限、可能较慢、数据可能被用于训练。

## 怎么用？

**什么都不用学，直接说话就行。** 门童路由员会自动判断任务复杂度，调度对应的 agent 链。

| 你说的话         | 门童做的事                          | 用到的 agent        |
| ------------ | ------------------------------ | ---------------- |
| "把这个变量名改了"   | 判定为简单任务                        | 闪电侠（Flash）       |
| "写个用户认证模块"   | 工具层搜材料 → 3 中端并行 → 融合           | 工具人 + 中级三剑客 + 融合 |
| "设计微服务架构"    | 工具层搜材料 → 3 旗舰并行 → 融合 → 编码 → 质检 | 全链路 6 个 agent    |
| "还原这个截图的 UI" | 三前端专家并行 → 总工择优                 | 前端四人组            |
| 带截图的消息       | 视觉翻译官转文字 → 正常路由                | 视觉翻译官            |

**直接 @ 调用：**

```
@闪电侠 帮我写个 hello world
@工具人 搜一下项目里所有 TODO
@旗舰·架构 设计一个消息队列方案
```

**一键命令：**

| 命令              | 场景                |
| --------------- | ----------------- |
| `/moa-quick`    | 简单任务、翻译、改配置       |
| `/moa-medium`   | 函数模块、bug 修复、单文件重构 |
| `/moa-flagship` | 系统架构、大型重构         |
| `/moa-frontend` | UI 还原、CSS、截图修复    |
| `/moa-describe` | 截图/图片转文字          |

## 架构

```
                     门童路由员（Flash）
                            │
              ┌─────────────┼─────────────┐
              ▼             ▼             ▼
           工具层          意见层          融合层
        Flash + MiMo    3 份并行意见      取长补短
        （~80% 调用）   （~18% 调用）    （~2% 调用）
```

**工具层**（Flash + MiMo）—— 读代码、搜文件、截图转文字。便宜快，随便调。

**意见层**（MiniMax / DeepSeek Pro / Qwen / MiMo-Pro）—— 从不同视角出方案。三份意见天然形成"共识 + 分歧"结构。

**融合层**（Kimi / Qwen-Max / GLM）—— 识别共识直接保留，分歧取长补短。只用在刀刃上。

## 19 个 Agent

```
门童路由员 (Flash)
 │
 ├── 工具层 ──────────────────────────────────────
 │   工具人      (Flash)        读代码搜文件
 │   工具人-mimo (MiMo)        可靠读文件（保底+并行）
 │   闪电侠      (Flash)        简单任务一步到位
 │   视觉翻译官   (MiMo)        截图/UI图/报错图转文字
 │
 ├── 中级意见层 ──────────────────────────────────
 │   中级·工程    (MiniMax M3)   工程视角方案
 │   中级·创意    (DeepSeek Pro) 创意视角方案
 │   中级·码农    (Flash)        实战视角方案
 │   中级·融合    (Kimi)         三份方案取长补短
 │
 ├── 旗舰意见层 ──────────────────────────────────
 │   旗舰·架构    (Qwen3.7Max)   顶层架构设计
 │   旗舰·规划    (GLM)          结构化方案设计
 │   旗舰·工程    (MiniMax M3)   大规模实现方案
 │   旗舰·融合    (Kimi)         三份架构方案融合
 │   旗舰·实现    (Flash)        按融合方案编码
 │   旗舰·质检    (DeepSeek Pro) 方案 vs 代码验收
 │
 └── 前端意见层 ──────────────────────────────────
     前端·还原    (MiMo)        像素级还原 UI
     前端·逻辑    (Qwen3.7Plus) 组件架构与状态管理
     前端·动效    (MiMo-Pro)    交互体验与动效
     前端·总工    (Kimi)        三份前端方案择优
```

## 容错设计

### 降级链

工具层挂了不会卡死，自动降级：

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

### MCP 权限隔离

意见层 agent 被禁止访问 MCP 工具，防止绕过工具层自行获取材料：

- 工具层：可以调用 MCP（读代码、搜文件）
- 意见层：`read: deny` + MCP 被拦截，只能基于工具层提供的材料出方案
- 融合层：同上，只能基于三份意见融合

### 无材料保底

意见层被调用但没有材料时（工具层全部失败），会 ask 用户：

- 选"直接出方案" → 基于需求描述纯逻辑推演（不读代码）
- 选"等工具层恢复" → 输出 WAITING，等工具层恢复后重试

### 错误分类

工具层失败时输出明确的错误类别，不再盲目重试：

- `ERROR_PROVIDER` — 服务端 502/503/timeout
- `ERROR_AUTH` — 认证失败
- `ERROR_UNKNOWN` — 其他错误

## 成本

### OpenCode Go 订阅

MoA 基于 [OpenCode Go](https://opencode.ai/docs/zh-cn/go/) 订阅，**首月 $5，之后 $10/月**。

**使用限制：**

| 时间窗口 | 额度 |
|----------|------|
| 每 5 小时 | $12 |
| 每周 | $30 |
| 每月 | $60 |

限制按美元价值定义。便宜模型（Flash）可用更多次，贵模型（GLM）可用较少次。

### 各层级月配额

| 层级 | 模型 | 单价（输入/输出 per 1M） | 月配额 | 调用频率 |
|------|------|--------------------------|--------|----------|
| 工具层 | Flash | $0.14 / $0.28 | 158,150 次 | ~80% |
| 工具层 | MiMo-V2.5 | $0.14 / $0.28 | 150,400 次 | （随便调） |
| 意见层 | MiniMax M3 | $0.30 / $1.20 | 16,000 次 | ~18% |
| 意见层 | DeepSeek V4 Pro | $1.74 / $3.48 | 17,150 次 | |
| 意见层 | Qwen3.7 Plus | $0.40 / $1.60 | 21,600 次 | |
| 融合层 | Kimi K2.7 Code | $0.95 / $4.00 | 9,250 次 | ~2% |
| 融合层 | Qwen3.7 Max | $2.50 / $7.50 | 4,770 次 | （刀刃上） |
| 融合层 | GLM-5.2 | $1.40 / $4.40 | 4,300 次 | |

> 所有模型 ID 仅作声明，可替换为你偏好的任何模型。

### 达到限制后

- **免费模型保底** — Go 达到限制后可继续使用免费模型
- **Zen 余额回退** — 在控制台启用「使用余额」，Go 限制后自动用 Zen 余额

### 免费模型

OpenCode Zen 提供免费模型作为最后保底：

| 模型 | 特点 |
|------|------|
| DeepSeek V4 Flash Free | 快，但上下文有限 |
| MiMo-V2.5 Free | 质量较好，但可能慢 |
| North Mini Code Free | Cohere 提供 |
| Nemotron 3 Ultra Free | NVIDIA 免费端点 |

> ⚠️ 免费模型限制：上下文窗口较小、响应可能较慢、数据可能被用于训练、限时免费。

## 安全

| 防护           | 效果                           |
| ------------ | ---------------------------- |
| 全局 catch-all | 未声明的工具调用 → 弹窗确认              |
| Agent 权限隔离   | 每个 agent 只能用允许的工具            |
| MCP 权限隔离     | 意见层禁止访问 MCP，防止绕过工具层           |
| task 白名单     | 门童只能调用声明过的 agent             |
| 降级链          | 工具层失败 → ask 用户 → 等待/跳过/免费模型 |
| 一键回滚         | 删掉 `.opencode/` 目录即可还原       |

## 本地模型

支持 Ollama / LM Studio 等本地模型混用：

```yaml
# .opencode/agents/中级·码农.md
model: ollama-local/qwen3-coder
```

详见 [`docs/opencode-moa.md`](docs/opencode-moa.md) 附录 A。

## 验证

部署后运行静态检查（需要 `pwsh`）：

```bash
pwsh .opencode/tests/T0-static-verify.ps1
# 预期：41 PASS / 0 FAIL
```

## 贡献

欢迎提交 PR 和 Issue。详见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## License

[MIT](LICENSE) · [OpenCode MoA](https://github.com/ZenHG/opencode-moa)
