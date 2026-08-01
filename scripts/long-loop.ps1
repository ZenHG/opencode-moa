#requires -Version 7
# long-loop.ps1 — 长程自完善循环驱动脚本
# 用法: pwsh scripts/long-loop.ps1 -Goal "目标文本" [-Dir <项目根>] [-Agent 门童] [-IntervalSec 180] [-MaxIterations 0] [-MaxHours 0] [-RunOnce] [-DryRun]
# 桌面版模式（推荐）: 先 `opencode serve --port 4096`（设 OPENCODE_SERVER_PASSWORD），再 -ServerPort 4096 -ServerPassword <密码> 连接；
#   桌面版 Settings → Servers → Add server 填同一 URL/密码，即可在桌面版 UI 实时查看循环会话。或 -SpawnServer 让脚本自动起服务。
# 独立模式: 不带 -Server* 参数 = 每轮独立 opencode run（无共享 server）
# 状态唯一事实源: <Dir>/.moa/longloop/state.json + 足迹.md（由 agent 维护，脚本只更新脚本字段）

param(
    [string]$Goal = "",
    [string]$Dir = (Get-Location).Path,
    [string]$Agent = "门童",
    [int]$IntervalSec = 180,
    [int]$MaxIterations = 0,
    [double]$MaxHours = 0,
    [string]$StateDir = "",
    [switch]$DryRun,
    [switch]$RunOnce,
    [int]$ServerPort = 0,
    [string]$ServerPassword = "",
    [string]$ServerHostname = "127.0.0.1",
    [switch]$SpawnServer
)

$ErrorActionPreference = "Stop"
$opencode = $null
$script:serverProc = $null
$script:serverReady = $false

function Get-OpencodeBin {
    # 查找顺序: OPENCODE_BIN 环境变量 → PATH → npm 全局 → 常见安装路径
    if ($env:OPENCODE_BIN -and (Test-Path $env:OPENCODE_BIN)) { return $env:OPENCODE_BIN }
    foreach ($c in @("opencode", "opencode.exe")) {
        $cmd = Get-Command $c -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    $npmRoot = npm root -g 2>$null
    if ($npmRoot) {
        $p = Join-Path $npmRoot "opencode-ai/bin/opencode.exe"
        if (Test-Path $p) { return $p }
    }
    foreach ($p in @("$HOME\.opencode\bin\opencode.exe", "$HOME\.local\bin\opencode.exe", "$env:APPDATA\npm\node_modules\opencode-ai\bin\opencode.exe")) {
        if (Test-Path $p) { return $p }
    }
    return $null
}

function New-LogLine {
    param([string]$Msg)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path (Join-Path $script:stateDir "loop.log") -Value "[$ts] $Msg" -Encoding utf8
}

function Save-State {
    param($State)
    $State.updated_at = (Get-Date -Format o)
    $State | ConvertTo-Json -Depth 6 | Set-Content -Path $script:stateFile -Encoding utf8
}

function Get-FileSha {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return "" }
    (Get-FileHash -Path $Path -Algorithm SHA256).Hash
}

# 变化签名 = state.json + 足迹.md 双哈希拼接（足迹追加也算产出，避免「干了活却判无变化」）
function Get-StateSignature {
    (Get-FileSha $script:stateFile) + "|" + (Get-FileSha $script:footprintFile)
}

function Set-StateProp {
    param($State, [string]$Name, $Value)
    if ($null -eq $State.PSObject.Properties[$Name]) {
        $State | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    } else {
        $State.$Name = $Value
    }
}

function Test-ServerHealth {
    param([string]$Url, [string]$Password)
    try {
        $u = [uri]$Url
        $auth = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("opencode:$Password"))
        $r = Invoke-WebRequest -Uri "$Url/app" -Headers @{ Authorization = "Basic $auth" } -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        return $r.StatusCode -eq 200
    } catch { return $false }
}

function Test-PortFree {
    # 探测 TCP 端口是否空闲（跨平台，无需管理权限）
    param([int]$Port)
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
    try { $listener.Start(); return $true } catch { return $false } finally { $listener.Stop() }
}

