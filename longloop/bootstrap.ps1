#requires -Version 7
# bootstrap.ps1 — 长程自完善·零先验自举引导器（草案 v3.1 落地）
# 用法: pwsh longloop/bootstrap.ps1 -Dir <项目根> [-NonInteractive] [-AutoAccept]
# 流程: 内容探测 → 健康快照基线 → 候选改进清单（带证据）→ Onboarding 问询 → 交互预审 → 落盘 state.json + 探针骨架
# 产出: <Dir>/.moa/longloop/state.json（含 onboarding/baseline 字段 + 预审 roadmap）+ 足迹.md + probes/
# 兼容: 落盘后直接 `pwsh longloop/long-loop.ps1 -Dir <Dir>` 接续，无需 -Goal（state.json 已含 goal）

param(
    [string]$Dir = (Get-Location).Path,
    [switch]$NonInteractive,   # 跳过交互问询与预审，全用默认值（全接受候选）
    [switch]$AutoAccept,       # 预审自动全接受（等价 -NonInteractive，仅简化预审）
    [switch]$ScanOnly          # 只重跑健康快照并对比基线（长程循环每轮判定用），不落盘 roadmap
)

$ErrorActionPreference = "Stop"

# ── 1. 内容探测（语言无关统计 marker，确定性检查器）──
function Invoke-HealthScan {
    param([string]$Root)
    $files = Get-ChildItem $Root -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '\\.git\\|\\node_modules\\|\\.moa\\|\\.opencode\\|\\dist\\|\\build\\|\\__pycache__\\|\\bin\\|\\obj\\' }
    $extMap = @{
        '.ps1' = 'powershell'; '.psm1' = 'powershell'; '.psd1' = 'powershell'
        '.py' = 'python'; '.js' = 'javascript'; '.mjs' = 'javascript'; '.cjs' = 'javascript'
        '.ts' = 'typescript'; '.tsx' = 'typescript'; '.jsx' = 'javascript'
        '.go' = 'go'; '.rs' = 'rust'; '.java' = 'java'; '.c' = 'c'; '.h' = 'c'
        '.cpp' = 'cpp'; '.hpp' = 'cpp'; '.cs' = 'csharp'; '.rb' = 'ruby'
        '.sh' = 'shell'; '.bash' = 'shell'; '.json' = 'json'; '.yaml' = 'yaml'; '.yml' = 'yaml'
        '.md' = 'markdown'; '.txt' = 'text'; '.html' = 'html'; '.css' = 'css'; '.sql' = 'sql'
    }
    $markers = [ordered]@{
        total_files     = $files.Count
        total_lines     = 0
        languages       = [ordered]@{}
        long_files      = @()   # 超长文件（>800 行）
        long_lines      = @()   # 超长行（>200 字符）
        todo_density    = 0     # TODO/FIXME/HACK 每千行
        empty_catch     = @()   # 空 catch/except 吞错
        console_logs    = @()   # console.log/print 泄漏
        hardcoded_secret= @()   # 硬编码 secret 模式
        swallow_fail    = @()   # || true / ; true 吞失败
        dup_blocks      = 0     # 重复代码块近似（相同行出现 ≥3 次）
        max_nesting     = 0     # 最深大括号嵌套
    }
    $dupLineCount = @{}
    $lineCounts = @{}
    foreach ($f in $files) {
        $ext = $f.Extension.ToLowerInvariant()
        $lang = if ($extMap.ContainsKey($ext)) { $extMap[$ext] } else { 'other' }
        if ($markers.languages.Contains($lang)) { $markers.languages[$lang]++ } else { $markers.languages[$lang] = 1 }
        $lines = try { Get-Content $f.FullName -Encoding utf8 -ErrorAction Stop } catch { continue }
        $rel = if ($f.FullName.StartsWith($Root)) { $f.FullName.Substring($Root.Length).TrimStart('\','/') } else { [IO.Path]::GetFileName($f.FullName) }
        $markers.total_lines += $lines.Count
        $lineCounts[$f.FullName] = $lines.Count
        if ($lines.Count -gt 800) { $markers.long_files += [pscustomobject]@{ file = $rel; lines = $lines.Count } }
        $depth = 0; $maxDepth = 0
        foreach ($ln in $lines) {
            if ($ln.Length -gt 200) { $markers.long_lines += [pscustomobject]@{ file = $rel; line = $ln.Substring(0, 80) } }
            if ($ln -match 'TODO|FIXME|HACK') { $markers.todo_density++ }
            if ($ln -match '^\s*(catch|except)[^\{]*\{\s*$|^\s*(catch|except)[^\{]*\{?\s*$' -and $ln -notmatch 'throw|Write-|log|Log') {
                # 空 catch 吞错（近似：catch 行内无处理动作）
                $markers.empty_catch += [pscustomobject]@{ file = $rel; line = $ln.Trim().Substring(0, [Math]::Min(60, $ln.Trim().Length)) }
            }
            if ($ln -match 'console\.(log|debug|warn|error)|print\(') {
                $markers.console_logs += [pscustomobject]@{ file = $rel; line = $ln.Trim().Substring(0, [Math]::Min(80, $ln.Trim().Length)) }
            }
            if ($ln -match '(password|passwd|secret|api[_-]?key|token)\s*[:=]\s*[''"][^''"]{6,}[''"]') {
                $markers.hardcoded_secret += [pscustomobject]@{ file = $rel; line = $ln.Trim().Substring(0, [Math]::Min(80, $ln.Trim().Length)) }
            }
            if ($ln -match '\|\|\s*true\s*$|;\s*true\s*$|&&\s*true\s*$') {
                $markers.swallow_fail += [pscustomobject]@{ file = $rel; line = $ln.Trim().Substring(0, [Math]::Min(60, $ln.Trim().Length)) }
            }
            if ($ln -match '\{') { $depth += ([regex]::Matches($ln, '\{')).Count }
            if ($ln -match '\}') { $depth -= ([regex]::Matches($ln, '\}')).Count }
            if ($depth -lt 0) { $depth = 0 }
            if ($depth -gt $maxDepth) { $maxDepth = $depth }
            foreach ($w in $ln -split '\s+') {
                $t = $w.Trim()
                if ($t.Length -gt 30) { $key = $t.Substring(0, 30) } else { $key = $t }
                if ($dupLineCount.ContainsKey($key)) { $dupLineCount[$key]++ } else { $dupLineCount[$key] = 1 }
            }
        }
        $markers.max_nesting = [Math]::Max($markers.max_nesting, $maxDepth)
    }
    $markers.todo_density = [Math]::Round(($markers.todo_density * 1000.0) / [Math]::Max(1, $markers.total_lines), 1)
    $markers.dup_blocks = @($dupLineCount.GetEnumerator() | Where-Object { $_.Value -ge 3 }).Count
    $markers.long_files = @($markers.long_files | Sort-Object lines -Descending | Select-Object -First 10)
    $markers.empty_catch = @($markers.empty_catch | Select-Object -First 10)
    $markers.console_logs = @($markers.console_logs | Select-Object -First 10)
    $markers.hardcoded_secret = @($markers.hardcoded_secret | Select-Object -First 10)
    $markers.swallow_fail = @($markers.swallow_fail | Select-Object -First 10)
    return [pscustomobject]$markers
}

# ── 2. 健康快照加权评分（默认均权）──
function Get-HealthScore {
    param($Scan)
    $sub = [ordered]@{}
    $sub.file_size   = if ($Scan.long_files.Count -gt 5) { 0 } elseif ($Scan.long_files.Count -gt 0) { 5 } else { 10 }
    $sub.line_length = if ($Scan.long_lines.Count -gt 20) { 0 } elseif ($Scan.long_lines.Count -gt 5) { 5 } else { 10 }
    $sub.todo        = if ($Scan.todo_density -gt 5) { 0 } elseif ($Scan.todo_density -gt 1) { 5 } else { 10 }
    $sub.error_handling = if ($Scan.empty_catch.Count -gt 5) { 0 } elseif ($Scan.empty_catch.Count -gt 0) { 5 } else { 10 }
    $sub.log_leak    = if ($Scan.console_logs.Count -gt 10) { 0 } elseif ($Scan.console_logs.Count -gt 2) { 5 } else { 10 }
    $sub.secret      = if ($Scan.hardcoded_secret.Count -gt 0) { 0 } else { 10 }
    $sub.dup         = if ($Scan.dup_blocks -gt 20) { 0 } elseif ($Scan.dup_blocks -gt 5) { 5 } else { 10 }
    $sub.nesting     = if ($Scan.max_nesting -gt 8) { 0 } elseif ($Scan.max_nesting -gt 4) { 5 } else { 10 }
    $total = 0.0; foreach ($v in $sub.Values) { $total += [double]$v }
    $score = [Math]::Round($total / $sub.Count, 1)
    return [pscustomobject]@{ score = $score; sub_scores = [pscustomobject]$sub }
}

# ── 3. 候选改进清单（规则映射，带证据）──
function Get-Candidates {
    param($Scan)
    $c = @()
    if ($Scan.hardcoded_secret.Count -gt 0) {
        $c += [pscustomobject]@{ id = "c1"; title = "硬编码凭据清理（$($Scan.hardcoded_secret.Count) 处）"; evidence = ($Scan.hardcoded_secret | ForEach-Object { "$($_.file):$($_.line)" }) -join '; '; risk = "L1"; desc = "把密钥移入环境变量/配置注入，消除硬编码 secret 模式" }
    }
    if ($Scan.empty_catch.Count -gt 0) {
        $c += [pscustomobject]@{ id = "c2"; title = "空 catch 吞错修复（$($Scan.empty_catch.Count) 处）"; evidence = ($Scan.empty_catch | ForEach-Object { "$($_.file):$($_.line)" }) -join '; '; risk = "L1"; desc = "空 catch/except 改为记录错误或抛出，避免静默失败" }
    }
    if ($Scan.long_files.Count -gt 0) {
        $c += [pscustomobject]@{ id = "c3"; title = "超大文件拆分（$($Scan.long_files.Count) 个 >800 行）"; evidence = ($Scan.long_files | ForEach-Object { "$($_.file) ($($_.lines)L)" }) -join '; '; risk = "L2"; desc = "按职责拆分超大文件为模块（可回滚：每拆一步跑语法探针）" }
    }
    if ($Scan.console_logs.Count -gt 2) {
        $c += [pscustomobject]@{ id = "c4"; title = "调试输出清理（$($Scan.console_logs.Count) 处）"; evidence = ($Scan.console_logs | ForEach-Object { "$($_.file):$($_.line)" }) -join '; '; risk = "L1"; desc = "console.log/print 改为结构化日志或移除" }
    }
    if ($Scan.todo_density -gt 1) {
        $c += [pscustomobject]@{ id = "c5"; title = "TODO 债务清理（密度 $($Scan.todo_density)/千行）"; evidence = "全库 TODO/FIXME/HACK 标记"; risk = "L2"; desc = "逐项评估 TODO：完成/转 issue/删除" }
    }
    if ($Scan.swallow_fail.Count -gt 0) {
        $c += [pscustomobject]@{ id = "c6"; title = "吞失败模式修复（$($Scan.swallow_fail.Count) 处 `|| true`）"; evidence = ($Scan.swallow_fail | ForEach-Object { "$($_.file):$($_.line)" }) -join '; '; risk = "L1"; desc = "`|| true`/`; true` 吞掉失败退出码，改为显式处理" }
    }
    if ($Scan.dup_blocks -gt 5) {
        $c += [pscustomobject]@{ id = "c7"; title = "重复代码抽取（$($Scan.dup_blocks) 个近似重复块）"; evidence = "重复行统计"; risk = "L2"; desc = "抽取公共函数/常量，减少重复" }
    }
    if ($Scan.max_nesting -gt 4) {
        $c += [pscustomobject]@{ id = "c8"; title = "深层嵌套简化（最深 $($Scan.max_nesting) 层）"; evidence = "最大大括号嵌套深度"; risk = "L2"; desc = "拆函数/早退，降低嵌套复杂度" }
    }
    if ($c.Count -eq 0) {
        $c += [pscustomobject]@{ id = "c0"; title = "建立验收探针（语法+冒烟）"; evidence = "零问题项目仍需可执行验收层"; risk = "L1"; desc = "为项目构建最小探针集（草案第 2 层），作为后续完善基线" }
    }
    return @($c)
}

# ── 4. Onboarding 一次性问询 ──
function Invoke-Onboarding {
    param([switch]$Skip)
    if ($Skip) {
        return [pscustomobject]@{
            run_command  = ""
            goal         = ""
            preferences  = @{}
            auth_boundary= "L1"
            budget_rounds= 100
        }
    }
    Write-Host "`n=== Onboarding 一次性问询（循环期将零问询）===" -ForegroundColor Cyan
    $run = Read-Host "① 项目怎么运行？（冒烟探针唯一信息来源，答不了直接回车=声明未知）"
    $goal = Read-Host "② 目标（可选，回车=自动体检+趋势优化）"
    $auth = Read-Host "③ 授权边界 [L1=只读+小步改进(默认) / L2=可回滚改动 / L3=全权]"
    if (-not $auth) { $auth = "L1" }
    $budget = Read-Host "④ 资源预算（轮数，默认 100）"
    if (-not $budget) { $budget = "100" }
    return [pscustomobject]@{
        run_command   = $run.Trim()
        goal          = $goal.Trim()
        preferences   = @{ }
        auth_boundary = $auth
        budget_rounds = [int]$budget
    }
}

# ── 5. 交互预审（任务来源=用户定义）──
function Invoke-PreReview {
    param($Candidates, [switch]$Auto)
    $accepted = @()
    if ($Auto) {
        Write-Host "自动全接受 $($Candidates.Count) 条候选。" -ForegroundColor Yellow
        return @($Candidates)
    }
    Write-Host "`n=== 候选改进清单预审（勾选接受后落盘为 roadmap）===" -ForegroundColor Cyan
    foreach ($c in $Candidates) {
        Write-Host "`n[$($c.id)] $($c.title)" -ForegroundColor White
        Write-Host "  证据: $($c.evidence)" -ForegroundColor DarkGray
        Write-Host "  风险: $($c.risk) | $($c.desc)" -ForegroundColor DarkGray
        $ans = Read-Host "  接受? [y/N]"
        if ($ans -match '^[yY]') { $accepted += $c }
    }
    return @($accepted)
}

# ── 主流程 ──
$Dir = (Resolve-Path $Dir).Path
$stateDir = Join-Path $Dir ".moa/longloop"
$stateFile = Join-Path $stateDir "state.json"
$baselineFile = Join-Path $stateDir "health-baseline.json"

# ── ScanOnly：长程循环每轮重跑快照 + 基线对比 + 回退判定（不落盘 roadmap）──
if ($ScanOnly) {
    $scan = Invoke-HealthScan $Dir
    $health = Get-HealthScore $scan
    $out = [ordered]@{ score = $health.score; sub_scores = $health.sub_scores; scan = $scan }
    if (Test-Path $baselineFile) {
        $base = Get-Content $baselineFile -Raw | ConvertFrom-Json
        $hist = @($base.history)
        if ($hist.Count -eq 0) { $hist = @($base.score) }
        $prev = $hist[-1]
        $delta = [Math]::Round($health.score - [double]$prev, 1)
        $hist += $health.score
        if ($hist.Count -gt 30) { $hist = @($hist | Select-Object -Last 30) }
        # 连续 2 轮下降才算回退（草案 v3.1 快照聚合规则：容忍单轮波动）
        $dropStreak = 0
        for ($i = $hist.Count - 1; $i -gt 0 -and $dropStreak -lt 2; $i--) {
            if ([double]$hist[$i] -lt [double]$hist[$i - 1]) { $dropStreak++ } else { break }
        }
        $regressed = $dropStreak -ge 2
        $base | Add-Member -NotePropertyName history -NotePropertyValue $hist -Force
        $base | Add-Member -NotePropertyName scan -NotePropertyValue $scan -Force
        $base | ConvertTo-Json -Depth 8 | Set-Content $baselineFile -Encoding utf8
        $out.delta = $delta
        $out.baseline = [double]$base.score
        $out.regressed = $regressed
        $out.drop_streak = $dropStreak
    }
    $out | ConvertTo-Json -Depth 8
    exit 0
}

# 若 state.json 已存在则拒绝覆盖（保护既有循环）
if (Test-Path $stateFile) {
    Write-Host "state.json 已存在 —— 循环已在运行或已初始化。本引导器只负责首次自举，不覆盖既有状态。" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $stateDir)) { New-Item -ItemType Directory -Path $stateDir -Force | Out-Null }
