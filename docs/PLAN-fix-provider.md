# 方案：修复 OpenCode MoA 工具层连通性（实现 opencode-moa.md 全量功能）

> 文档版本：v0.0.3-plan | 状态：执行中

## 根因（一句话）
子代理写 `opencode/<model>`，解析走 OpenCode 的 **provider 注册表**；但加载的配置里**没有带凭证的 `opencode` provider**——只有内置 console `opencode`（无 key → 降级 `public` → 付费 Go 模型被禁用 → "OpenCode Go provider error / Upstream request failed"）。能工作的主会话靠的是 `user_config.json` 里写死 `base_url+key` 的 legacy `llm` 块，那段凭证**不会**共享给子代理。

## 关键事实（排查确认）
- 系统级配置 `~/.config/opencode/opencode.json`（及 `.jsonc`）里**没有 `opencode` provider、没有 Go key、没有 `llm` 块**，只有 `mcp` + 两个无关 provider（`1`、`openmodel`）。
- 内置 `opencode`(console) provider：源码 `opencode_provider.ts:165-177` 显示无 key 时 `apiKey="public"`，仅启用免费模型 → 付费 Go 模型被禁。
- `@explore`/`@general` 一直成功 = 用内置 console 的**免费模型**（`public` 即可）；我们的子代理用**付费模型** → 失败。
- `zen/go/v1` + Go key 对全部 9 个模型已实测返回 OK（deepseek-v4-flash / mimo-v2.5 / mimo-v2.5-pro / minimax-m3 / glm-5.2 / qwen3.7-max / qwen3.7-plus / kimi-k2.7-code / deepseek-v4-pro）。
- 运行时配置定位：新建无 json 项目 → 加载系统级 `~/.config/opencode/opencode.json`（GG 的全局配置）。项目里 `opencode.json` 被改名 `.json11`、真正项目运行时是 gitignored 的 `user_config.json`（含 `llm` 块+key）。
- 仓库 git 跟踪 `opencode.json`（无 key 模板）；`user_config.json` 被 `.gitignore` 排除（含 key，正确）。
- 部署手册 opencode-moa.md 通篇用 `opencode/`（附录A / Q&A / 各 agent）；README 仍写 `opencode-go`（不一致，需对齐）。

## 修复核心
在**真正被加载的配置**里注册带凭证的自定义 `provider.opencode`（openai-compatible）→ `https://opencode.ai/zen/go/v1` + Go key + 9 模型。

```jsonc
"provider": {
  "opencode": {
    "npm": "@ai-sdk/openai-compatible",
    "name": "OpenCode Go (MoA)",
    "options": {
      "baseURL": "https://opencode.ai/zen/go/v1",
      "apiKey": "sk-iZ5Mm0PtGRflrRPmmOKgcupwevJiE9xXJhIHTcmdLfOWBixXxPXOj7hIHEmdxFbP"
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

## 落地步骤
1. 系统级配置 `~/.config/opencode/opencode.json`（及 `.jsonc`）：加入 `provider.opencode` 块。覆盖所有项目（含新建无 json 项目）。仓库外 → key 不入库。
2. 项目运行时 `H:\opencode-moa\user_config.json`（gitignored）：两个 JSON 对象拼接的非法文件 → 合并为单个合法对象；加入 `provider.opencode`；删除非法 `"": "https://opencode.ai/config.json"` extends；legacy `llm` 块统一为顶层 `model: opencode/deepseek-v4-flash`。
3. 提交模板 `opencode.json`（无 key）：删除 `"": "https://opencode.ai/config.json"` 非法 extends（指向 JSON Schema 不是配置，会导致加载失败）；与部署手册 Block 5 对齐（只含 `$schema`+permissions）。保持无 key。
4. 命名保持 `opencode/`（与部署手册 + GG 方向一致）；19 个 agent 不动。
5. README 第 43/158 行 `opencode-go` → `opencode`（与部署手册统一）。
6. CI `T0-static-verify.ps1` 已是 `opencode/` 检查 → 保持不变。

## 验证（重启 OpenCode 后）
- `@工具人` / `@闪电侠` 正常响应（工具层连通）。
- `@explore` / `@general` 仍正常（确认覆盖内置 `opencode` 未破坏内置免费通道）。
- `pwsh .opencode/tests/T0-static-verify.ps1` → 40 PASS。
- 端到端：门童路由员跑"中"任务 → 工具人+视觉翻译官 → 中级三剑客并行 → 中级融合。

## 风险与回退
- **覆盖内置 `opencode` 风险**：自定义 `provider.opencode` 覆盖内置 console provider。若验证发现 `@explore`/`@general` 因用到清单外默认模型而失效 → 回退：provider 改名 **`opencode-go`**，19 agent + CI + README + 文档 `opencode/` 全改回 `opencode-go/`（也对齐 README 原始命名）。
- **/connect 原生方案（备选）**：OpenCode 内 `/connect` 用 Go 订阅鉴权内置 `opencode` provider，则无需自定义 provider（最贴部署手册）。依赖订阅状态、无法会话内验证，故以自定义 provider 为确定性主方案。

## 密钥安全
- `user_config.json` 已被 `.gitignore` 排除；系统配置在仓库外 → key 不会泄露。
- 提交模板 `opencode.json` 保持无 key。
- 禁止把含 key 的文件加入 git / 推送。
