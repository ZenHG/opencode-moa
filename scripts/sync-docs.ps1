# sync-docs.ps1 — 从 .opencode/agents/ 和 opencode.json 同步到部署手册
#
# 用法: pwsh ./scripts/sync-docs.ps1
# 选项: -DryRun  只报告不修改
#        -Target  "zh" | "en" | "all" (默认 all)
#
# 同步范围:
#   1. Agent YAML frontmatter（以 agent 文件为准）
#   2. opencode.json permission.task 白名单
#   3. Agent 计数

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
$ocJson = Get-Content "$base\opencode.json" -Raw -Encoding utf8 | ConvertFrom-Json
$taskAllowlist = $ocJson.permission.task.PSObject.Properties |
    Where-Object { $_.Value -eq "allow" } | ForEach-Object { $_.Name } | Sort-Object
$totalAgents = $agents.Count

# ── 处理一个部署文档 ──
function Sync-Doc {
    param([string]$filePath)

    $shortName = Split-Path $filePath -Leaf
    if (-not (Test-Path $filePath)) { Warn "${shortName}: 不存在"; return }

    $content = Get-Content $filePath -Raw -Encoding utf8
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

    # ── 3b. permission.task ──
    $tPat = '(?s)("permission"\s*:\s*\{[^}]*"task"\s*:\s*\{)(.*?)(\})'
    $t = [regex]::Match($content, $tPat)
    if ($t.Success) {
        $entries = [ordered]@{}
        $entries['*'] = 'deny'
        foreach ($a in $taskAllowlist) { $entries[$a] = 'allow' }
        $parts = foreach ($e in $entries.GetEnumerator()) { "      `"$($e.Key)`": `"$($e.Value)`"" }
        $newBody = "`n" + ($parts -join ",`n") + "`n    "

        if ($t.Groups[2].Value.Trim() -ne $newBody.Trim()) {
            $content = $content.Replace($t.Groups[0].Value, $t.Groups[1].Value + $newBody + $t.Groups[3].Value)
            $changes++
            Ok "${shortName}: 更新 permission.task ($($taskAllowlist.Count) 条)"
        }
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
Write-Host "  检测到 $totalAgents 个 agent | task 白名单 $($taskAllowlist.Count) 条" -ForegroundColor Gray

$total = 0
foreach ($f in $files) { $total += Sync-Doc $f }

Write-Host ""
if ($total -eq 0) { Write-Host "  全部已是最新。" -ForegroundColor Green }
else              { Write-Host "  共 $total 处修改。" -ForegroundColor $(if ($DryRun) { 'Yellow' } else { 'Green' }) }
Write-Host ""
Write-Host "  提示: README 表格的 model 列需手动同步。" -ForegroundColor Gray
Write-Host "  运行 'pwsh .opencode/tests/T1-readme-consistency.ps1' 验证。" -ForegroundColor Gray
