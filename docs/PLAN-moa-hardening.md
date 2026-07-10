# OpenCode MoA 部署手册加固方案

> 版本：配套 `docs/opencode-moa.md` v0.0.5 | 日期：2026-07-10
> 背景：测试环境实测发现「部署成功但全 agent 连不上」的空壳 scenario——系统级 `opencode.json` 被删 / 系统目录为空 / provider 缺失或占位符 key，部署仍能写出完整文件却运行时全挂，且旧 T0 只 WARN 不红。

---

## 已确认设计决定

1. **provider（含 key）默认写入项目级 `opencode.json`**：部署自包含，抗系统目录为空/被删；系统级降级为「多项目共享」可选项。
2. **只加固手册**：不改 19 agent / command / skill 实体，不碰测试环境。

---

## 配置加载机制（推演依据）

- OpenCode 合并加载 project `opencode.json`（最高优先）与 system `~/.config/opencode/opencode.json(c)`；任一层的 `provider` 对 project agent 均可见。
- 同层同时有 `.json` 与 `.jsonc` 时 **`.jsonc` 优先**，另一个基本被忽略（或告警）。
- Windows `~` = `%USERPROFILE%`，系统级路径是 `C:\Users\<你>\.config\opencode`（非 `%APPDATA%\opencode`）。
- opencode ≥ 1.3.4 起，自定义 `@ai-sdk/openai-compatible` provider 默认不透传 reasoning 参数，需 `forceReasoning: true`。

---

## 三种极端情况的预期行为（加固后）

| 情况 | 行为 | 处理 |
| --- | --- | --- |
| 系统级 `.json` + `.jsonc` 都在，**有真实 key**（且 key 在被加载的 `.jsonc` 里） | 19 agent 正常解析，可用 | 仅需避双文件错位 |
| 系统级两文件都在，**没 key**（缺 provider / 占位符 / 空） | 空壳：缺 provider→`model not found`；有 provider 无 key→401/403 | 硬门拦截 + T0 红 |
| 系统级目录全空 | 绝对空壳，19 agent 全 `model not found` | 部署强制建 provider（写项目级）→ 自包含可用 |

---

## 改动清单

### 1. Provider 配置节
- 方式 A 默认改为「写入**项目** `opencode.json`」（provider 块 + `apiKey: {file:.opencode/local/opencode-go.key}`），标注"自包含部署"；系统级仅作多项目共享备选。
- 新增**同层双文件警告**：别同时留 `opencode.json` 和 `opencode.jsonc`，`.jsonc` 优先，确保被加载的那个含有效 key。
- 明写 `apiKey` 禁用 `<YOUR_GO_API_KEY>` 占位符 / 空值。

### 2. Block 0 环境检查
- `opencode` 二进制检查**软化**：找不到只 WARN（桌面端子 shell PATH 差异会误报），不阻断文件部署、更不因此跳过 provider。
- 新增 **provider 硬门**：部署后断言 project **或** system 配置含 `opencode-go` provider 且 `apiKey` 真实（非占位符/非空）；不满足则 AI 必须执行 Provider 步重建，不许宣布"部署成功"。

### 3. T0（Block 5.5）
- 增 **provider 注册校验**：`grep "opencode-go"` 且 `apiKey` 非占位符/非空，否则 FAIL。
- skills 校验改为「**3 个指定目录存在**」（`code-review-moa` / `architecture-moa` / `frontend-moa`），不再数总数==3 → 修掉 `opencode-moa` 元 skill 导致的误 FAIL。

### 4. 速查 / 说明段
- 「部署失败原因速查」补三行空壳成因：系统级被删、系统目录为空、双文件错位、占位符 key。
- 新增「系统级 `opencode.json` 被删 / 目录为空如何恢复」。

### 5. CHANGELOG v0.0.5 追加
- P1：`opencode` 未装误报不阻断；provider 升级为「存在 + 真实 key」硬门。
- P2：T0 增 provider+真实 key 校验、skills 误判修复、双文件警告、provider 默认项目级。

---

## 不改动

- 19 agent / 5 command / 3(+元) skill 实体文件；测试环境；README（前轮已同步版本号）。