# 自复制：循环期每轮 ScanOnly 由目标项目自包含运行（不依赖 opencode-moa 仓库路径）
Copy-Item $PSCommandPath (Join-Path $stateDir "bootstrap.ps1") -Force

$scan = Invoke-HealthScan $Dir
$health = Get-HealthScore $scan

# 快照基线落盘（趋势对比用，绝对分无意义）
$baseline = [pscustomobject]@{
    created_at = (Get-Date -Format o)
    score      = $health.score
    sub_scores = $health.sub_scores
    history    = @($health.score)
    scan       = $scan
}
$baseline | ConvertTo-Json -Depth 8 | Set-Content $baselineFile -Encoding utf8

Write-Host "`n=== 健康快照（基线）===" -ForegroundColor Cyan
Write-Host "  files=$($scan.total_files) lines=$($scan.total_lines) lang=$((($scan.languages.GetEnumerator() | ForEach-Object { "$($_.Key):$($_.Value)" }) -join ','))"
Write-Host "  得分: $($health.score)/10" -ForegroundColor Yellow
Write-Host "  分项: $(($health.sub_scores.PSObject.Properties | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join ' | ')"

$candidates = Get-Candidates $scan
Write-Host "`n=== 候选改进清单（$($candidates.Count) 条，全部带证据）===" -ForegroundColor Cyan
foreach ($c in $candidates) {
    Write-Host "  [$($c.id)] $($c.title)  (risk=$($c.risk))" -ForegroundColor White
}

