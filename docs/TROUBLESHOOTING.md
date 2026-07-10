# OpenCode MoA 故障排查与维护手册

> 文档版本：v1.1 | 关联：CHANGELOG.md v0.0.3

---

## 1. Provider 配置模板

19 个 agent 用 `opencode-go/<model-id>`。必须在配置里注册带凭证的 `opencode-go` provider 才能用 Go 付费模型。

```jsonc
"provider": {
  "opencode-go": {
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

> 两处放 key：系统级 `~/.config/opencode/opencode.json`（全项目生效，仓库外），或项目 `user_config.json`（需 `.gitignore`）。**切勿把含 key 的文件提交或推送。**

---

## 2. 故障对照表

| 症状 | 可能原因 | 排查 / 解决 |
|------|----------|-------------|
| 工具层报 `Upstream request failed` / `OpenCode Go provider error` | `opencode-go` provider 无凭证，Go 付费模型被禁用 | 确认配置有 `provider.opencode-go` 且 `apiKey` 正确；重启 OpenCode |
| 全部 agent 都连不上 | 配置 JSON 非法（双对象拼接、坏 `""` extends）| 用 `Get-Content file \| ConvertFrom-Json` 校验；删 `"": "https://opencode.ai/config.json"` |
| 仅某几个模型失败 | 模型 ID 拼写错或该模型在 `zen/go/v1` 不存在 | 比对上面 9 个模型清单；`/models` 查看可用列表 |
| `model not found` | agent 的 provider 前缀无对应 provider | 确认前缀与配置里 `provider.<前缀>` 一致 |
| 改了配置不生效 | 没重启 OpenCode，或改错文件 | 改的是系统级 `~/.config/opencode/opencode.json` 或项目 `user_config.json`；重启 |
| `@explore`/`@general` 也挂了 | `opencode-go` 不顶内置 `opencode`，不会触发此故障 | 检查是否误覆盖了内置 provider（确认自定义 provider 名不是 `opencode`）|
| CI 报 `Skill files = 3` FAIL | 本地多了未入库的 `opencode-moa` skill | 预期现象，远程 CI 通过；不要为过 CI 而提交该 skill |

---

## 3. 日常维护

### 3.1 新增模型
1. 在配置的 `provider.opencode-go.models` 加一行 `"<model-id>": { "name": "..." }`。
2. 在 agent frontmatter 用 `model: opencode-go/<model-id>`。
3. 先手动 curl 验证该模型在 `zen/go/v1` + key 下可用。

### 3.2 更换 / 续费 Go key
只改两处含 key 的文件：`~/.config/opencode/opencode.json`（及 `.jsonc`）和 `user_config.json` 的 `provider.opencode-go.options.apiKey`。**不要动仓库模板 `opencode.json`。**

### 3.3 新增 agent
1. `.opencode/agents/<名>.md`，frontmatter 含 `description / mode: subagent / model: opencode-go/<model> / temperature / reasoningEffort / permission`。
2. 在 `opencode.json` 的 `permission.task` 加 `"<名>": "allow"`，在 `agent.<名>.permission` 加 task 限制（意见层加 `"*_*": "deny"` 防越权）。
3. 门童路由员 prompt 的路由表里加该 agent。
4. 跑 `T0-static-verify.ps1` 确认计数。

### 3.4 路由 / 降级逻辑改动
门童路由员（`.opencode/agents/门童路由员.md`）改动后务必保留："工具层失败必须停下来 ask 用户，不要跳过 ask 直接路由"。

---

## 4. 密钥安全红线

- `user_config.json`、`~/.config/opencode/*` 含 key → 不入库、不推送。
- 仓库模板 `opencode.json` 永远无 key。
- `.gitignore` 已忽略 `user_config*.json`、`opencode.json1*`、`*.zip`；提交前用 `git status` 确认无含 key 文件被 staged。
