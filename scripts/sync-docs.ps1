# sync-docs.ps1 — 从 .opencode/agents/ 和 opencode.json 同步到部署手册
#
# 用法: pwsh ./scripts/sync-docs.ps1
# 选项: -DryRun  只报告不修改
#        -Target  "zh" | "en" | "all" (默认 all)
#
# 同步范围:
#   1. Agent YAML frontmatter（以 agent 文件为准）
#   2. opencode.json permission.task 白名单 (<!-- SYNC:TASK_WHITELIST -->)
#   3. opencode.json per-agent 配置 (<!-- SYNC:PER_AGENT_CONFIG -->)
#   4. Agent 计数
#   5. todowrite 权限存在性检查

param(
    [ValidateSet("zh","en","all")]
    [string]$Target = "all",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$base = Split-Path $scriptDir

function Info($m) { Write-Host "  [INFO] $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "  [OK] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  [WARN] $m" -ForegroundColor Yellow }

# ── 1. 读取当前 agent 配置 ──
$agents = @{}
Get-ChildItem "$base\.opencode\agents\*.md" | ForEach-Object {
    $name = $_.BaseName
    $raw = Get-Content $_.FullName -Raw -Encoding utf8
    if ($raw -match '(?s)^---(.+?)---') {
        $yaml = $matches[1]
        $model  = if ($yaml -match 'model:\s*(\S+)') { $matches[1] } else { '' }
        $hidden = [bool]($yaml -match 'hidden:\s*true')
        $agents[$name] = @{ name = $name; yaml = $yaml; model = $model; hidden = $hidden }
    }
}

# ── 2. 读取 opencode.json ──
$ocRaw = Get-Content "$base\opencode.json" -Raw -Encoding utf8
$ocJson = $ocRaw | ConvertFrom-Json
$taskAllowlist = $ocJson.permission.task.PSObject.Properties |
    Where-Object { $_.Value -eq "allow" } | ForEach-Object { $_.Name } | Sort-Object
$totalAgents = $agents.Count
$hasTodoWrite = ($ocJson.permission.todowrite -eq "allow")

# ── 2b. 提取 per‑agent 配置（steps 等非默认值） ──
$ocObj = $ocRaw | ConvertFrom-Json -AsHashtable
$agentOverrides = @{}
if ($ocObj.ContainsKey('agent')) {
    foreach ($kv in $ocObj['agent'].GetEnumerator()) {
        $aName = $kv.Key
        $aCfg  = $kv.Value
        $hasSteps = $aCfg.ContainsKey('steps')
        if ($hasSteps) {
            $taskList = @()
            if ($aCfg.ContainsKey('permission') -and $aCfg['permission'].ContainsKey('task')) {
                $taskList = ($aCfg['permission']['task'].GetEnumerator() |
                    Where-Object { $_.Value -eq "allow" } |
                    ForEach-Object { $_.Key } | Sort-Object)
            }
            $agentOverrides[$aName] = @{ steps = $aCfg['steps']; task = $taskList }
        }
    }
}

# ── 2c. 读取 .moa 目录（界线/足迹/拦路虎） ──
$moaBoundaries = if (Test-Path "$base\.moa\界线.json") { (Get-Content "$base\.moa\界线.json" -Raw -Encoding utf8).TrimEnd("`r","`n") } else { '' }
$moaFootprint  = if (Test-Path "$base\.moa\足迹模板.md")  { (Get-Content "$base\.moa\足迹模板.md" -Raw -Encoding utf8).TrimEnd("`r","`n") } else { '' }
$moaBlocker    = if (Test-Path "$base\.moa\拦路虎模板.md") { (Get-Content "$base\.moa\拦路虎模板.md" -Raw -Encoding utf8).TrimEnd("`r","`n") } else { '' }

# ── 生成 task 白名单块 ──
function Gen-TaskWhitelist {
    param([string[]]$names, [string]$lang)
    $mapped = Map-Allowlist -cnNames $names -lang $lang
    $indent = "      "
    $lines = @()
    $lines += '    "task": {'
    $lines += '      "*": "deny",'
    foreach ($a in $mapped) {
        $lines += "$indent`"$a`": `"allow`","
    }
    $lines[-1] = $lines[-1] -replace ',$', ''
    $lines += '    },'
    return ($lines -join "`n")
}

# ── 生成 per‑agent 配置块 ──
function Gen-AgentConfig {
    param([hashtable]$overrides)
    if ($overrides.Count -eq 0) { return "    // (no agent-level overrides)" }
    $lines = @()
    foreach ($kv in $overrides.GetEnumerator()) {
        $name = $kv.Key
        $cfg  = $kv.Value
        $lines += "    `"$name`": {"
        $lines += "      `"steps`": $($cfg.steps),"
        $lines += '      "permission": {'
        $lines += '        "*": "ask",'
        $lines += '        "task": {'
        foreach ($t in $cfg.task) { $lines += "          `"$t`": `"allow`"," }
        $lines[-1] = $lines[-1] -replace ',$', ''
        $lines += '        },'
        $lines += '        "*_*": "deny"'
        $lines += '      }'
        $lines += '    },'
    }
    # 去尾逗号
    if ($lines.Count -gt 0) { $lines[-1] = $lines[-1] -replace ',$', '' }
    return ($lines -join "`n")
}

# ── 根据 lang 映射 agent 名称 ──
# en doc uses English aliases; zh doc uses Chinese file names
$enNameMap = @{
    "门童"   = "concierge-router"
    "工具人"       = "tool-handler"
    "工具人-mimo"  = "tool-handler-mimo"
    "闪电侠"       = "swift"
    "视觉翻译官"   = "vision-translator"
    "中级·工程"   = "mid-eng"
    "中级·创意"   = "mid-creative"
    "中级·码农"   = "mid-coder"
    "中级·融合"   = "mid-fuse"
    "旗舰·架构"   = "flag-arch"
    "旗舰·规划"   = "flag-plan"
    "旗舰·工程"   = "flag-eng"
    "旗舰·融合"   = "flag-fuse"
    "旗舰·执行"   = "flag-impl"
    "旗舰·质检"   = "flag-qa"
    "前端·还原"   = "fe-restore"
    "前端·逻辑"   = "fe-logic"
    "前端·动效"   = "fe-motion"
    "前端·总工"   = "fe-lead"
    "残差提取者"   = "residual-extractor"
    "置信度评估者" = "confidence-assessor"
    "融合·保底"   = "fusion-fallback"
}

function Map-Allowlist {
    param([string[]]$cnNames, [string]$lang)
    if ($lang -eq "zh") { return $cnNames }
    return $cnNames | ForEach-Object { if ($enNameMap.ContainsKey($_)) { $enNameMap[$_] } else { $_ } }
}

# ── 替换 marker 间的内容 ──
function Replace-BetweenMarkers {
    param([string]$content, [string]$startMarker, [string]$endMarker, [string]$newInner)

    $pat = [regex]::Escape($startMarker) + '(?s:.*?)' + [regex]::Escape($endMarker)
    $m = [regex]::Match($content, $pat)
    if (-not $m.Success) { return $content, $false }

    $oldBlock = $m.Groups[0].Value
    $innerStart = $oldBlock.IndexOf($startMarker) + $startMarker.Length
    $innerEnd   = $oldBlock.LastIndexOf($endMarker)
    $innerOld   = $oldBlock.Substring($innerStart, $innerEnd - $innerStart)

    if ($innerOld.Trim() -eq $newInner.Trim()) { return $content, $false }

    $newBlock = $startMarker + "`n" + $newInner + "`n" + $endMarker
    return $content.Replace($oldBlock, $newBlock), $true
}

# ── 处理一个部署文档 ──
function Sync-Doc {
    param([string]$filePath)

    $shortName = Split-Path $filePath -Leaf
    if (-not (Test-Path $filePath)) { Warn "${shortName}: 不存在"; return }

    $content = Get-Content $filePath -Raw -Encoding utf8
    $lang = if ($shortName -match '\.en\.') { 'en' } else { 'zh' }
    $changes = 0

    # ── 3a. Agent frontmatter ──
    foreach ($agentName in $agents.Keys) {
        $hPat = '(?m)^#{3,4}\s+' + [regex]::Escape($agentName) + '\s*$'
        $h = [regex]::Match($content, $hPat)
        if (-not $h.Success) { continue }

        $after = $content.Substring($h.Index + $h.Length)
        $cb = [regex]::Match($after, '(?s)```(yaml|markdown)\s*\n(.*?)```')
        if (-not $cb.Success -or $cb.Groups[2].Value -notmatch '^\s*---') { continue }

        $body = $cb.Groups[2].Value
        $fs = $body.IndexOf('---')
        $fe = $body.IndexOf('---', $fs + 3)
        if ($fs -lt 0 -or $fe -lt 0) { continue }

        $oldFm = $body.Substring($fs, $fe - $fs + 3)
        $newFm = "---`n$($agents[$agentName].yaml.Trim())`n---"
        if ($oldFm.Trim() -eq $newFm.Trim()) { continue }

        $newBody = $body.Substring(0, $fs) + $newFm + $body.Substring($fe + 3)
        $fence   = '```' + $cb.Groups[1].Value
        $oldFull = $fence + "`n" + $body + "`n" + '```'
        $newFull = $fence + "`n" + $newBody + "`n" + '```'

        $na = $after.Substring(0, $cb.Index) + $newFull + $after.Substring($cb.Index + $cb.Length)
        $content = $content.Substring(0, $h.Index + $h.Length) + $na
        $changes++
        Ok "${shortName}: 更新 ${agentName} frontmatter"
    }

    # ── 3b. Task whitelist (SYNC:TASK_WHITELIST) ──
    $taskBlock = Gen-TaskWhitelist -names $taskAllowlist -lang $lang
    $content, $taskChanged = Replace-BetweenMarkers $content "<!-- SYNC:TASK_WHITELIST start -->" "<!-- SYNC:TASK_WHITELIST end -->" $taskBlock
    if ($taskChanged) {
        $changes++
        Ok "${shortName}: 更新 task whitelist ($($taskAllowlist.Count) 条)"
    }

    # ── 3c. Agent 计数 ──
    $pats = @(
        '(?<=部署\s*)(\d+)\s*个\s*agent',
        '(?<=deploy\w*\s+)(\d+)(?=\s*[-–—]\s+agent)',
        '(\d+)\s+agents?\s+·\s+\d+\s+commands?\s+·\s+\d+\s+skills?',
        '(\d+)\s+个\s+agent\s+·\s+\d+\s+个\s+命令\s+·\s+\d+\s+个\s+skill'
    )
    $seen = @{}
    foreach ($pat in $pats) {
        $content = [regex]::Replace($content, $pat, {
            param($m)
            if ($seen.ContainsKey($m.Index)) { return $m.Value }
            $seen[$m.Index] = $true
            $old = [int]$m.Groups[1].Value
            if ($old -ne $totalAgents) { $changes++; Ok "${shortName}: 计数 $old → $totalAgents" }
            return $m.Value.Replace($m.Groups[1].Value, $totalAgents.ToString())
        })
    }

    # ── 3d. Per‑agent config (SYNC:PER_AGENT_CONFIG) ──
    $agentBlock = Gen-AgentConfig $agentOverrides
    $content, $agentChanged = Replace-BetweenMarkers $content "<!-- SYNC:PER_AGENT_CONFIG start -->" "<!-- SYNC:PER_AGENT_CONFIG end -->" $agentBlock
    if ($agentChanged) {
        $changes++
        Ok "${shortName}: 更新 per‑agent 配置 ($($agentOverrides.Count) 个有覆盖)"
    }

    # ── 3e. todowrite 权限 ──
    if ($hasTodoWrite) {
        $tdwPat = '"todowrite"\s*:\s*"allow"'
        if (-not ($content -match $tdwPat)) {
            Warn "${shortName}: 缺少 todowrite: allow (需手动添加)"
        } else {
            Info "${shortName}: todowrite 权限已存在"
        }
    }

    # ── 3f. .moa 目录（界线/足迹/拦路虎） ──
    $content, $moaBChanged = Replace-BetweenMarkers $content "<!-- SYNC:MOA_BOUNDARIES start -->" "<!-- SYNC:MOA_BOUNDARIES end -->" $moaBoundaries
    if ($moaBChanged) { $changes++; Ok "${shortName}: 更新 .moa/界线.json" }
    $content, $moaFChanged = Replace-BetweenMarkers $content "<!-- SYNC:MOA_FOOTPRINT start -->" "<!-- SYNC:MOA_FOOTPRINT end -->" $moaFootprint
    if ($moaFChanged) { $changes++; Ok "${shortName}: 更新 .moa/足迹模板.md" }
    $content, $moaKChanged = Replace-BetweenMarkers $content "<!-- SYNC:MOA_BLOCKER start -->" "<!-- SYNC:MOA_BLOCKER end -->" $moaBlocker
    if ($moaKChanged) { $changes++; Ok "${shortName}: 更新 .moa/拦路虎模板.md" }

    if ($changes -eq 0) { Info "${shortName}: 已是最新" }
    elseif ($DryRun)     { Warn "${shortName}: $changes 处需修改 (DryRun)" }
    else {
        Set-Content -Path $filePath -Value $content -Encoding utf8
        Ok "${shortName}: 已写入 $changes 处修改"
    }
    return $changes
}

# ── 执行 ──
$files = @()
if ($Target -in @("zh","all")) { $files += "$base\docs\opencode-moa.md" }
if ($Target -in @("en","all")) { $files += "$base\docs\opencode-moa.en.md" }

Write-Host "=== 同步部署手册 ===" -ForegroundColor Cyan
Write-Host "  检测到 $totalAgents 个 agent | task 白名单 $($taskAllowlist.Count) 条 | $($agentOverrides.Count) 个 agent 覆盖" -ForegroundColor Gray

$total = 0
foreach ($f in $files) { $total += Sync-Doc $f }

Write-Host ""
if ($total -eq 0) { Write-Host "  全部已是最新。" -ForegroundColor Green }
else              { Write-Host "  共 $total 处修改。" -ForegroundColor $(if ($DryRun) { 'Yellow' } else { 'Green' }) }
Write-Host ""
Write-Host "  提示: README 表格的 model 列需手动同步。" -ForegroundColor Gray
Write-Host "  运行 'pwsh .opencode/tests/T1-readme-consistency.ps1' 验证。" -ForegroundColor Gray
