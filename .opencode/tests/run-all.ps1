# run-all.ps1 — MoA 三层验证入口
# Usage: pwsh ./tests/run-all.ps1

$ErrorActionPreference = "Continue"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  OpenCode MoA 三层验证" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

# Layer 0: 静态检查 (0 token) — 由 manifest.json 单一事实源驱动
Write-Host "--- Layer 0: 静态验证 (0 token) ---" -ForegroundColor Yellow
$manifest = Get-Content (Join-Path $scriptDir "manifest.json") -Raw -Encoding utf8 | ConvertFrom-Json
$l0 = 0
foreach ($item in $manifest.layer0) {
    $script = Join-Path $scriptDir $item.file
    if (-not (Test-Path $script)) {
        Write-Host "FAIL: manifest 登记脚本缺失: $($item.file)" -ForegroundColor Red
        $l0 = 1
        continue
    }
    & $script
    $l0 = $l0 -bor $LASTEXITCODE
}

# Layer 1: 行为引导 (人工)
Write-Host "`n--- Layer 1: 行为验证 (人工) ---" -ForegroundColor Yellow
& "$scriptDir\T1-behavioral-guide.ps1"
$l1 = $LASTEXITCODE

# Layer 2: MoA 冒烟 (人工)
Write-Host "`n--- Layer 2: MoA 冒烟验证 (人工) ---" -ForegroundColor Yellow
& "$scriptDir\T2-moa-smoke-guide.ps1"
$l2 = $LASTEXITCODE

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  Layer 0: $( if ($l0 -eq 0) {'PASS'} else {'FAIL'} )" -ForegroundColor $( if ($l0 -eq 0) {'Green'} else {'Red'} )
Write-Host "  Layer 1: 请按引导手动验证" -ForegroundColor Yellow
Write-Host "  Layer 2: 请按引导手动验证" -ForegroundColor Yellow
Write-Host "============================================`n" -ForegroundColor Cyan
