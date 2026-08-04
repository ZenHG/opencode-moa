# verify-evidence-refs.ps1 — 足迹 evidence ref 可解析校验（0 token；P1-10）
# 规则：evidence 正则常量单一事实源 = manifest.json（与 server.js P0-4 同源）
#  - commit:<sha>：有 .git 时 git rev-parse 验证存在；不存在记警告（非阻塞，amend/squash 语义）；无 .git 跳过（环境矩阵降级）
#  - smoke:/pr:/run:：ref 是标识符非路径，仅断言格式非空；若值含路径分隔符则检查产物存在且非空（相对项目根）
# Usage: pwsh .opencode/tests/verify-evidence-refs.ps1 [-ProjectRoot <根>]（默认当前目录）
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [string]$FootprintFile = (Join-Path $ProjectRoot '.moa/longloop/足迹.md'),
    [string]$ManifestFile = (Join-Path $PSScriptRoot 'manifest.json')
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path $FootprintFile)) { Write-Host 'verify-evidence-refs: 无足迹文件（未跑过 LongLoop），跳过'; exit 0 }
$manifest = Get-Content $ManifestFile -Raw -Encoding utf8 | ConvertFrom-Json
$re = $manifest.evidence_regex
$hasGit = Test-Path (Join-Path $ProjectRoot '.git')
$warn = 0
$err = 0
Get-Content $FootprintFile -Encoding utf8 | ForEach-Object {
    if ($_ -notmatch $re) { return }
    $ref = ($_ -replace '^- 证据：', '').Trim()
    if ($ref -match '^commit:(\S+)') {
        if (-not $hasGit) { return }
        $sha = $Matches[1]
        git -C $ProjectRoot rev-parse --verify "$sha^{commit}" *> $null
        if ($LASTEXITCODE -ne 0) { Write-Host "WARN: commit ref 不可解析（可能被 amend/squash）: $sha" -ForegroundColor Yellow; $warn++ }
    }
    elseif ($ref -match '^(smoke|pr|run):(\S+)$') {
        $val = $Matches[2]
        if ($val -match '[\\/]') {
            $path = Join-Path $ProjectRoot $val
            if (-not (Test-Path $path) -or (Get-Item $path).Length -eq 0) {
                Write-Host "FAIL: 产物不存在或为空: $val" -ForegroundColor Red; $err++
            }
        }
    }
}
if ($err -gt 0) { Write-Host "verify-evidence-refs: $err 失败 / $warn 警告" -ForegroundColor Red; exit 1 }
Write-Host "verify-evidence-refs: 通过（$warn 警告）" -ForegroundColor Green
