# 多语言翻译规范（i18n）

OpenCode MoA 面向全球用户，但**包只有一个版本号**，贯穿所有语言。本文定义文档与 README 的多语言布局约定。

## 布局

| 内容 | 中文（源） | 其他语言 |
| --- | --- | --- |
| 部署手册 | `docs/opencode-moa.md` | `docs/<lang>/opencode-moa.<lang>.md` |
| README | `README.md`（根，入口） | `README.<lang>.md`（根） |
| 版本记录 | `CHANGELOG.md`（**单语，不翻译**） | — |

语言代码用 ISO 639-1：`en` / `ja` / `ko` / `fr` / `de` / `zh` ……

## 规则

1. **CHANGELOG 是版本真相源，永远单语**（建议中文或英文其一），不翻译、不移动、文件名固定。
   解析器只认文件顶部第一个 `## vX.Y.Z` 标题；非版本标题（如 `## 路线图`）请放在版本节**之下**，会被自动忽略。
2. **中文 `docs/opencode-moa.md` 是部署手册的源 of truth**。其他语言由其翻译而来，源更新后需同步翻译。
3. **`README.md` 为中文入口**，应在显眼位置列出各语言 README 链接；`README.<lang>.md` 结构保持一致。
4. **不按语言拆仓库 / 拆 tag / 拆 Release**。一次发版，归档内含全部语言文档（`git archive` 打整树）。
5. 翻译 PR 请遵循根 `CONTRIBUTING.md` 的提交与测试规范，并通过 Layer 0 静态检查。

## 当前进度

| 语言 | 部署手册 | README | 状态 |
| --- | --- | --- | --- |
| `zh` | `docs/opencode-moa.md` | `README.md` | ✅ 完整 |
| `en` | `docs/en/opencode-moa.en.md` | `README.en.md` | ✅ 完整 |

## 如何新增一种语言

1. 建目录 `docs/<lang>/`。
2. 复制 `docs/opencode-moa.md` 译为 `docs/<lang>/opencode-moa.<lang>.md`。
3. 建 `README.<lang>.md`（可先由 `README.md` 翻译首段 + 链接）。
4. 在本文「当前进度」表加一行。
5. 在 `README.md` 加该语言链接。
6. 发版：在 `CHANGELOG.md` 顶部加新版本节并 push（见 `CONTRIBUTING.md` 发版规范）——**翻译内容本身不触发发版**，版本号随源改动走。
