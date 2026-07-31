# opencode-moa 权限优化清单（审核版）

> 状态: **已实施（2026-07-31，GG 审核通过并批准执行）** | 验收: `pwsh .opencode/tests/run-all.ps1` Layer 0 全绿（90+ 项）
> 版本: v6（实施版 — 采纳 GG 提问"frontmatter 未标注是否默认 allow"后的精简：白名单单源化到全局 bash 段，执行层 frontmatter 仅保留 edit/lsp/task）

---

## A1. 执行层 agent 现在能执行任何命令，没人拦

**涉及**：闪电侠、旗舰·实现、前端·还原（3 个真正动手写代码的 agent）

**修复前可能存在的问题**：
- 这 3 个 agent 执行命令时完全放行，**没有任何确认环节**
- 假如它在改代码时误发了一条删除命令（`rm -rf` 或 Windows 的删除），**不会问你，直接执行**——你的文件/工作区可能瞬间没掉，你事后才发现
- 它跑一个你从没见过的命令（比如偷偷往别处传数据、改系统设置），**也不会问你**
- 你配的"禁止删除"规则（在 opencode.json 里）对这 3 个 agent **是失效的**——写了等于没写

**修复后解决的问题**：
- 日常命令（看文件列表、看 git 状态、跑测试、搜代码）依然直接放行，干活不卡壳
- 删除类命令（`rm`/`del`）**直接禁止**，agent 想删也得换个方式（或用正规的改文件工具），删错的风险没了
- 其他没见过的命令**弹窗问你**：同意才执行，不同意就拒绝——你始终有最终决定权

**改法（已实施）**：3 个 agent 文件删除 bash 段，只留 `edit/lsp/task` 三条；白名单单源到 opencode.json 全局 bash 段（15 条 allow + 5 条 deny + `*` ask 兜底）。机制：agent frontmatter 无 bash 规则时全局 bash 规则直接生效（"agent rules take precedence" 仅在 agent 有该工具规则时成立），且其他层 agent 都有 `bash: deny` 压住全局 → 全局白名单实际只对执行层生效，行为与 v5 附录写法完全等价，但每文件从 23 行降到 4 行

---

## A2. Windows 上的删除命令漏网

**涉及**：全局配置（所有场景）

**修复前可能存在的问题**：
- 你配的删除禁令只覆盖了 `rm`（Mac/Linux 命令）和 `del`
- 但 Windows 上真实的删除命令是 `Remove-Item`、`rd`、`rmdir`——**都没被禁**
- Windows 用户（包括你）的 agent 跑这些命令删文件，不会被拦，只是弹个窗问一下，点了就放行

**修复后解决的问题**：
- Windows 的删除命令和 Mac/Linux 的 `rm` 一样被直接禁止
- 不管在哪个系统上跑，删除操作都有一致的保护

**改法**：全局配置里补 3 条删除禁令（Remove-Item/rd/rmdir）

---

## A3. 用 cat 读文件不受限制（可选，倾向不改）

**修复前可能存在的问题**：
- `cat` 命令被放行，理论上 agent 可以用 `cat 你的.env` 把你的密钥/密码读进对话内容（会发给模型）

**为什么倾向不改**：
- 读文件本来有专门的"禁止读 .env"规则管着，agent 正经读文件会走那条规则
- 能跑 `cat` 的只有执行层 3 个 agent，它们本来就是被信任写代码的，再防意义不大
- 改了反而让日常读文件多弹窗

**结论**：这项建议**不做**，除非你特别在意密钥泄露这点风险

---

## B1. 配置文件里有 11 份重复内容（中低优先）

**状态：已实施。** 10 份 agent 块精简为 `{"*_*": "deny"}`（删掉与全局/frontmatter 同值的 `*: ask` 与 task 白名单）。安全性论证：无论 opencode 的 agent 块与 frontmatter 谁在后加载，被删内容与全局或 frontmatter 完全同值，行为不变；`*_*` deny 是 agent 块唯一独有内容，保留。T0 已固化断言（agent 块=10、`*_*`=10、task 名单四源一致）。

**修复前可能存在的问题**：
- opencode.json 里 11 个"只读规划"类 agent 各有一段几乎一样的配置
- 其中一行"所有工具默认弹窗问"其实和每个 agent 自己文件里的声明**重复**了
- 以后要改权限，得改 12 个地方（1 个全局 + 11 个 agent），漏一个就出现"行为不一致"的怪问题

**修复后解决的问题**：
- 每份配置只留真正有用的部分（能调用哪些子 agent + 封掉 MCP 工具），删掉重复行
- 改动量减半，不容易改漏
- ⚠️ 前提：先验证删除后行为完全不变（有一项顺序问题需要确认，见附录），验证通过才删

---

## B2. 21 个 agent 名字在 3 个地方各写一遍

**修复前可能存在的问题**：
- 以后新增一个 agent，要在 3 个地方登记名字（全局白名单、路由员白名单、配置文件）
- 如果只改了 2 处，会出现"agent 建好了但调不动/路由不到"的怪问题，**而且没有任何检查能发现**

**修复后解决的问题**：
- 自动化测试自动对比 3 处名单是否一致
- 新增 agent 忘改某处时，跑测试立刻报红提醒，问题在发生前就暴露

---

## B3. 配置里引用了一个不存在的文件

**修复前可能存在的问题**：
- opencode.json 里写着"加载 AGENTS.md 这个文件"
- 但仓库里**根本没有这个文件**——这条配置一直在空转
- 属于无效配置，还容易误导人以为有这个文件

