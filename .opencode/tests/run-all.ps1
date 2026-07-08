# run-all.ps1 — MoA 三层验证入口
# Usage: pwsh ./tests/run-all.ps1

$ErrorActionPreference = "Continue"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  OpenCode MoA 三层验证" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

# Layer 0: 静态检查 (0 token)
Write-Host "--- Layer 0: 静态验证 (0 token) ---" -ForegroundColor Yellow
& "$scriptDir\T0-static-verify.ps1"
$l0 = $LASTEXITCODE

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
