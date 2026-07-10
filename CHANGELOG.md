# Changelog

## 版本规范

- 格式：`v0.X.Y`（语义化版本：主版本.次版本.修订号）
- 修订号（Y）：小修、文档更新、配置调整
- 次版本号（X）：新增功能、模型调整、agent 改动
- 主版本号：架构重构
- 不跳版本号，每次改动只升一级

---

## v0.0.3（2026-07-10）

修复工具层（子代理）连不上 OpenCode Go provider 的根因。

### 根因

子代理 `model: opencode/<model>` 解析走 OpenCode 的 provider 注册表；加载的配置里没有带凭证的 `opencode` provider，只有内置 console `opencode`（无 key → 降级 `public` → 付费 Go 模型被禁用），导致 "OpenCode Go provider error / Upstream request failed"。主会话能工作是因为 `user_config.json` 的 legacy `llm` 块写死了 `base_url+key`，但该凭证不共享给子代理。

### 修复

- 在系统级配置 `~/.config/opencode/opencode.json`（及 `.jsonc`）注册自定义 `provider.opencode`（openai-compatible）→ `https://opencode.ai/zen/go/v1` + Go key + 9 个模型，使 `opencode/<model>` 解析到带凭证的端点（已实测 9 模型全部返回 OK）。
- 修复项目运行时 `user_config.json`：原文件是两个 JSON 对象拼接的非法文件，合并为单个合法对象，加入 `provider.opencode`，移除非法的 `"": "https://opencode.ai/config.json"` extends。
- 修复仓库模板 `opencode.json`：移除指向 JSON Schema 的非法 `"": "https://opencode.ai/config.json"` extends（会导致加载失败），改为 `$schema`。
- README 模型前缀示例 `opencode-go/` → `opencode/`，与部署手册统一。
- 19 个 agent 保持 `opencode/`（与部署手册一致），未回退。
- 与官方命名对齐：agent 模型前缀 `opencode/` → `opencode-go/`，自定义 provider 名 `opencode` → `opencode-go`。官方 Go 文档规定模型 ID 格式为 `opencode-go/<model>`。现独立命名不顶内置 Zen provider，避免冲突。
- `.gitignore`：补 `user_config*.json`（含 key 的副本文件）、`opencode.json1*`（改名副本）、`*.zip`，防误提交泄露。

### 文档

- 新增 `docs/PLAN-fix-provider.md`：完整根因分析与修复方案（后删除，命名已过时）。
- 删除 `docs/PLAN-fix-provider.md`。
- 重写 `docs/TROUBLESHOOTING.md`：删除回退方案节，全篇 `opencode` → `opencode-go`，去 `/connect` 误导。
- 重写 `docs/opencode-moa.md` Provider 节：非交互配置文件鉴权为主，TUI `/connect` 为备选，+ 错误兜底说明。

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