$onboard = Invoke-Onboarding -Skip:($NonInteractive -or $AutoAccept)
$accepted = Invoke-PreReview -Candidates $candidates -Auto:($NonInteractive -or $AutoAccept)

# ── 落盘 state.json（协议兼容：现有字段 + onboarding/baseline 扩展）──
$now = Get-Date -Format o
$roadmap = @()
$i = 0
foreach ($c in $accepted) {
    $i++
    $roadmap += [pscustomobject]@{
        id     = "t$i"
        title  = "$($c.title)（验收：对应 marker 回退至阈值内 + 探针全绿）"
        status = "open"
        note   = "来源: bootstrap 自举候选 $($c.id) | 风险: $($c.risk) | 证据: $($c.evidence)"
    }
}
$goal = if ($onboard.goal) { $onboard.goal } else { "自完善：健康快照单调不回退（基线 $($health.score)/10）+ 探针全绿" }
$state = [pscustomobject]@{
    schema_version = 1
    goal           = $goal
    created_at     = $now
    updated_at     = $now
    phase          = "working"
    roadmap        = $roadmap
    blockers       = @()
    finished       = $false
    onboarding     = [pscustomobject]@{
        run_command    = $onboard.run_command
        auth_boundary  = $onboard.auth_boundary
        budget_rounds  = $onboard.budget_rounds
        pref_reviewed  = $true
    }
    baseline       = [pscustomobject]@{
        file  = ".moa/longloop/health-baseline.json"
        score = $health.score
    }
}
if (-not (Test-Path $stateDir)) { New-Item -ItemType Directory -Path $stateDir -Force | Out-Null }
$state | ConvertTo-Json -Depth 6 | Set-Content $stateFile -Encoding utf8

