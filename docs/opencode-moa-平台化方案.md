# opencode-moa 平台化配置方案（多角色评审版）

> 状态: **阶段一 + 阶段二最小版已实施（2026-07-31）** | 版本: v2
> 实施纪要: GG 批准"先执行权限优化清单 → 阶段一直接做 → 阶段二做最小版"。实际落地：阶段一全部完成；阶段二采用最小版（install 脚本内按平台注入删除禁令，未采用 §2.3/§3.1 模板文件方案）
> 关联: docs/opencode-moa-权限优化清单.md（v6，已实施）

---

## 0. 结论摘要

| 问题 | 结论 |
|------|------|
| git clone 时能识别平台吗？ | **不能**。git clone 是静态拉取，无执行时机。但仓库已有更优机制：用户跑 install.ps1 / install.sh 本身就是平台信号 |
| 要 3 套配置（Win/Linux/macOS）吗？ | **不用**。macOS 与 Linux 的 shell 命令集相同，只需 2 套：Windows 套 / Unix 套 |
| 平台化值得做吗？ | **值得做，但要分两步**：第一步（修漂移+权限落地）贡献约 90% 价值且必做；第二步（平台化）收益主要在规则纯净度，token 收益诚实评估约 0.1% 上下文 |
| 平台化怎么落地？ | 2 个平台模板文件（单源）+ install 脚本内自动检测 OS 选模板 + 执行层 frontmatter 平台无关化 + T0 联动校验 |

---

## 1. 用户需求与诚实回答

**需求**：git clone 时智能识别平台，只给相应平台的文件 → 减少通用命令、减少 token。

**诚实回答（三角色共识）**：

1. **git clone 无法识别平台**：clone 是静态拉取，GitHub 侧不执行任何代码。模板仓库不能像二进制软件那样按平台分发 Release 资产（用户要的是源码模板）。
2. **现有机制已经隐式完成平台识别**：README 引导 Windows 用户跑 `install.ps1`（pwsh）、Linux/macOS 用户跑 `install.sh`（bash+jq）。**用户选的脚本就是平台信号**——不需要在 clone 时识别。
3. **真正的平台判定标准**：不是"用户跑哪个脚本"，而是 **opencode 进程运行在哪个 OS**。Windows 上的 opencode，其 bash 工具 spawn 的永远是 PowerShell（本仓库 T0 等 ps1 测试即此环境实证）；Linux/macOS 上 spawn 的是 sh/bash。所以规则集必须匹配 opencode 运行 OS 的 shell 命令集，而非用户终端 shell。
4. **token 收益真实但不显著**（规划角色测算）：bash 规则从 ~17 条（v5 三平台成对）减到 ~10-14 条（单平台），每条约 25 token → 省 75-175 token/turn，约占 128K 上下文 0.1%。**主要收益是规则集纯净度**：Windows 用户不再看到 rm/grep 等无效命令，规则即文档。
5. **维护成本上升是真实代价**：从"1 份规则集"变"2 份模板 + 双脚本引用 + T0 联动"。用**单源模板文件**把漂移面压到最小（详见 §3）。

---

## 2. 平台判定设计

### 2.1 判定原则

**以 opencode 运行 OS 为准，脚本自动检测，不依赖用户选择**：

```
install 脚本检测运行 OS：
├─ Windows（含 Git Bash/MSYS2/Cygwin 环境）→ Windows 套（PS 命令集）
├─ Linux / macOS（Darwin）→ Unix 套（shell 命令集）
```

### 2.2 检测实现

| 脚本 | 检测方式 | 判定 |
|------|----------|------|
| install.ps1 | `$IsWindows`（PW7 内置；Git Bash 里跑 pwsh 时 `$IsWindows` 仍为 true） | Windows 套 |
| install.sh | `uname -s`：`MINGW*/MSYS*/CYGWIN*` → Windows 套；`Linux`/`Darwin` → Unix 套 | 自动归入 |

关键：**Git Bash 用户跑 install.sh 会被归入 Windows 套**——因为他在 Windows 上跑 opencode，bash 工具实际是 PowerShell，`ls`/`grep` 在 PS 里是别名或不存在的命令。这是架构角色的核心修正：平台信号 = opencode 运行 OS，不是脚本语言。

### 2.3 两套规则集（模板文件）

**.opencode/templates/permission.windows.json**（opencode 在 Windows → bash 工具是 PowerShell）：

