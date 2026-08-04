# verify-frontmatter.ps1 — agent frontmatter 语法断言（0 token；管语法，一致性归 T0 expectedModels）
# Usage: pwsh .opencode/tests/verify-frontmatter.ps1
param(
    [string]$AgentsDir = (Join-Path $PSScriptRoot '..\..\.opencode\agents')
)
$ErrorActionPreference = 'Stop'
$fail = 0
$count = 0
Get-ChildItem $AgentsDir -Filter *.md | Sort-Object Name | ForEach-Object {
    $count++
    $text = Get-Content $_.FullName -Raw -Encoding utf8
    if ($text -notmatch '(?s)\A---\r?\n(.*?)\r?\n---') {
        Write-Host "FAIL $($_.Name) : 缺 frontmatter" -ForegroundColor Red
        $fail++
        return
    }
    $fm = $Matches[1]
    $model = [regex]::Match($fm, '(?m)^model:\s*(\S+)').Groups[1].Value
    if (-not $model) {
        Write-Host "FAIL $($_.Name) : 缺 model" -ForegroundColor Red; $fail++
    }
    elseif ($model -notmatch '^[^/\s]+/[^/\s]+$') {
        Write-Host "FAIL $($_.Name) : model 格式非法（须 provider/model）: $model" -ForegroundColor Red; $fail++
    }
    $temp = [regex]::Match($fm, '(?m)^temperature:\s*(\S+)').Groups[1].Value
    if ($temp -and $temp -notmatch '^\d+(\.\d+)?$') {
        Write-Host "FAIL $($_.Name) : temperature 非数值: $temp" -ForegroundColor Red; $fail++
    }
    $hidden = [regex]::Match($fm, '(?m)^hidden:\s*(\S+)')
    if ($hidden.Success -and $hidden.Groups[1].Value -notin @('true', 'false')) {
        Write-Host "FAIL $($_.Name) : hidden 非布尔: $($hidden.Groups[1].Value)" -ForegroundColor Red; $fail++
    }
}
if ($fail -gt 0) { Write-Host "verify-frontmatter: $fail 处失败（$count agents）" -ForegroundColor Red; exit 1 }
Write-Host "verify-frontmatter: 全部通过（$count agents）" -ForegroundColor Green
