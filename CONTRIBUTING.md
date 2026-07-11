# 贡献指南

欢迎提交 PR 和 Issue！

## 快速开始

1. Fork 本仓库
2. 创建分支：`git checkout -b feat/my-feature`
3. 修改文件，运行测试：`pwsh .opencode/tests/T0-static-verify.ps1`
4. 提交 PR

## 提交规范

- **agent 变更**：修改对应的 `.opencode/agents/*.md`
- **命令变更**：修改对应的 `.opencode/commands/*.md`
- **skill 变更**：修改对应的 `.opencode/skills/*/SKILL.md`
- **配置变更**：修改 `opencode.json`，确保 task 白名单同步更新
- **reasoningEffort 变更**：改 agent 推理强度请直接改 `.opencode/agents/*.md` 的 `reasoningEffort` 字段并重启；**不要**在 TUI 手动切「变体 / 推理档」——会覆盖 agent 配置并写入 model 选择缓存（`~/.local/state/opencode/model.json` 等，WSL 走 Linux 路径、Unix 下受 `XDG_STATE_HOME` 影响可重定向），重启仍生效、跨平台一致，会静默顶掉 low→xhigh 矩阵。详见 `docs/opencode-moa.md` 推理矩阵段警告框与「推理强度感觉没变」排错行。

## 测试要求

所有 PR 必须通过 Layer 0 静态检查（全部 PASS / FAIL=0；key 走系统级时 WARN 也算过）：

```bash
pwsh .opencode/tests/T0-static-verify.ps1
```

## Issue 规范

- Bug 报告：请附上 OpenCode 版本、错误日志、复现步骤
- 功能请求：请描述场景和期望行为

## 发版规范（CHANGELOG 驱动，全自动）

发版**唯一入口**是 `CHANGELOG.md`：在文件顶部加一个 `## vX.Y.Z（日期）` 节并 push 到 `master`，GitHub Actions 会自动打 tag、建 Release、上传 `zip`/`tar.gz` 源码归档。你**不需要**手动打 tag 或手动建 Release。

- **一次一发**：一个 PR / 一次提交只新增一个版本节。
- **不要手动打 tag**：手动 `git push` 的 `v*` tag 不会再触发发版（发版逻辑已内聚进 CHANGELOG 推送这一个 job）。
- **发版门禁**：发版前跑 Layer 0 静态检查，失败则中止发版。
- **预演（dry-run）**：仓库 `Actions → Release → Run workflow`，勾 `dry_run`，只打印将发版本号、不真正发版。
- **已发版后补说明**：改同名 CHANGELOG 节**不会**回更 Release body，请直接到 GitHub Releases 页手动编辑。
- **回滚**：`git push -d origin vX.Y.Z` 删 tag，并在 Releases 页删对应 Release（不会自动撤回）。
- **CHANGELOG 铁律**：双语（中文 + 英文，用 `<details>` 折叠分隔）、文件名固定、顶部第一条 `## v` 必须是版本号；非版本标题（如 `## 路线图`）放版本节**之下**，解析器自动忽略。

### 本地发版提醒（防忘，可选）

仓库带 `hooks/pre-commit` 与 `hooks/pre-push`：改了 `CHANGELOG.md` 会在提交时提示、在 push `master` 时交互确认（Enter 发版 / Ctrl+C 取消）。启用（一次性）：

```bash
git config core.hooksPath hooks
```

> 仅本机生效，不影响 CI；非交互环境（如自动化推送）自动放行。

## 多语言规范

本项目面向多语言用户，但**包版本号单一、贯穿所有语言**，不按语言拆 repo / tag / Release。

- **版本真相源**：`CHANGELOG.md` 双语（中文 + 英文，`<details>` 折叠），文件名固定。
- **部署手册**：中文源 `docs/opencode-moa.md`；其他语言放 `docs/<lang>/opencode-moa.<lang>.md`（例：`docs/en/opencode-moa.en.md`）。
- **README**：根 `README.md` 为英文首页；中文 `README.zh.md`；其他语言 `README.<lang>.md`。
- 翻译进度与约定见 [`docs/TRANSLATION.md`](docs/TRANSLATION.md)。

## License

提交即同意 [MIT License](LICENSE)。