```json
{
  "*": "ask",
  "git status *": "allow",
  "git diff *": "allow",
  "git log *": "allow",
  "Select-String *": "allow",
  "Get-ChildItem *": "allow",
  "Get-Content *": "allow",
  "cd *": "allow",
  "npm run *": "allow",
  "pwsh .opencode/tests/*": "allow",
  "rm *": "deny",
  "del *": "deny",
  "Remove-Item *": "deny",
  "rd *": "deny",
  "rmdir *": "deny"
}
```

**.opencode/templates/permission.unix.json**（Linux/macOS 通用）：

```json
{
  "*": "ask",
  "git status *": "allow",
  "git diff *": "allow",
  "git log *": "allow",
  "grep *": "allow",
  "rg *": "allow",
  "ls *": "allow",
  "cd *": "allow",
  "npm run *": "allow",
  "pwsh .opencode/tests/*": "allow",
  "rm *": "deny"
}
```

设计说明：
- 删除禁令按平台收敛（Windows 套 5 条、Unix 套 1 条），**每套只含本平台真实命令**——这是"精简专有平台指令"的落点
- Windows 套保留 `rm *` deny：Git Bash 用户（归 Windows 套）仍可能敲 rm，防误删；不加入白名单
- 平台无关部分（`*.env deny`、task 白名单、`*_*`、read/lsp/edit/webfetch）**不进模板**，留在 install 脚本公共段——架构角色明确：这些与 OS 命令无关，必须平台无关

---

## 3. 架构设计

### 3.1 文件组织（单源模板）

```
.opencode/
  templates/
    permission.windows.json   ← Windows 套（单源）
    permission.unix.json      ← Unix 套（单源）
  agents/                     ← 全部平台无关，无平台分支
  ...
install.ps1                   ← 检测 OS → 读对应模板 → 合并生成 opencode.json
install.sh                    ← 同上（jq 读模板）
```

选型理由（工程视角，对比内嵌方案）：
- **单源**：两脚本引用同一模板文件 → "双脚本内嵌配置漂移"（现行 bug：task 18/21、agent 块 8/11）从根上消失，两脚本只剩"引用路径 + 合并逻辑"两处差异
- **T0 可校验**：直接读 JSON 断言比解析脚本内嵌文本可靠得多（§4）
- **手动部署可参考**：README 手动安装节直接引用模板文件内容，不跑脚本的用户照抄

### 3.2 执行层 frontmatter 平台无关化

- 现状：闪电侠/旗舰·实现/前端·还原 frontmatter 是 `bash: allow`（v5 方案待改）
- 平台化后：**frontmatter 不写 bash 段**（删掉 `bash: allow` 一行）→ 全局规则生效
- 机制依据（源码实证）：opencode 权限合并是平铺追加，agent 规则在后、后写胜。frontmatter 无 bash 规则 → 全局 bash 规则（install 按平台生成的）对执行层生效；其他层 agent frontmatter 有 `bash: deny` → 压住全局白名单 → **全局白名单实际只对执行层生效**，行为等价于 v5 方案
- 已审计：门童路由员 frontmatter 有 `edit/bash/read/webfetch deny` + `"*": deny` → 不会意外继承全局白名单 ✓（架构角色提出的漏洞点已排除）

### 3.3 权限矩阵推演（merge 后实际生效）

| Agent 层 | frontmatter bash | 生效规则 | 结果 |
|----------|-----------------|---------|------|
| 执行层（3） | 无 bash 段 | 全局平台套 | 白名单+ask 兜底+删除 deny ✓ |
| 观点层（11） | `bash: deny` | frontmatter deny | 无 bash 权限 ✓ |
| 工具层/融合层 | `bash: deny` | frontmatter deny | 无 bash 权限 ✓ |
| 路由员 | `bash: deny` | frontmatter deny | 无 bash 权限 ✓ |

---

## 4. T0 联动校验（防回归）

T0-static-verify.ps1 新增断言：
1. `templates/permission.{windows,unix}.json` 存在且可解析
2. 每套模板：`"*"` 在首位（last-wins 要求）、deny 集合非空、无 git push/reset/clean 放行
3. install.ps1 / install.sh 引用模板文件路径正确（字符串断言）
4. 执行层 3 agent frontmatter **无 bash 段**（平台无关固化）
5. 现有断言更新：执行层不再匹配 `bash:\s*allow`（旧断言与新方案冲突，需同步改）

---

## 5. 多角色评审意见摘要

### 架构角色
- 平台化边界：仅 bash 规则平台化；`*.env`/task/`*_*`/read/lsp/edit/webfetch 必须平台无关
- 核心修正：平台信号 = opencode 实际 spawn 的 shell（Windows 上永远是 PowerShell），不是用户选的脚本 → Git Bash/MSYS 用户归 Windows 套
- opencode 无条件配置能力（flat merge），install 生成是唯一可行路径 ✓ 方向可行
- 需审计路由员 frontmatter（已审计：有 bash deny，无漏洞）

