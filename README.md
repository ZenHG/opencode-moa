# 

> # OpenCode MoA

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![OpenCode](https://img.shields.io/badge/OpenCode-%3E%3D1.1.1-orange.svg)](https://opencode.ai)

> **一个模型不够用？那就用 19 个，让它看起来像一个超级模型。**

OpenCode MoA 是 OpenCode 的 Mixture of Agents 配置包。它让多个模型**同时思考同一个问题**，然后融合出单一模型无法达到的输出质量。你不需要换工具、不需要写代码、不需要 API 额度——只需要把文件放进项目，重启 OpenCode。

**19 个 agent · 5 个命令 · 3 个 skill · 快速部署**

## 它做了什么？

```
你：帮我设计一个消息队列方案

    ┌─ 旗舰·架构 (Qwen) ─── 从架构师视角出方案
    ├─ 旗舰·规划 (GLM)  ─── 从产品经理视角出方案
    ├─ 旗舰·工程 (Pro)  ─── 从实现者视角出方案
    └─ 旗舰·融合 (Kimi) ─── 取长补短，一份最优解
```

**单一模型**只有一种思维方式，容易陷入盲区。**MoA** 用三个不同模型的三份独立方案，天然形成"共识 + 分歧"结构，融合模型能识别哪些是共识直接保留、哪些是分歧取长补短。

## 为什么不是调参，而是真正的多模型协作？

|      | 传统做法            | MoA 做法                          |
| ---- | --------------- | ------------------------------- |
| 模型选择 | 手动切换，一次一个       | 自动调度，按复杂度分层                     |
| 决策质量 | 单一视角，有盲区        | 3 份独立意见 + 融合                    |
| 成本控制 | 全部用贵模型，或全部用便宜模型 | 简单任务用 Flash（~80%），复杂任务才调旗舰（~2%） |
| 覆盖范围 | 一个模型处理所有环节      | 工具层搜材料 → 意见层出方案 → 融合层出最优解       |

## 30 秒部署

### 方式一：AI 自动部署（推荐）

1. 下载 [`docs/opencode-moa.md`](https://github.com/ZenHG/opencode-moa/blob/master/docs/opencode-moa.md)
2. 在 OpenCode 中上传该文档，发送：

> 请按这份部署手册，帮我把 19 个 agent、5 个命令、3 个 skill 全部部署到当前项目

3. AI 会自动创建所有文件。完成后**重启 OpenCode** 即可。

> 全程不需要手动创建任何文件。部署手册本身就是安装器。

### 方式二：手动安装

```bash
git clone https://github.com/ZenHG/opencode-moa.git
cp -r opencode-moa/.opencode/ your-project/
cat opencode-moa/opencode.json >> your-project/opencode.json
# 重启 OpenCode
```

### 不喜欢？一键回滚

```bash
rm -rf your-project/.opencode/
```

## 怎么用？

OpenCode 原有两个内置 agent：**build**（全功能开发）和 **plan**（只读分析）。部署 MoA 后，新增**门童路由员**作为默认入口——它不写代码、不改文件，只根据任务复杂度自动调度其他 19 个 agent。

**什么都不用学，直接说话就行。** 门童会自动判断任务复杂度，调度对应的 agent 链。

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
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
        工具层             意见层            融合层
     Flash + MiMo      3 份并行意见         取长补短
     （~80% 调用）      （~18% 调用）      （~2% 调用）
```

**工具层**（Flash + MiMo）—— 读代码、搜文件、截图转文字。便宜快，随便调。
**意见层**（Pro / MiniMax / Qwen / MiMo-Pro）—— 从不同视角出方案。三份意见天然形成"共识 + 分歧"结构。
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
 │   中级·工程    (Pro)          工程视角方案
 │   中级·创意    (MiniMax)      创意视角方案
 │   中级·码农    (Flash)        实战视角方案
 │   中级·融合    (Kimi)         三份方案取长补短
 │
 ├── 旗舰意见层 ──────────────────────────────────
 │   旗舰·架构    (Qwen3.7Max)   顶层架构设计
 │   旗舰·规划    (GLM)          结构化方案设计
 │   旗舰·工程    (Pro)          大规模实现方案
 │   旗舰·融合    (Kimi)         三份架构方案融合
 │   旗舰·实现    (Flash)        按融合方案编码
 │   旗舰·质检    (Pro)          方案 vs 代码验收
 │
 └── 前端意见层 ──────────────────────────────────
     前端·还原    (MiMo)        像素级还原 UI
     前端·逻辑    (Qwen3.7Plus) 组件架构与状态管理
     前端·动效    (MiMo-Pro)    交互体验与动效
     前端·总工    (Kimi)        三份前端方案择优
```

## 成本

| 层级  | 模型                              | 调用频率      |
| --- | ------------------------------- | --------- |
| 工具层 | Flash + MiMo                    | ~80%（随便调） |
| 意见层 | Pro / MiniMax / Qwen / MiMo-Pro | ~18%      |
| 融合层 | Kimi / Qwen-Max / GLM           | ~2%（刀刃上）  |

> 所有模型 ID 仅作声明，可替换为你偏好的任何模型。

## 安全

| 防护           | 效果                           |
| ------------ | ---------------------------- |
| 全局 catch-all | 未声明的工具调用 → 弹窗确认              |
| Agent 权限隔离   | 每个 agent 只能用允许的工具            |
| task 白名单     | 门童只能调用声明过的 agent             |
| 降级链          | 任务失败 → 重试 → 换同类 → 降级内置 agent |
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
