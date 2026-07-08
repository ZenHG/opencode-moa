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

## 测试要求

所有 PR 必须通过 Layer 0 静态检查（41 PASS / 0 FAIL）：

```bash
pwsh .opencode/tests/T0-static-verify.ps1
```

## Issue 规范

- Bug 报告：请附上 OpenCode 版本、错误日志、复现步骤
- 功能请求：请描述场景和期望行为

## License

提交即同意 [MIT License](LICENSE)。
