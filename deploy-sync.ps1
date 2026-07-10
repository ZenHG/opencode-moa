# deploy-sync.ps1 — 双平台同步：GitHub + SkillHub
# 用法：
#   pwsh ./deploy-sync.ps1                 # 完整流程（git commit + push + SkillHub 上传）
#   pwsh ./deploy-sync.ps1 -SkipGit         # 只上传 SkillHub
#   pwsh ./deploy-sync.ps1 -SkipSkillHub    # 只 git commit + push
#   pwsh ./deploy-sync.ps1 -DryRun          # 预览 SkillHub 提交内容，不实际提交
#   pwsh ./deploy-sync.ps1 -SkillDir path   # 指定要上传的 skill 目录（默认 .opencode/skills/opencode-moa）

param(
    [switch]$SkipGit,
    [switch]$SkipSkillHub,
    [switch]$DryRun,
    [string]$SkillDir
)

$ErrorActionPreference = "Stop"
$RepoRoot = $PSScriptRoot

function Write-Step($n, $msg) { Write-Host "`n[$n] $msg" -ForegroundColor Cyan }
function Write-OK($msg)       { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Fail($msg)     { Write-Host "  [FAIL] $msg" -ForegroundColor Red }
function Write-Warn($msg)     { Write-Host "  [!] $msg" -ForegroundColor Yellow }

# ── 跨平台临时目录 ──
if ($env:TEMP) { $TmpBase = $env:TEMP }
elseif ($env:TMPDIR) { $TmpBase = $env:TMPDIR }
else { $TmpBase = "/tmp" }
$UploadDir = Join-Path $TmpBase "skillhub-upload"

# ── SkillHub CLI 模块路径解析（优先级：环境变量 > npm 全局 > npx）──
function Get-SkillHubCli {
    if ($env:SKILLHUB_CLI -and (Test-Path $env:SKILLHUB_CLI)) { return $env:SKILLHUB_CLI }
    $globalRoot = (& npm root -g 2>$null)
    if ($globalRoot) {
        $candidate = Join-Path $globalRoot "@xhs/skillhub-upload/cli/index.mjs"
        if (Test-Path $candidate) { return $candidate }
    }
    return $null
}

function ConvertTo-FileUrl($p) { "file:///" + ($p -replace '\\', '/') }

# 通过临时 .mjs 调用 SkillHub CLI，避免 node -e 的引号嵌套问题
function Invoke-SkillHub {
    param([string[]]$CliArgs)
    $cli = Get-SkillHubCli
    if (-not $cli) {
        Write-Warn "未找到 SkillHub CLI（设置 `$env:SKILLHUB_CLI 或 npm i -g @xhs/skillhub-upload）"
        return $null
    }
    $mjs = Join-Path $UploadDir ("skillhub-run-" + [guid]::NewGuid().ToString("N") + ".mjs")
    $url = ConvertTo-FileUrl $cli
    $code = @"
import { main } from '$url';
const out = { write: (s) => process.stdout.write(String(s)) };
const exitCode = await main(process.argv.slice(2), process.env, { out });
process.exit(typeof exitCode === 'number' ? exitCode : 0);
"@
    Set-Content -Path $mjs -Value $code -Encoding UTF8
    try {
        $output = & node $mjs @CliArgs 2>&1
        $exit = $LASTEXITCODE
        return [PSCustomObject]@{ Output = ($output -join "`n"); ExitCode = $exit }
    } finally {
        Remove-Item $mjs -Force -ErrorAction SilentlyContinue
    }
}

# ── Step 1：定位要上传的 skill ──
Write-Step 1 "检查 SkillHub 上传目标"
if (-not $SkillDir) { $SkillDir = Join-Path $RepoRoot ".opencode/skills/opencode-moa" }
$SkillSource = Join-Path $SkillDir "SKILL.md"
$doSkillHub = -not $SkipSkillHub
if ($doSkillHub -and -not (Test-Path $SkillSource)) {
    Write-Warn "找不到 $SkillSource，跳过 SkillHub 上传（用 -SkillDir 指定其它 skill）"
    $doSkillHub = $false
} elseif ($doSkillHub) {
    Write-OK "SKILL.md 存在: $SkillSource"
}

# ── Step 2：同步到上传目录 ──
if ($doSkillHub) {
    Write-Step 2 "同步到上传目录"
    New-Item -ItemType Directory -Force -Path $UploadDir | Out-Null
    Copy-Item $SkillSource (Join-Path $UploadDir "SKILL.md") -Force
    Write-OK "已复制到 $UploadDir"
}

# ── Step 3：SkillHub 上传 ──
if ($doSkillHub) {
    Write-Step 3 "SkillHub 上传"
    $whoami = Invoke-SkillHub -CliArgs "whoami"
    $loggedIn = $whoami -and $whoami.ExitCode -eq 0 -and ($whoami.Output -match '"loggedIn"\s*:\s*true')
    if (-not $loggedIn) {
        Write-Warn "未登录 SkillHub，尝试登录..."
        $login = Invoke-SkillHub -CliArgs "login", "--agent"
        if ($login -and $login.ExitCode -eq 0 -and ($login.Output -match 'PROMPT:(\{.*\})')) {
            try { $pd = $Matches[1] | ConvertFrom-Json } catch { $pd = $null }
            if ($pd) {
                Write-Host ""
                Write-Host "请用浏览器打开授权链接：" -ForegroundColor Yellow
                Write-Host $pd.authorizeUrl -ForegroundColor White
                Write-Host "授权码：$($pd.userCode)" -ForegroundColor White
                Write-Host "有效期：$([math]::Floor($pd.expiresInSeconds / 60)) 分钟" -ForegroundColor White
                Write-Host ""
                Read-Host "完成授权后按回车继续"
            }
        } else {
            Write-Fail "SkillHub 登录失败，跳过上传"; $doSkillHub = $false
        }
    } else {
        Write-OK "已登录 SkillHub"
    }
}

if ($doSkillHub) {
    $publishArgs = @("publish", (ConvertTo-FileUrl $UploadDir), "--agent", "--source", "original", "--tag", "效率工具")
    if ($DryRun) {
        Write-Warn "Dry-run 模式，预览提交内容..."
        $r = Invoke-SkillHub -CliArgs ($publishArgs + "--dry-run")
        Write-Host ($r.Output)
    } else {
        $confirm = Read-Host "`n确认上传到 SkillHub？(y/n)"
        if ($confirm -eq 'y') {
            $r = Invoke-SkillHub -CliArgs $publishArgs
            Write-Host ($r.Output)
            Write-OK "SkillHub 上传完成"
        } else {
            Write-Warn "已跳过 SkillHub 上传"
        }
    }
}

# ── Step 4：Git 操作 ──
if (-not $SkipGit) {
    Write-Step 4 "Git 提交并推送"
    Push-Location $RepoRoot
    try {
        $status = (git status --short 2>&1)
        if (-not $status) {
            Write-OK "没有需要提交的变更"
        } else {
            $status | ForEach-Object { Write-Host "    $_" }
            $commitMsg = Read-Host "`n提交信息 (回车使用默认: 'sync: update')"
            if (-not $commitMsg) { $commitMsg = "sync: update" }
            git add -A
            git commit -m $commitMsg 2>&1 | Out-Null
            Write-OK "已提交: $commitMsg"
            $pushConfirm = Read-Host "推送到 GitHub？(y/n)"
            if ($pushConfirm -eq 'y') {
                git push 2>&1
                Write-OK "已推送到 GitHub"
            } else {
                Write-Warn "已跳过 GitHub 推送"
            }
        }
    } finally {
        Pop-Location
    }
}

Write-Host "`n═══════════════════════════════════════" -ForegroundColor Green
Write-Host "  同步完成" -ForegroundColor Green
Write-Host "═══════════════════════════════════════" -ForegroundColor Green