**修复后解决的问题**：
- 删掉这行无效配置（opencode 本来就会自动找 AGENTS.md，不写也生效）

---

## B4. 现有的自动化检查在睡觉

**修复前可能存在的问题**：
- 仓库有个自动化检查（T0），但它只检查 agent 文件，**完全不看 opencode.json**
- 所以 A1、A2 这类问题，现在跑测试全绿也发现不了——检查形同虚设
- 更糟：将来有人把权限改回宽松配置，测试照样全绿，问题悄悄回来

**修复后解决的问题**：
- T0 增加对 opencode.json 和执行层权限新写法的检查
- A1、A2 的修复**被测试固化**：以后谁改回旧配置，测试立刻报红
- 测试还顺便检查 B2 的名单一致性问题

---

## C1. 写代码时频繁弹窗（可选）

**修复前可能存在的问题**：
- 执行层 agent 写代码时会频繁用代码提示/类型检查功能（lsp）
- 每次用都要弹窗问一次，很烦，打断编码节奏

**修复后解决的问题**：
- lsp 直接放行，写代码不被打断（其他工具照旧弹窗）

---

## C2. 一条重要规则没有文档，容易被人误删

**修复前可能存在的问题**：
- 配置里有一条规则 `*_*`（作用：封掉所有"外部工具"——比如你以后装了某个 MCP 服务，它自动被禁用，防它乱动）
- 这条规则**没有任何说明文档**，看起来像乱码
- 更危险的是它"生效顺序"很敏感：哪天有人调整了配置顺序，这条规则会**悄悄失效**，没人知道

**修复后解决的问题**：
- README 里写明这条规则的作用、为什么不能删、顺序为什么不能乱
- 后人不会误删误改，保护一直有效

---

## 附录：技术细节（给需要核对的人）

### A1 的实施写法（白名单单源版 — 执行层 frontmatter 仅 3 行）

3 个文件（闪电侠/旗舰·实现/前端·还原）frontmatter 最终形态：

```yaml
permission:
  edit: allow
  lsp: allow
  task: deny
```

白名单 + 删除禁令全部在 opencode.json 全局 bash 段（单源；对执行层生效，其他层被各自 frontmatter 的 bash: deny 压住）：

```json
"bash": {
  "*": "ask",
  "git status *": "allow",
  "git diff *": "allow",
  "git log *": "allow",
  "grep *": "allow",
  "rg *": "allow",
  "Select-String *": "allow",
  "ls *": "allow",
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

**跨平台覆盖对照**（此表是白名单的审核依据）：

| 用途 | Linux/macOS | Windows | 三平台通用 |
|------|-------------|---------|-----------|
| 搜代码 | grep / rg | Select-String / rg | rg |
| 看文件 | ls | Get-ChildItem | — |
| 读文件 | （走 read 工具，与 Windows 同） | Get-Content（与 cat 同风险级） | — |
| 切目录 | cd | cd | cd |
| 跑测试 | npm run / pwsh | npm run / pwsh | npm run / pwsh |
| git 只读 | git status/diff/log | git status/diff/log | git status/diff/log |
| 删除（禁） | rm | del / Remove-Item / rd / rmdir | — |

### A2 的具体写法（opencode.json 全局 bash 规则里加 3 条）

```json
"rm *": "deny",
"del *": "deny",
"Remove-Item *": "deny",
"rd *": "deny",
"rmdir *": "deny"
```

### B1 的前置验证（已完成，结论：可删）

opencode 的规则合并是"追加 + 后写的赢"（源码实证：`merge` 平铺 + `evaluate` findLast）。本仓库被删内容（`*: ask`、task 白名单对象）与全局 permission / frontmatter 完全同值——无论 agent 块与 frontmatter 谁在后加载，行为都不变；`*_*` deny 为 agent 块唯一独有内容，保留。T0 断言已固化（`"*_*"` 计数=10、agent 块=10）。

### 机制依据（源码实证，非猜测）

- `packages/opencode/src/permission/index.ts`：`fromConfig`/`merge`/`evaluate` 三个函数（配置转规则、规则平铺追加、后匹配者胜）
- `packages/core/src/util/wildcard.ts`：命令匹配规则（`cmd *` 结尾自动兼容裸命令；大小写敏感 → Windows 命令按常见写法书写）
- 官方文档：agent 权限与全局合并，"agent rules take precedence"

---

## 验收与回滚

- **验收（已通过）**：`pwsh .opencode/tests/run-all.ps1` Layer 0 全绿；T0 新增 opencode.json 断言（白名单 15 条逐一、deny 5 条逐一、无 instructions、agent 块=10、`*_*`=10、task 名单四源一致、平台分支）；改动的文件：opencode.json、3 个 agent、T0、install.ps1、install.sh、README.md
- **回滚**：全部文件 git 已跟踪，出问题 `git checkout -- 文件名` 逐个还原即可

## 实施记录（2026-07-31）

1. **批1**：A1'（白名单单源全局）+ A2 + B1 + B3 + C1 + C2 + B2/B4（T0 90 项全绿）
2. **批2**：install 双脚本漂移修复（task 21 / agent 10 / bash 补齐 / todowrite / reserved 15000 / 删 instructions）
3. **批3**：平台化最小版（install 按平台生成 deny 集：Windows 5 条 / Unix 仅 rm；T0 平台分支断言固化）
4. **验收**：run-all Layer 0 PASS（T1/T2 为引导式手动验证，设计如此）