# 足迹初始化
if (-not (Test-Path (Join-Path $stateDir "足迹.md"))) {
    @"
# 长程足迹（append-only）

> 首轮自举（bootstrap.ps1）：健康快照基线得分 $($health.score)/10，候选 $($candidates.Count) 条，预审接受 $($accepted.Count) 条。

- task: t1 初始化
- did: bootstrap 自举：内容探测 → 快照基线 → 候选预审
- verify: 基线已落盘 $baselineFile
- result: done
"@ | Set-Content (Join-Path $stateDir "足迹.md") -Encoding utf8
}

# ── 探针骨架（草案第 2 层；语法探针按语言生成，冒烟探针等运行方式）──
$probeDir = Join-Path $stateDir "probes"
New-Item -ItemType Directory -Path $probeDir -Force | Out-Null
$probeReadme = @"
# 验收探针目录（bootstrap 生成骨架，AI 补全实现）

> 草案第 2 层：探针由 AI 编写、机器可判、可被用户审查。
> 自检（负对照）：每个探针首次构建时配坏样本验证真能「红」；坏样本放 .fixtures/ 子目录，不进 .gitignore。

- 语法探针: 对每个源文件生成 parse/compile check（见 check-syntax.ps1 骨架）
- 冒烟探针: run_command = "$($onboard.run_command)"（Onboarding ①；未声明则挂起，循环只做静态层）
- 完善判定: 语法探针全绿 + health-baseline.json 加权总分不回退（连续 2 轮下降才算回退）
"@
Set-Content (Join-Path $probeDir "README.md") $probeReadme -Encoding utf8

