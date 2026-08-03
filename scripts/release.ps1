# 一键发版：推送 master 触发 Release workflow（自动打 tag + 建 Release + 传附件）。
# 正规流程 = 只 push；tag/Release 全部由 .github/workflows/release.yml 自动完成，本地从不手动 git tag。
# 前置：CHANGELOG.md 顶部已写好新版本号条目（## vX.Y.Z），且全部改动已 commit。
# 用法: pwsh scripts/release.ps1 [-NoWatch]
param(
    [switch]$NoWatch
)
$ErrorActionPreference = "Stop"

# 1. 解析版本（CHANGELOG 顶部）
$verLine = Select-String -Path CHANGELOG.md -Pattern '^## +v[0-9]+\.[0-9]+\.[0-9]+' | Select-Object -First 1
if (-not $verLine) { throw "CHANGELOG.md 顶部没有版本号条目（## vX.Y.Z），先写好再发版" }
$ver = ($verLine.Line -replace '^## +', '').Trim()
Write-Host "将发布版本: $ver" -ForegroundColor Cyan

# 2. 工作区必须干净（防止漏发未提交改动）
$dirty = git status --porcelain
if ($dirty) { throw "工作区有未提交改动，先 commit 再发版：`n$($dirty -join "`n")" }

# 3. 本地若有同名 tag 先删（手动 tag 会让 workflow 的 Create tag 步骤在 set -e 下失败）
if (git rev-parse "refs/tags/$ver" 2>$null) {
    Write-Host "⚠ 本地已存在 tag $ver（疑似手动打过）——自动删除本地 tag；remote 若有同 tag 请先 gh release view $ver 确认" -ForegroundColor Yellow
    git tag -d $ver | Out-Null
}

# 4. 推送（只推 master，不推 tag）
git push origin master
Write-Host "已推送 master，Release workflow 触发中..." -ForegroundColor Green

if ($NoWatch) { exit 0 }

# 5. 轮询本次 push 对应的 Release run，直到出结果
$sha = git rev-parse HEAD
for ($i = 1; $i -le 60; $i++) {
    Start-Sleep -Seconds 10
    $runs = gh run list --workflow release.yml --commit $sha --json databaseId,status,conclusion --limit 1 2>$null | ConvertFrom-Json
    if (-not $runs -or -not $runs[0]) { continue }
    $run = $runs[0]
    if ($run.status -in @("queued", "in_progress")) { Write-Host "  [$i] 等待 Release workflow ($($run.databaseId))..."; continue }
    if ($run.conclusion -eq "success") {
        Write-Host "✓ Release workflow 成功" -ForegroundColor Green
        gh release view $ver --json url -q '.url' | ForEach-Object { Write-Host "Release: $_" -ForegroundColor Green }
        exit 0
    }
    Write-Host "✗ Release workflow 失败: $($run.databaseId)" -ForegroundColor Red
    gh run view $run.databaseId --log-failed 2>$null | Select-Object -First 40
    exit 1
}
Write-Host "轮询超时（10 分钟），请手动检查: gh run list --workflow release.yml" -ForegroundColor Yellow
exit 1
