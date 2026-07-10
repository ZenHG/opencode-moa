# OpenCode MoA 故障排查与维护手册

> 文档版本：v1.0 | 创建：2026-07-10 | 关联：docs/PLAN-fix-provider.md、CHANGELOG.md v0.0.3

本手册用于快速定位 MoA 跑不通的问题，以及日常维护（加模型、换 key、加 agent）。

---

## 0. 一句话架构

- **19 个 agent** 在 `.opencode/agents/`，每个 `model: opencode/<model-id>`。
- 子代理的 `opencode/<model>` 走 **OpenCode provider 注册表**，必须有一个**带凭证**的 `opencode` provider 才能用付费 Go 模型。
- **主会话**（门童路由员等）若用 legacy `llm` 块写死 `base_url+key` 也能通，但那段凭证**不共享给子代理**。
- 模型实际由 `https://opencode.ai/zen/go/v1` + **Go 订阅 key** 提供服务（9 个模型已实测可用）。

---

## 1. 本次修复记录（v0.0.3，2026-07-10）

### 症状
工具层（@工具人 / @闪电侠 等）调用时报 `OpenCode Go provider error` / `Upstream request failed`；@explore / @general 正常。

### 根因
子代理 `opencode/<model>` 解析到内置 console `opencode` provider，该 provider 无 key 时自动降级 `apiKey: "public"`，**付费 Go 模型被禁用** → 子代理连不上。主会话能通只是因为 `user_config.json` 的 legacy `llm` 块带 key 直连，但该凭证不进 provider 注册表。

### 修复动作
| 位置 | 改动 |
|------|------|
| 系统级 `~/.config/opencode/opencode.json`（及 `.jsonc`）| 注册 `provider.opencode`（openai-compatible → `zen/go/v1` + key + 9 模型）|
| 项目运行时 `H:\opencode-moa\user_config.json`（gitignored）| 原文件是两个 JSON 拼接的非法文件 → 合并为合法单对象，加入 `provider.opencode`，删非法 `"": "https://opencode.ai/config.json"` extends |
| 仓库模板 `opencode.json`（无 key）| 删掉指向 JSON Schema 的非法 `"": "https://opencode.ai/config.json"` extends（这是它曾"加载失败"的原因），改 `$schema` |
| `README.md` | 模型前缀示例 `opencode-go/` → `opencode/`（与部署手册统一）|
| `CHANGELOG.md` | 新增 v0.0.3 |

> 关键事实：OpenCode 配置里的 `provider` 条目会**覆盖**同名内置 provider（`config/plugin/provider.ts` 用 `catalog.provider.update` 应用），且内置 `opencode` provider 判定 `hasKey` 时会读到我们配置的 `request.body.apiKey`，不会降级成 `public`。所以自定义 `provider.opencode` 必然生效。

### 验证（重启 OpenCode 后）
1. `@工具人` / `@闪电侠` 正常响应 → 工具层连通。
2. `@explore` / `@general` 仍正常 → 覆盖内置 provider 未破坏内置免费通道。
3. `pwsh .opencode/tests/T0-static-verify.ps1` → 40 PASS。
   - 注：本地若出现 `Skill files = 3` FAIL 属预期（本地多了禁止入库的 `opencode-moa` skill，共 4 个；仓库内 3 个 → 远程 CI 通过），与连通性无关。

---

## 2. provider 配置模板（带凭证，放本地/系统，勿入库）

```jsonc
"provider": {
  "opencode": {
    "npm": "@ai-sdk/openai-compatible",
    "name": "OpenCode Go (MoA)",
    "options": {
      "baseURL": "https://opencode.ai/zen/go/v1",
      "apiKey": "<OPENCODE_GO_API_KEY>"
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
```

> key 真实值只在：`~/.config/opencode/opencode.json`（系统级，仓库外）与 `user_config.json`（gitignored）。**切勿把含 key 的文件提交或推送。**

---

## 3. 故障对照表