# check-syntax.ps1 完整模板（全语言分支内置，AI 按项目补全/精简）
$syntaxTemplate = @'
# 语法探针骨架（bootstrap 生成，AI 补全）— 退出码 0=全绿，非 0=有红
# 用法: pwsh ./check-syntax.ps1 [-Root <项目根>]
param([string]$Root = (Get-Location).Path)
$failed = 0
Get-ChildItem $Root -Recurse -File | Where-Object { $_.FullName -notmatch '\\node_modules\\|\\.git\\|\\.moa\\|\\.opencode\\|\\dist\\|\\build\\|\\__pycache__\\' } | ForEach-Object {
    $file = $_
    switch -Regex ($file.Extension.ToLowerInvariant()) {
        '\.py'        { & python -m py_compile $file.FullName 2>&1 | Out-Null; if ($LASTEXITCODE -ne 0) { Write-Host "[FAIL] $($file.FullName)" -ForegroundColor Red; $failed++ } }
        '\.js|\.mjs|\.cjs' { & node --check $file.FullName 2>&1 | Out-Null; if ($LASTEXITCODE -ne 0) { Write-Host "[FAIL] $($file.FullName)" -ForegroundColor Red; $failed++ } }
        '\.ts|\.tsx'  { & npx tsc --noEmit $file.FullName 2>&1 | Out-Null; if ($LASTEXITCODE -ne 0) { Write-Host "[FAIL] $($file.FullName)" -ForegroundColor Red; $failed++ } }
        '\.ps1|\.psm1' { $errs = $null; [void][System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$errs); if ($errs.Count -gt 0) { Write-Host "[FAIL] $($file.FullName)" -ForegroundColor Red; $failed++ } }
        '\.go'        { & go vet $file.FullName 2>&1 | Out-Null; if ($LASTEXITCODE -ne 0) { Write-Host "[FAIL] $($file.FullName)" -ForegroundColor Red; $failed++ } }
        '\.rs'        { & cargo check --manifest-path (Join-Path $file.DirectoryName "Cargo.toml") 2>&1 | Out-Null; if ($LASTEXITCODE -ne 0) { Write-Host "[FAIL] $($file.FullName)" -ForegroundColor Red; $failed++ } }
        '\.json'      { try { $null = Get-Content $file.FullName -Raw | ConvertFrom-Json } catch { Write-Host "[FAIL] $($file.FullName)" -ForegroundColor Red; $failed++ } }
    }
}
if ($failed -eq 0) { Write-Host "语法探针全绿" -ForegroundColor Green } else { Write-Host "$failed 个文件语法失败" -ForegroundColor Red }
exit $failed
'@
Set-Content (Join-Path $probeDir "check-syntax.ps1") $syntaxTemplate -Encoding utf8

Write-Host "`n=== 自举完成 ===" -ForegroundColor Green
Write-Host "  state.json : $stateFile"
Write-Host "  基线快照   : $baselineFile"
Write-Host "  roadmap    : $($roadmap.Count) 项（预审接受）"
Write-Host "  探针目录   : $probeDir"
Write-Host "`n接续运行: pwsh longloop/long-loop.ps1 -Dir `"$Dir`"" -ForegroundColor Yellow
