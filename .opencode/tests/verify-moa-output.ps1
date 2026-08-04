# verify-moa-output.ps1 — MoA 冒烟产物断言（0 token）：按角色断言输出协议节齐全 + 红线/验收非空
# Usage: pwsh .opencode/tests/verify-moa-output.ps1 <产物文件> [-Role <agent名>]（默认 旗舰·融合）
param(
    [Parameter(Mandatory = $true)][string]$File,
    [string]$Role = '旗舰·融合',
    [string]$MatrixFile = (Join-Path $PSScriptRoot 'agent-protocol-matrix.json')
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path $File)) { Write-Host "FAIL : 产物文件不存在 $File" -ForegroundColor Red; exit 2 }
$matrix = Get-Content $MatrixFile -Raw -Encoding utf8 | ConvertFrom-Json
if (-not ($matrix.agents.PSObject.Properties.Name -contains $Role)) {
    Write-Host "FAIL : 未知角色 $Role" -ForegroundColor Red; exit 2
}
$entry = $matrix.agents.$Role
$text = Get-Content $File -Raw -Encoding utf8
$fail = 0
foreach ($marker in @($entry.protocol)) {
    if ($entry.conditional -contains $marker) { continue }
    if ($text -notmatch ('(?m)^' + [regex]::Escape($marker) + '$')) {
        Write-Host "FAIL : 产物缺节 $marker" -ForegroundColor Red; $fail++
    }
}
foreach ($must in @('---红线---', '---验收标准---')) {
    if ($entry.protocol -contains $must) {
        $m = [regex]::Match($text, ('(?s)' + [regex]::Escape($must) + '\r?\n(.*?)(?=\r?\n---|\z)'))
        if (-not $m.Success -or [string]::IsNullOrWhiteSpace($m.Groups[1].Value)) {
            Write-Host "FAIL : $must 节为空" -ForegroundColor Red; $fail++
        }
    }
}
if ($fail -gt 0) { Write-Host "verify-moa-output: $fail 处失败（$Role）" -ForegroundColor Red; exit 1 }
Write-Host "verify-moa-output: 通过（$Role）" -ForegroundColor Green