function Start-LoopServer {
    # 自起 opencode serve（SpawnServer 模式）；端口被占用时自动顺延
    if (-not $ServerPassword) { Write-Host "-SpawnServer 需要同时提供 -ServerPassword。" -ForegroundColor Red; exit 1 }
    $port = if ($ServerPort -gt 0) { $ServerPort } else { 4096 }
    if (-not (Test-PortFree $port)) {
        $newPort = $port
        $found = $false
        for ($i = 1; $i -le 10; $i++) {
            if (Test-PortFree ($port + $i)) { $newPort = $port + $i; $found = $true; break }
        }
        if (-not $found) { Write-Host "端口 $port 及后续 10 个端口均被占用，无法启动 server。请释放端口，或指定空闲的 -ServerPort。" -ForegroundColor Red; exit 1 }
        Write-Host "端口 $port 已被其他进程占用，自动改用端口 $newPort（桌面版挂载请用 http://127.0.0.1:$newPort）。" -ForegroundColor Yellow
        $port = $newPort
    }
    $script:serverPort = $port
    Write-Host "启动 opencode server (127.0.0.1:$port)…" -ForegroundColor Yellow
    $args = @("serve", "--port", "$port", "--hostname", $ServerHostname, "--log-level", "ERROR")
    $ext = [System.IO.Path]::GetExtension($script:opencode).ToLowerInvariant()
    $launchArgs = @()
    if ($ext -eq ".ps1") { $launchArgs = @("pwsh", "-NoProfile", "-File", $script:opencode) + $args }
    elseif ($ext -in @(".cmd", ".bat")) { $launchArgs = @("cmd.exe", "/c", "`"$script:opencode`"") + $args }
    else { $launchArgs = @($script:opencode) + $args }
    $p = Start-Process -FilePath $launchArgs[0] -ArgumentList $launchArgs[1..($launchArgs.Count - 1)] -PassThru -WindowStyle Hidden
    $script:serverProc = $p
    $url = "http://${ServerHostname}:${port}"
    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Milliseconds 1000
        if (Test-ServerHealth $url $ServerPassword) { $script:serverReady = $true; break }
        if ($p.HasExited) { Write-Host "server 进程异常退出 (exit=$($p.ExitCode))，请检查 opencode serve 是否可用。" -ForegroundColor Red; exit 1 }
    }
    if (-not $script:serverReady) { Write-Host "server 在 30s 内未就绪。" -ForegroundColor Red; exit 1 }
    $script:serverUrl = $url
    Write-Host "server 就绪: $url" -ForegroundColor Green
}

function Invoke-Round {
    param([int]$N)
    # 动态首句：喂给 opencode 的自动标题生成（不传 --title 时由 title agent 概括）
    $taskHint = ""
    if (Test-Path $script:stateFile) {
        try {
            $st = Get-Content $script:stateFile -Raw | ConvertFrom-Json
            $openTask = @($st.roadmap | Where-Object { $_.status -in @("open", "in_progress") }) | Select-Object -First 1
            if ($openTask) { $taskHint = "本轮推进：$($openTask.title)" }
            elseif ($st.finished) { $taskHint = "状态已收官（finished）" }
            elseif (@($st.blockers).Count -gt 0) { $taskHint = "等待用户答复（blockers=$(@($st.blockers).Count)）" }
        } catch { }
    }
    if (-not $taskHint -and $script:goalText) {
        $goalShort = $script:goalText
        if ($goalShort.Length -gt 60) { $goalShort = $goalShort.Substring(0, 60) + "…" }
        $taskHint = "本轮目标：$goalShort"
    }
    $prompt = @"
[长程自完善 · 第 $N 轮 · 无人值守] $taskHint
你是门童。本次输入不是用户需求，而是自主循环的调度请求。
目标：推进 .moa/longloop/state.json 的 goal 字段（先取证再行动）。

执行协议：
1. task(@工具人) 读取 .moa/longloop/state.json 与 .moa/longloop/足迹.md 全文并内联
2. 从 roadmap 选一个 open 任务（in_progress 先看 note 恢复现场）；无则按 goal 新开一项
3. 按置信度路由派发：简单→闪电侠/中级·码农；中→中级链（三意见+融合）；探索型→意见层并行直接汇总；重任务→旗舰链
4. 无人值守约束：需求不清晰/置信度低 → 不烧旗舰链，写 blockers 换任务；同一任务连续 3 轮无进展 → blocked 换路线；同一条验收连败 3 次 → blocked 换下一项（「没做成但说清了」合格，「做了但更糟」不合格）
5. 派发时要求执行 agent 更新状态并 append 一条结构化足迹到 足迹.md（格式见 .moa/longloop/足迹模板.md：做了什么/验证/证据/负结果/下一步，负结果必填）：
   - 首选 moa-loop MCP 工具（moa_state_read/moa_roadmap_add/moa_roadmap_update/moa_blockers_add/moa_footprint_append/moa_heartbeat/moa_finish），
     由执行 agent 直接调用维护 state.json（注意工具目录=当前项目，与文件路径一致）
   - 工具不可用时退化为直接编辑 state.json（任务标 done/blocked + note 保留进度）
   - 派发给执行 agent 的任务描述必须内联取证结果（state.json/足迹.md 全文）并附：
     最小步骤集（add→update→footprint→heartbeat 等具体步骤）+ 工具边界（只允许 moa_* 与 read；
     禁止 grep/glob/bash/webfetch/探索类动作；任务外多想一步 → 写进 note 回传，禁止自行扩展动作）
   - 执行 agent 用 todowrite（opencode 原生任务清单）把本轮任务拆成步骤并逐步标记完成
6. 全部任务 done/blocked 且 blockers 空 → 让执行 agent 调 moa_finish 收官（校验通过才置 finished=true，防提前收尾）；全 blocked 且 blockers 非空 → phase=waiting_user
7. 回复一行总结：本轮任务 + 结果 + state.json 变更要点
"@
    if ($N -eq 1 -and $script:goalText) {
        $prompt += "`n本轮目标：$($script:goalText)（目标全文在 state.json 的 goal 字段）。"
    }
    Write-Host "  [run] opencode --agent $Agent --dir $Dir" -ForegroundColor Gray
    # 不传 --title：由 opencode 的 title agent 基于首句自动生成智能标题（如「执行 t2：改写 round2」）
    $out = & $script:opencode run --agent $Agent --dir $Dir --print-logs=false --log-level ERROR -- $prompt 2>&1
    $code = $LASTEXITCODE
    $text = ($out | Out-String).Trim()
    if ($code -ne 0) {
        New-LogLine "round $N FAILED exit=$code"
        Write-Host "  [fail] exit=$code" -ForegroundColor Red
        if ($text) { Write-Host "  $text" -ForegroundColor DarkGray }
    }
    return @{ Code = $code; Text = $text }
}

# ── 初始化 ──
$Dir = (Resolve-Path $Dir).Path
if (-not $StateDir) { $StateDir = Join-Path $Dir ".moa/longloop" }
$script:stateDir = $StateDir
$script:stateFile = Join-Path $StateDir "state.json"
$script:footprintFile = Join-Path $StateDir "足迹.md"
$templateState = Join-Path $Dir ".moa/longloop/state.template.json" # 用户项目自带模板
$templateFoot = Join-Path $Dir ".moa/longloop/足迹模板.md"
if (-not (Test-Path $templateState)) {
    # 回退1: 脚本所在仓库自带模板（安装 opencode-moa 后 scripts/ 与 .moa/ 同根）
    $repoRoot = Split-Path $PSScriptRoot -Parent
    $alt = Join-Path $repoRoot ".moa/longloop/state.template.json"
    if (Test-Path $alt) { $templateState = $alt; $templateFoot = Join-Path (Split-Path $alt -Parent) "足迹模板.md" }
}
if (-not (Test-Path $templateState)) {
    # 回退2: 内联默认模板（脚本可独立运行，不依赖仓库目录）
    New-Item -ItemType Directory -Path (Split-Path $templateState -Parent) -Force | Out-Null
    $inlineState = '{\n  "schema_version": 1,\n  "goal": "<长程目标>",\n  "created_at": null,\n  "updated_at": null,\n  "phase": "working",\n  "roadmap": [],\n  "blockers": [],\n  "finished": false\n}'
    $inlineState | Set-Content -Path $templateState -Encoding utf8
    if (-not (Test-Path $templateFoot)) {
        Set-Content -Path $templateFoot -Value "# 长程足迹（append-only）`n`n> 每轮追加一行：任务/做了什么/验证/结果。`n" -Encoding utf8
    }
}
$script:goalText = $Goal

$opencode = Get-OpencodeBin
if (-not $opencode) {
    Write-Host "找不到 opencode CLI —— 长程循环依赖它驱动每轮会话，桌面版无法替代（桌面版仅可挂载查看）。" -ForegroundColor Red
    Write-Host "安装 opencode CLI：" -ForegroundColor Yellow
    if ($env:OS -match "Windows") {
        Write-Host "  npm install -g opencode-ai" -ForegroundColor Cyan
        Write-Host "  若 opencode.exe 报 'Access is denied'（Windows Defender 误报）：重装一次，或把 npm 全局目录加入 Defender 排除项。" -ForegroundColor Yellow
    } else {
        Write-Host "  curl -fsSL https://opencode.ai/install | bash   # 或 npm install -g opencode-ai" -ForegroundColor Cyan
    }
    Write-Host "装好后若仍找不到，设置环境变量 OPENCODE_BIN 指向 opencode 可执行文件。" -ForegroundColor Yellow
    exit 1
}

# ── server 模式（桌面版挂载）──
$script:serverUrl = ""
if ($ServerPort -gt 0) {
    if (-not $ServerPassword) { Write-Host "-ServerPort 需要同时提供 -ServerPassword。" -ForegroundColor Red; exit 1 }
    # 凭据须在 serve 子进程启动前设置（否则 serve 无认证，健康检查失败）
    $env:OPENCODE_SERVER_HOSTNAME = $ServerHostname
    $env:OPENCODE_SERVER_PASSWORD = $ServerPassword
    $env:OPENCODE_SERVER_USERNAME = "opencode"
    $script:serverPort = $ServerPort
    $script:serverUrl = "http://${ServerHostname}:${ServerPort}"
    if (Test-ServerHealth $script:serverUrl $ServerPassword) {
        Write-Host "已连接外部 opencode server: $($script:serverUrl)（桌面版可 Add server 挂载查看）" -ForegroundColor Green
        $script:serverReady = $true
    } elseif ($SpawnServer) {
        Start-LoopServer
    } else {
        if (-not (Test-PortFree $ServerPort)) { Write-Host "端口 $ServerPort 已被其他进程占用，且不是本脚本可连接的 opencode server。换一个 -ServerPort，或加 -SpawnServer 让脚本自动选端口。" -ForegroundColor Red }
        else { Write-Host "无法连接 $($script:serverUrl)。请先启动 server（opencode serve --port $ServerPort），或加 -SpawnServer 让脚本自动启动。" -ForegroundColor Red }
        exit 1
    }
    # CLI 客户端（opencode run）用的端口：SpawnServer 自动顺延后用协商端口
    $env:OPENCODE_PORT = "$($script:serverPort)"
}
if (-not (Test-Path $StateDir)) { New-Item -ItemType Directory -Path $StateDir -Force | Out-Null }

$firstRun = -not (Test-Path $script:stateFile)
if ($firstRun) {
    if (-not $Goal) { Write-Host "首次运行必须提供 -Goal 目标文本。" -ForegroundColor Red; exit 1 }
    $template = Get-Content $templateState -Raw -Encoding utf8 | ConvertFrom-Json
    $template.goal = $Goal
    $template.created_at = Get-Date -Format o
    Save-State $template
}
if (-not (Test-Path $script:footprintFile)) {
    if (Test-Path $templateFoot) { Copy-Item $templateFoot $script:footprintFile }
    else { Set-Content -Path $script:footprintFile -Value "# 长程足迹（append-only）`n" -Encoding utf8 }
}

$state = Get-Content $script:stateFile -Raw -Encoding utf8 | ConvertFrom-Json

if ($DryRun) {
    Write-Host "=== 长程循环预演 ===" -ForegroundColor Yellow
    Write-Host "  opencode : $opencode"
    Write-Host "  项目目录 : $Dir"
    Write-Host "  agent    : $Agent"
    Write-Host "  状态文件 : $script:stateFile"
    if ($script:serverUrl) { Write-Host "  server   : $($script:serverUrl) (SpawnServer=$SpawnServer)" }
    Write-Host "  目标     : $($state.goal)"
    Write-Host "  roadmap  : $($state.roadmap.Count) 项 | blockers: $($state.blockers.Count) | phase: $($state.phase)"
    Write-Host "  首轮 prompt 预览:"
    $p1 = @"
[长程自完善模式 · 第 1 轮 · 无人值守]
你是门童。本次输入不是用户需求，而是自主循环的调度请求。
目标：推进 .moa/longloop/state.json 的 goal 字段（先取证再行动）。
执行协议：@工具人 取证 → 选 open 任务 → 按置信度路由派发 → 执行 agent 回写 state.json/足迹.md → blockers 挂起 → finished 停止。
"@
    if ($Goal) { $p1 += "`n本轮目标：$Goal（目标全文在 state.json 的 goal 字段）。" }
    Write-Host "  $p1" -ForegroundColor DarkGray
    exit 0
}

# ── 主循环 ──
$deadline = if ($MaxHours -gt 0) { (Get-Date).AddHours($MaxHours) } else { $null }
$streak = 0
$iter = if ($state.iteration) { [int]$state.iteration } else { 0 }

Write-Host "长程循环启动: 目标 = $($state.goal)" -ForegroundColor Green
Write-Host "  agent=$Agent | 间隔=${IntervalSec}s | 状态=$script:stateFile" -ForegroundColor Gray
New-LogLine "loop started goal=$($state.goal)"

while ($true) {
    $iter++
    $state = Get-Content $script:stateFile -Raw -Encoding utf8 | ConvertFrom-Json
    $sigBefore = Get-StateSignature
    $roundStart = Get-Date

    Write-Host "`n── 第 $iter 轮 ($(Get-Date -Format "HH:mm:ss")) ──" -ForegroundColor Cyan
    if ($state.phase -eq "finished" -or $state.finished -eq $true) {
        Write-Host "phase=finished：目标达成，停止。" -ForegroundColor Green
        New-LogLine "loop finished at iteration $iter"
        break
    }
    if ($state.phase -eq "waiting_user") {
        Write-Host "phase=waiting_user：等待用户决策（拦路虎 $(($state.blockers | ForEach-Object { $_.question }) -join ' | ')）。间隔拉长到 1800s。" -ForegroundColor Yellow
    }

    $round = Invoke-Round $iter
    $sigAfter = Get-StateSignature
    $durationSec = [int]((Get-Date) - $roundStart).TotalSeconds

    $summary = $round.Text -replace "`n", " "
    if ($summary.Length -gt 300) { $summary = $summary.Substring(0, 300) + "…" }

    $state = Get-Content $script:stateFile -Raw -Encoding utf8 | ConvertFrom-Json
    Set-StateProp $state "iteration" $iter
    Set-StateProp $state "last_round_change" ($sigBefore -ne $sigAfter)
    Set-StateProp $state "last_round_summary" $summary
    if (-not $state.finished -and $state.phase -eq "waiting_user" -and $state.blockers.Count -eq 0) { $state.phase = "working" }
    Save-State $state

    if ($state.last_round_change) { $streak = 0 }
    else {
        $streak++
        Write-Host "  [warn] 状态无变化（streak=$streak/4，含足迹）" -ForegroundColor Yellow
    }
    if ($round.Text) { Write-Host "  $($round.Text)" -ForegroundColor DarkGray }
    # 决策日志（结构化，append-only，供复盘/审计）：round/exit/change/duration/roadmap/blockers/phase/hash
    New-LogLine "round=$iter exit=$($round.Code) change=$($state.last_round_change) duration=${durationSec}s roadmap=$($state.roadmap.Count) blockers=$($state.blockers.Count) phase=$($state.phase) sig=$($sigAfter.Substring(0,12))"

    if ($state.phase -eq "finished" -or $state.finished -eq $true) { Write-Host "目标达成，停止。" -ForegroundColor Green; break }
    if ($streak -ge 4) { Write-Host "连续 4 轮状态无变化（含足迹），停止（可 -DryRun 或断点重启排查）。" -ForegroundColor Yellow; break }
    if ($MaxIterations -gt 0 -and $iter -ge $MaxIterations) { Write-Host "达到最大轮数 $MaxIterations，停止。" -ForegroundColor Yellow; break }
    if ($deadline -and (Get-Date) -ge $deadline) { Write-Host "达到最长运行时间 ${MaxHours}h，停止。" -ForegroundColor Yellow; break }
    if ($RunOnce) { break }

    $sleep = if ($state.phase -eq "waiting_user") { 1800 } else { $IntervalSec }
    Start-Sleep -Seconds $sleep
}

Write-Host "`n=== 长程循环结束（共 $iter 轮）===" -ForegroundColor Green
Write-Host "  最终 phase: $($state.phase) | roadmap done: $(@($state.roadmap | Where-Object { $_.status -eq 'done' }).Count)/$($state.roadmap.Count) | blockers: $($state.blockers.Count)"
New-LogLine "loop ended after $iter iterations phase=$($state.phase)"

# ── 清理自起 server ──
if ($script:serverProc -and -not $script:serverProc.HasExited) {
    Write-Host "关闭自起 server (PID $($script:serverProc.Id))…" -ForegroundColor Gray
    Stop-Process -Id $script:serverProc.Id -Force -ErrorAction SilentlyContinue
}
