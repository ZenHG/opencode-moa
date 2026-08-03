# clone-core.ps1 — Minimal clone of opencode-moa core files
# Usage: pwsh ./scripts/clone-core.ps1 [-Dest <path>] [-Repo <url>]
#
# Core files retrieved:
#   README.md, opencode.json,
#   docs/README-details.md, install.ps1, install.sh
#   .opencode/agents, .opencode/commands, .opencode/skills
#   longloop/（long-loop.ps1 + server.js + package.json + templates + 2 文档）
#   .moa/界线.json, .moa/足迹模板.md, .moa/拦路虎模板.md
#   .github/moa-arch.png, .github/moa-cost.png（README 引用）

param(
    [string]$Dest = "opencode-moa-core",
    [string]$Repo  = "https://github.com/ZenHG/opencode-moa.git"
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== OpenCode MoA Minimal Clone ===" -ForegroundColor Cyan
Write-Host "Repo   : $Repo"
Write-Host "Target : $Dest`n" -ForegroundColor Gray

# ── Clone with sparse + blob filter ──
git clone --filter=blob:none --sparse --depth 1 $Repo $Dest `
    || throw "Clone failed"

Set-Location $Dest

# ── Define core paths ──
$sparsePaths = @(
    "README.md",
    "opencode.json",
    "docs/README-details.md",
    ".opencode/agents",
    ".opencode/commands",
    ".opencode/skills",
    "longloop/long-loop.ps1",
    "longloop/server.js",
    "longloop/package.json",
    "longloop/templates",
    "longloop/docs/长程自完善.md",
    "longloop/docs/LongLoop.md",
    ".moa/界线.json",
    ".moa/足迹模板.md",
    ".moa/拦路虎模板.md",
    "install.ps1",
    "install.sh",
    ".github/moa-arch.png",
    ".github/moa-cost.png"
)

git sparse-checkout set --skip-checks $sparsePaths `
    || throw "Sparse checkout failed"

Write-Host "`n--- Core files retrieved ---" -ForegroundColor Green
foreach ($p in $sparsePaths) {
    $full = Join-Path (Get-Location) $p
    if (Test-Path $full) {
        $size = if (Test-Path $full -PathType Container) {
            $(Get-ChildItem $full -Recurse -File | Measure-Object Length -Sum).Sum
        } else {
            (Get-Item $full).Length
        }
        $kb = [math]::Round($size / 1KB, 1)
        Write-Host "  [OK] $p  ($kb KB)" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] $p  (not found)" -ForegroundColor Yellow
    }
}

Write-Host "`nDone. Working directory: $(Get-Location)" -ForegroundColor Cyan
Write-Host "Run 'pwsh ./opencode-moa-core' or explore .opencode/ to start.`n" -ForegroundColor Gray