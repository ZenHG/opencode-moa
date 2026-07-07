# OpenCode MoA

19-agent Cost-Optimal MoA (Mixture of Agents) 配置，适用于 [OpenCode](https://opencode.ai)。

搬砖用 flash 和 MiMo，意见用中端，融合用旗舰。每个模型只干自己最擅长的事。

## 架构概览

`
门童路由员 (flash)
  ├── 工具层：工具人(flash) + 工具人-mimo(MiMo) + 视觉翻译官(MiMo)
  ├── 中级意见：工程(Pro) + 创意(MiniMax) + 码农(flash) → 融合(Kimi)
  ├── 旗舰意见：架构(Qwen3.7Max) + 规划(GLM) + 工程(Pro) → 融合(Kimi) → 实现(flash) → 质检(Pro)
  └── 前端意见：还原(MiMo) + 逻辑(Qwen3.7Plus) + 动效(MiMoPro) → 总工(Kimi)
`

## 文件结构

`
opencode-moa/
├── opencode.json                  # 配置入口（合并到已有配置）
├── .opencode/
│   ├── agents/                    # 19 个 agent 定义
│   │   ├── 门童路由员.md           # primary，路由分发
│   │   ├── 工具人.md              # flash，快速读文件
│   │   ├── 工具人-mimo.md         # MiMo，可靠读文件
│   │   ├── 闪电侠.md              # flash，简单任务执行
│   │   ├── 视觉翻译官.md          # MiMo，截图转文字
│   │   ├── 中级·工程.md           # Pro，工程视角意见
│   │   ├── 中级·创意.md           # MiniMax，创意视角意见
│   │   ├── 中级·码农.md           # flash，实战视角意见
│   │   ├── 中级·融合.md           # Kimi，三意见融合
│   │   ├── 旗舰·架构.md           # Qwen3.7Max，架构意见
│   │   ├── 旗舰·规划.md           # GLM，规划意见
│   │   ├── 旗舰·工程.md           # Pro，工程意见
│   │   ├── 旗舰·融合.md           # Kimi，架构融合
│   │   ├── 旗舰·实现.md           # flash，编码实现
│   │   ├── 旗舰·质检.md           # Pro，方案验收
│   │   ├── 前端·还原.md           # MiMo，UI还原
│   │   ├── 前端·逻辑.md           # Qwen3.7Plus，组件架构
│   │   ├── 前端·动效.md           # MiMoPro，动效方案
│   │   └── 前端·总工.md           # Kimi，前端融合
│   ├── commands/                  # 5 个一键命令
│   │   ├── moa-quick.md           # 简单任务
│   │   ├── moa-medium.md          # 中级 MoA
│   │   ├── moa-flagship.md        # 旗舰 MoA
│   │   ├── moa-frontend.md        # 前端 MoA
│   │   └── moa-describe.md        # 截图转文字
│   ├── skills/                    # 3 个可复用 skill
│   │   ├── code-review-moa/       # MoA 代码评审
│   │   ├── architecture-moa/      # MoA 架构设计
│   │   └── frontend-moa/          # MoA 前端实现
│   └── tests/                     # 验证脚本
│       ├── run-all.ps1
│       ├── T0-static-verify.ps1
│       ├── T1-behavioral-guide.ps1
│       └── T2-moa-smoke-guide.ps1
└── docs/
    └── opencode-moa.md            # 完整部署手册
`

## 快速部署

1. 将 .opencode/ 目录复制到你的项目根目录
2. 将 opencode.json 的内容合并到你项目的 opencode.json（保留已有配置）
3. 重启 OpenCode

**注意**：如果某些模型的 provider 未配置，将对应 agent 的 model 字段改为 model: default，OpenCode 会使用默认模型运行。

## 使用方式

### 自动路由（推荐）

直接描述需求，门童自动判定复杂度并编排：

> 帮我写一个 Markdown 转 HTML 的函数

### 一键命令

| 命令 | 场景 | 流程 |
|------|------|------|
| /moa-quick | 简单任务 | 闪电侠一步到位 |
| /moa-medium | 函数模块、bug 修复 | 3 意见 → 融合 |
| /moa-flagship | 系统架构、大型重构 | 3 旗舰意见 → 融合 → 实现 → 质检 |
| /moa-frontend | UI 还原、CSS | 还原 + 逻辑 + 动效 → 总工 |
| /moa-describe | 截图转文字 | 视觉翻译官 |

### @ 直接调用

输入 @ 选择任意 agent 独立对话。

## 成本分层

| 层级 | 模型 | 月配额 | 角色 |
|------|------|--------|------|
| 工具层 | Flash + MiMo | ~30 万次 | 读文件、搜代码、改代码 |
| 意见层 | Pro / MiniMax / Qwen / MiMo-Pro | ~8.7 万次 | 出方案 |
| 融合层 | Kimi / Qwen-Max / GLM | ~1.8 万次 | 融合、质检 |

## 安全边界

- 全局 catch-all：未声明工具 → ask 弹窗
- agent 权限：工具级 allow/deny 硬限制
- task 白名单：门童只能调用指定 agent
- 降级链：task 失败 → 重试 → 换同类 → 降级内置 agent

## 本地模型

支持 Ollama / LM Studio 等本地模型混用。详见 docs/opencode-moa.md 附录 A。

## 文档版本

v3.4 | OpenCode >= 1.1.1
