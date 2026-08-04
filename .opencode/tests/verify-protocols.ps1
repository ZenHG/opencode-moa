# verify-protocols.ps1 — 按 agent-protocol-matrix.json 断言各 agent 输出协议节（0 token）
# Usage: pwsh .opencode/tests/verify-protocols.ps1
param(
    [string]$AgentsDir = (Join-Path $PSScriptRoot '..\..\.opencode\agents'),
    [string]$MatrixFile = (Join-Path $PSScriptRoot 'agent-protocol-matrix.json')
)
$ErrorActionPreference = 'Stop'
$matrix = Get-Content $MatrixFile -Raw -Encoding utf8 | ConvertFrom-Json
$fail = 0
$count = 0
Get-ChildItem $AgentsDir -Filter *.md | Sort-Object Name | ForEach-Object {
    $count++
    $name = $_.BaseName
    if (-not ($matrix.agents.PSObject.Properties.Name -contains $name)) {
        Write-Host "FAIL $name : 矩阵缺该 agent 条目" -ForegroundColor Red
        $fail++
        return
    }
    $entry = $matrix.agents.$name
    $text = Get-Content $_.FullName -Raw -Encoding utf8
    $body = [regex]::Replace($text, '(?s)\A---\r?\n.*?\r?\n---\r?\n', '')
    foreach ($marker in @($entry.protocol)) {
        if ($entry.conditional -contains $marker) { continue }
        $pat = '(?m)^' + [regex]::Escape($marker) + '$'
        if ($body -notmatch $pat) {
            Write-Host "FAIL $name : 缺必选协议节 $marker" -ForegroundColor Red
            $fail++
        }
    }
    foreach ($pat in @($entry.inline)) {
        if ($body -notmatch $pat) {
            Write-Host "FAIL $name : 缺行内协议 $pat" -ForegroundColor Red
            $fail++
        }
    }
}
if ($fail -gt 0) { Write-Host "verify-protocols: $fail 处失败（$count agents）" -ForegroundColor Red; exit 1 }
Write-Host "verify-protocols: 全部通过（$count agents）" -ForegroundColor Green
