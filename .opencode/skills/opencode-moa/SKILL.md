---
name: opencode-moa
description: 一键部署 19-agent Cost-Optimal MoA 架构到 OpenCode
---

## 触发条件

当用户意图包含以下任意语义时激活此 skill：

- **部署/安装/落地/执行** — "帮我部署 MoA"、"执行部署计划"、"落地这个方案"
- **初始化/配置** — "初始化 MoA 环境"、"配置多 agent 架构"
- **升级/更新** — "升级 MoA"、"更新 agent 配置"
- **回滚** — "回滚 MoA"、"恢复默认配置"

## 执行流程

### Step 0：读取部署手册

```
read(docs/opencode-moa.md)
```

此文件包含完整的 Block 0-6 部署指令，**不要跳过任何 Block**。

### Step 1：环境检查（Block 0）

执行部署手册中 Block 0 的环境检查脚本：

- 检测 opencode 运行模式（桌面版/CLI）
- 确认 opencode 版本 >= 1.1.1

### Step 2：创建目录（Block 1）

```bash
mkdir -p .opencode/agents .opencode/commands .opencode/skills .opencode/tests
```

### Step 3：写入 19 个 Agent（Block 2）

按部署手册中 Block 2 的顺序写入 agent 文件：

1. 门童路由员（primary）
2. 工具人 → 工具人-mimo → 闪电侠 → 视觉翻译官
3. 中级·工程 → 中级·创意 → 中级·码农 → 中级·融合
4. 旗舰·架构 → 旗舰·规划 → 旗舰·工程 → 旗舰·融合 → 旗舰·实现 → 旗舰·质检
5. 前端·还原 → 前端·逻辑 → 前端·动效 → 前端·总工

**写入前检查**：目标路径下已有同名文件时，ask 用户是否覆盖。

### Step 4：写入 5 个命令（Block 3）

写入 `.opencode/commands/` 目录：

- moa-quick.md
- moa-medium.md
- moa-flagship.md
- moa-frontend.md
- moa-describe.md

### Step 5：写入 3 个 Skill（Block 4）

写入 `.opencode/skills/` 目录（跳过 opencode-moa 本身）：

- code-review-moa/SKILL.md
- architecture-moa/SKILL.md
- frontend-moa/SKILL.md

### Step 6：合并 opencode.json（Block 5）

**重要**：先读现有 `opencode.json`，合并 permissions.task 配置，不要覆盖用户已有配置。

### Step 7：验证（Block 6）

执行部署手册中的验证脚本：

- Agent 数量：19
- Command 数量：5
- Skill 数量：3（不含 opencode-moa）
- Config 存在

## 降级策略

如果某个 Block 执行失败：

1. 记录失败的 Block 编号和错误信息
2. 继续执行后续 Block（不中断）
3. 全部完成后汇总报告：哪些成功、哪些失败、失败原因

## 部署成功判定

用户执行以下验证：

1. 重启 OpenCode
2. 按 `Ctrl+.` 切换 agent，看到「门童路由员」
3. 输入 `@工具人` 能正常响应
4. 运行验证脚本：`pwsh .opencode/tests/T0-static-verify.ps1`，预期 41 PASS

## 安全约束

- **不修改**：用户已有的 opencode.json 其他字段
- **不覆盖**：同名 agent/command/skill 文件时先 ask
- **不上传**：API key、.env、user_config.json 等私密文件
