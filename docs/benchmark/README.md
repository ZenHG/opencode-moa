# OpenCode MoA Benchmark

真实任务基准集，用于用事实支撑「更省钱、更稳、更少返工」的价值主张。

> 本目录为骨架。每个任务按 `task_id` 一个 YAML 文件存放于 `cases/`，
> 跑例后人工填充 `success / qa_findings / cost_estimate / comparison_single_agent` 等字段。
> 空骨架本身不产出价值，价值在人工填入真实运行数据。

## 如何新增一个 case

1. 复制模板：`cp template.yaml cases/<task_id>.yaml`
2. 填写 `input`（任务描述）与 `expected_path`（预期路由档位）。
3. 在 OpenCode MoA 中实际跑该任务，按真实结果回填其余字段。
4. 对照「全程旗舰单 agent」估算 `comparison_single_agent`（省了几次旗舰调用、是否返工）。

## 任务编号（建议集）

| 编号 | 场景 | 状态 |
| --- | --- | --- |
| B01 | README FAQ 修正 | ✅ 已填示例 `examples/B01.yaml` |
| B02 | install 脚本数量口径修复 | 待填 |
| B03 | 单文件 bug fix | 待填 |
| B04 | 多文件重构 | 待填 |
| B05 | 测试失败修复 | 待填 |
| B06 | CHANGELOG 更新 | 待填 |
| B07 | 配置迁移 | 待填 |
| B08 | 权限配置检查 | 待填 |
| B09 | QA 发现遗漏 | 待填 |
| B10 | 路由低置信度 ask 用户 | 待填 |
| B11 | Flash 失败后升级 | 待填 |
| B12 | 融合结果冲突解释 | 待填 |
| B13 | 发布前检查 | 待填 |
| B14 | 多语言 README 同步 | 待填 |
| B15 | 安装失败诊断 | 待填 |

## 单任务 YAML 模板

见 `template.yaml`（已含完整字段注释）。`examples/B01.yaml` 为一个填好的 lite 场景示例（随仓库发布，可作范式）。

> 注：`cases/*.yaml` 为本地采集数据（可能含任务内容），默认不进仓库（见根 `.gitignore`）；`examples/` 与 `template.yaml`/`README.md` 为 schema 与范式，随仓库发布。