### 工程角色（本次会话异常，结论由主会话基于 install 脚本全文补充）
- 推荐单源模板文件组织（§3.1 理由）
- 检测：`$IsWindows` / `uname -s` case 三行
- 实施顺序：先修漂移、再平台化，独立验收独立回滚

### 规划角色
- token 收益诚实评估：~0.1% 上下文，**真实但不显著**；主要收益是规则纯净度
- 风险清单：手动部署退化（中/中高）、双集再漂移（高/中，单源模板化解）、Git Bash 交叉（中高/中，平台判定化解）、增量合并覆盖（中/中，文档化）、.bak（低/低）
- 结论：阶段一必做（~90% 价值）；平台化以清晰度为目标可做，否则跳过

---

## 6. 分阶段实施

### 阶段一：漂移修复 + 权限落地（✅ 已实施，2026-07-31）

1. ✅ install 脚本漂移修复：task 白名单 18 → 21（补 融合·保底/残差提取者/置信度评估者——**原缺这 3 个会导致装完调不动**）、agent 块 8 → 10 且格式对齐（`{"*_*": "deny"}`）、bash 补 Windows 删除禁令、补 todowrite、删 instructions、reserved 对齐 15000
2. ✅ 按 v5 清单落地 A1'/A2（执行层权限、Windows 删除禁令）——实施时采纳 GG 提问后的单源版：白名单在全局 bash 段，执行层 frontmatter 仅 edit/lsp/task
3. ✅ B3 删 instructions AGENTS.md 引用、B4 T0 补 opencode.json 校验（90 项）
4. ✅ 验收：`pwsh .opencode/tests/run-all.ps1` Layer 0 全绿

### 阶段二：平台化（✅ 最小版已实施；完整版未做）

GG 决策：做最小版（仅删除禁令按平台分，allow 集保留通用版）。实际落地与完整版的差异：

1. — 模板文件（§2.3/§3.1）未建——最小版在 install 脚本内嵌注入，不引入模板
2. ✅ install.ps1/sh 改：检测 OS → 注入删除禁令（Windows 套 5 条 / Unix 套仅 rm；install.sh 用 uname -s 判 mingw|msys|cygwin + jq --argjson reduce 注入）
3. ✅ 执行层 3 frontmatter 删 bash 段（批1 即完成，与完整版 3.2 殊途同归）
4. ✅ T0 新增平台分支断言（install.ps1 $IsWindows 分支存在、install.sh mingw|msys|cygwin + DENY_EXTRA + reduce 存在）
5. — README 手动安装节未更新（无模板文件可引用；全局白名单即文档）
6. ✅ 验收：平台分支逻辑已用 PowerShell 模拟验证（Windows 套 5 条 deny / Unix 套仅 rm *）

---

## 7. 风险与缓解

| 风险 | 概率/影响 | 缓解 |
|------|----------|------|
| 手动部署（不跑 install）执行层退化全 ask | 中/中高 | README 手动节给模板参考块；ask 不阻塞只弹窗 |
| 双套规则再漂移 | 高/中 | 单源模板文件 + T0 断言 1/2/3 |
| Git Bash 交叉 | 中高/中 | 平台判定归 Windows 套（§2.2） |
| 用户已有 opencode.json 增量合并覆盖 | 中/中 | install 已有 .bak 备份；README 注明 last-wins 合并顺序 |
| 阶段一与阶段二耦合 | — | 分阶段实施，各自验收回滚 |

---

## 8. 验收与回滚

- **验收**：run-all.ps1 全绿；Windows 上 install.ps1 生成 Windows 套、Linux/macOS 上 install.sh 生成 Unix 套；Git Bash 跑 install.sh 也生成 Windows 套；手动部署文档可照抄
- **回滚**：全部文件 git 跟踪，`git checkout -- <file>` 还原；install 脚本改动前跑一次备份 opencode.json（已有 .bak 机制）

---

## 9. 决策记录（GG 2026-07-31）

1. 阶段一（漂移修复 + v5 权限落地）：**✅ 已做**
2. 阶段二（平台化）：**✅ 最小版**（仅删除禁令按平台分，allow 集保留通用版；install 脚本内嵌注入，未建模板文件）
3. 模板文件设计（§2/§3）：**未采用**（最小版无此需求；若未来要完整版，本方案 §2.3/§3.1 可直接复用）