| 症状 | 可能原因 | 排查 / 解决 |
|------|----------|-------------|
| 工具层报 `Upstream request failed` / `OpenCode Go provider error` | `opencode` provider 无凭证，付费模型被禁用 | 确认系统级配置有 `provider.opencode` 且 `apiKey` 正确；重启 OpenCode |
| 全部 agent 都连不上 | 配置 JSON 非法（如双对象拼接、坏 `""` extends）| 用 `Get-Content file | ConvertFrom-Json` 校验；删 `"": "https://opencode.ai/config.json"` |
| 仅某几个模型失败 | 模型 ID 拼写错或该模型在 `zen/go/v1` 不存在 | 比对上面 9 个模型清单；`/models` 查看可用列表 |
| `@explore`/`@general` 也挂了 | 自定义 `provider.opencode` 覆盖了内置 console provider，且内置默认模型不在 9 模型清单 | 回退：provider 改名 `opencode-go`，agent/CI/README/文档 `opencode/` 全改回 `opencode-go/`（见第 5 节）|
| `model not found` | agent 写的 provider 前缀无对应 provider | 确认前缀与配置里 `provider.<前缀>` 一致 |
| 改了配置不生效 | 没重启 OpenCode，或改错文件 | 改的是系统级 `~/.config/opencode/opencode.json` 或项目 `user_config.json`；重启 |
| CI 报 `Skill files = 3` FAIL | 本地多了未入库的 `opencode-moa` skill | 预期现象，远程 CI 通过；不要为过 CI 而提交该 skill |

---

## 4. 日常维护

### 4.1 新增一个模型
1. 在系统级 + 项目级配置的 `provider.opencode.models` 加一行 `"<model-id>": { "name": "..." }`。
2. 在 agent 文件 frontmatter 用 `model: opencode/<model-id>`。
3. 先手动 curl 验证该模型在 `zen/go/v1` + key 下可用，再提交。

### 4.2 更换 / 续费 Go key
只改两处含 key 的文件：`~/.config/opencode/opencode.json`（及 `.jsonc`）和 `user_config.json` 的 `provider.opencode.options.apiKey`。**不要动仓库模板 `opencode.json`（无 key）。**

### 4.3 新增一个 agent
1. `.opencode/agents/<名>.md`，frontmatter 含 `description / mode: subagent / model: opencode/<model> / temperature / reasoningEffort / permission`。
2. 在 `opencode.json` 的 `permission.task` 加 `"<名>": "allow"`，在 `agent.<名>.permission` 加 task 限制（意见层加 `"*_*": "deny"` 防越权）。
3. 门童路由员 prompt 的路由表里加该 agent。
4. 跑 `T0-static-verify.ps1` 确认计数。

### 4.4 路由 / 降级逻辑改动
门童路由员（`.opencode/agents/门童路由员.md`）负责探测工具层 → 降级链 ask → 正常路由 → STUCK。改动后务必保留："工具层失败必须停下来 ask 用户，不要跳过 ask 直接路由"。

---

## 5. 回退方案（覆盖内置 provider 导致内置 agent 失效时）

若验证发现 `@explore`/`@general` 因用到 9 模型清单外的默认模型而失效：

1. 系统级 + 项目级配置里把自定义 provider 从 `opencode` 改名为 **`opencode-go`**。
2. 19 个 agent 文件的 `model: opencode/<x>` → `model: opencode-go/<x>`。
3. `T0-static-verify.ps1` 的 `opencode/` 检查改 `opencode-go/`。
4. `README.md` / `docs/opencode-moa.md` 的 `opencode/` 模型前缀改 `opencode-go/`（README 原始即 `opencode-go`，更贴合）。

> `opencode-go` 不与内置 console `opencode` 冲突，因此不会破坏内置 agent。

---

## 6. 密钥安全红线
- `user_config.json`、`~/.config/opencode/*` 含 key → 不入库、不推送。
- 仓库模板 `opencode.json` 永远无 key（provider 由用户自带，符合 README "保留你已有的 provider" 设计）。
- `.gitignore` 已忽略 `user_config.json`、`*.local.json` 等；提交前用 `git status` 确认无含 key 文件被 staged。
