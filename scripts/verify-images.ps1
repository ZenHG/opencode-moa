# verify-images.ps1 — 校验 7 个 README 的图片锚点规范
# 规范:
#  1. 每个 README 必须有 ARCH-IMG 锚点(顶部架构图) 和 COST-IMG 锚点(降本卡)
#  2. 图片必须位于代码块(``` 围栏)之外, 不能在示意图代码块内
#  3. 架构图必须用 moa-arch*, 降本卡必须用 moa-cost*, 主视觉 opengraph 不得进 README
# Exit: 0 pass, 1 fail

$ErrorActionPreference = "Continue"
$base = Split-Path (Split-Path $MyInvocation.MyCommand.Path)
$readmes = @("README.md","README.zh.md","README.de.md","README.es.md","README.fr.md","README.ja.md","README.ko.md")
$pass = 0; $fail = 0
function Check($name, $ok, $detail = "") {
  if ($ok) { $script:pass++; Write-Host "  [PASS] $name" -ForegroundColor Green }
  else { $script:fail++; Write-Host "  [FAIL] $name $detail" -ForegroundColor Red }
}

foreach ($rf in $readmes) {
  $p = Join-Path $base $rf
  if (-not (Test-Path $p)) { Check "$rf exists" $false; continue }
  $lines = Get-Content $p -Encoding utf8
  $text = $lines -join "`n"

  # 1. 锚点存在
  $hasArchAnchor = $text -match '<!--\s*ARCH-IMG\s*-->'
  $hasCostAnchor = $text -match '<!--\s*COST-IMG\s*-->'
  Check "$rf : ARCH-IMG 锚点" $hasArchAnchor
  Check "$rf : COST-IMG 锚点" $hasCostAnchor

  # 2. 主视觉不得进 README
  $opengraphRef = $lines | Where-Object { $_ -match '!\[.*\]\(.*opengraph' }
  Check "$rf : 不含主视觉(opengraph)" ($opengraphRef.Count -eq 0) " [$($opengraphRef.Count) 处]"

  # 3. 图片必须在代码块外
  $inFence = $false
  $bad = @()
  foreach ($line in $lines) {
    if ($line -match '^\s*```') { $inFence = -not $inFence; continue }
    if ($inFence -and $line -match '!\[.*\]\(.*\.png\)') { $bad += $line.Trim() }
  }
  Check "$rf : 无图片位于代码块内" ($bad.Count -eq 0) " [$($bad -join '; ')]"

  # 4. 架构图用 moa-arch, 降本卡用 moa-cost
  $archOk = ($lines | Where-Object { $_ -match 'moa-arch' }).Count -ge 1
  $costOk = ($lines | Where-Object { $_ -match 'moa-cost' }).Count -ge 1
  Check "$rf : 引用 moa-arch(架构图)" $archOk
  Check "$rf : 引用 moa-cost(降本卡)" $costOk
}

Write-Host "`n==============================" -ForegroundColor Yellow
Write-Host "  PASS: $pass  FAIL: $fail" -ForegroundColor $(if ($fail -eq 0) {'Green'} else {'Red'})
Write-Host "==============================" -ForegroundColor Yellow
exit ($fail -gt 0)
