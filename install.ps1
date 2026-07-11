# install.ps1 — MoA 安装脚本（增量合并 opencode.json）
# 用法: pwsh ./install.ps1
# 兼容: Windows PowerShell 5.1+ / PowerShell Core 7+ (Linux/macOS)
# 需要: 先将 .opencode/ 复制到当前目录

$ErrorActionPreference = "Stop"

function Write-Step($step, $msg) {
    Write-Host "`n[$step] $msg" -ForegroundColor Yellow
}

function Write-Ok($msg) {
    Write-Host "  ✓ $msg" -ForegroundColor Green
}

function Write-Skip($msg) {
    Write-Host "  - $msg" -ForegroundColor Gray
}

function Write-Fail($msg) {
    Write-Host "  ✗ $msg" -ForegroundColor Red
}

Write-Host "`n=== OpenCode MoA 安装 ===" -ForegroundColor Cyan

$projectDir = Get-Location
$opencodeJson = Join-Path $projectDir.Path "opencode.json"
$moaDir = Join-Path $projectDir.Path ".opencode"

# 1. 检查 .opencode 目录
Write-Step "1/3" "检查 .opencode/ 目录..."
if (Test-Path $moaDir) {
    $agentCount = (Get-ChildItem "$moaDir/agents/*.md" -ErrorAction SilentlyContinue).Count
    Write-Ok ".opencode/ 存在 ($agentCount agents)"
} else {
    Write-Fail ".opencode/ 不存在"
    Write-Host "  请先克隆仓库并复制 .opencode/ 到当前目录" -ForegroundColor Gray
    Write-Host "  git clone https://github.com/ZenHG/opencode-moa.git tmp" -ForegroundColor Gray
    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        Write-Host "  xcopy tmp\.opencode .\.opencode /E /I /Y" -ForegroundColor Gray
    } else {
        Write-Host "  cp -r tmp/.opencode/ ." -ForegroundColor Gray
    }
    exit 1
}

# 2. 合并 opencode.json
Write-Step "2/3" "合并 opencode.json..."

$moaConfig = @{
    default_agent = "门童路由员"
    permission = @{
        "*" = "ask"
        bash = @{
            "*" = "ask"
            "git *" = "allow"
            "git status *" = "allow"
            "git diff *" = "allow"
            "git log *" = "allow"
            "grep *" = "allow"
            "ls *" = "allow"
            "cat *" = "allow"
            "cd *" = "allow"
            "npm run *" = "allow"
            "rm *" = "deny"
            "del *" = "deny"
        }
        task = @{
            "*" = "deny"
            "工具人" = "allow"
            "工具人-mimo" = "allow"
            "闪电侠" = "allow"
            "视觉翻译官" = "allow"
            "中级·工程" = "allow"
            "中级·创意" = "allow"
            "中级·码农" = "allow"
            "中级·融合" = "allow"
            "旗舰·架构" = "allow"
            "旗舰·规划" = "allow"
            "旗舰·工程" = "allow"
            "旗舰·融合" = "allow"
            "旗舰·实现" = "allow"
            "旗舰·质检" = "allow"
            "前端·还原" = "allow"
            "前端·逻辑" = "allow"
            "前端·动效" = "allow"
            "前端·总工" = "allow"
        }
        webfetch = "allow"
        read = @{
            "*" = "allow"
            "*.env" = "deny"
            "*.env.*" = "deny"
            "*.env.example" = "allow"
        }
    }
    agent = @{
        "中级·工程" = @{ permission = @{ "*" = "ask"; "task" = "allow"; "*_*" = "deny" } }
        "中级·创意" = @{ permission = @{ "*" = "ask"; "task" = "allow"; "*_*" = "deny" } }
        "中级·码农" = @{ permission = @{ "*" = "ask"; "task" = "allow"; "*_*" = "deny" } }
        "旗舰·架构" = @{ permission = @{ "*" = "ask"; "task" = "allow"; "*_*" = "deny" } }
        "旗舰·规划" = @{ permission = @{ "*" = "ask"; "task" = "allow"; "*_*" = "deny" } }
        "旗舰·工程" = @{ permission = @{ "*" = "ask"; "task" = "allow"; "*_*" = "deny" } }
        "前端·逻辑" = @{ permission = @{ "*" = "ask"; "task" = "allow"; "*_*" = "deny" } }
        "前端·动效" = @{ permission = @{ "*" = "ask"; "task" = "allow"; "*_*" = "deny" } }
    }
    instructions = @("AGENTS.md")
    compaction = @{ auto = $true; reserved = 10000 }
    share = "manual"
    snapshot = $true
}

if (Test-Path $opencodeJson) {
    Write-Skip "已有 opencode.json，执行增量合并"
    
    try {
        $existing = Get-Content $opencodeJson -Raw -Encoding UTF8 | ConvertFrom-Json
        
        if ($existing.provider) {
            $moaConfig | Add-Member -NotePropertyName "provider" -NotePropertyValue $existing.provider -Force
            Write-Ok "保留 provider 配置"
        }
        if ($existing.model) {
            $moaConfig | Add-Member -NotePropertyName "model" -NotePropertyValue $existing.model -Force
            Write-Ok "保留 model 配置"
        }
        if ($existing.small_model) {
            $moaConfig | Add-Member -NotePropertyName "small_model" -NotePropertyValue $existing.small_model -Force
        }
    } catch {
        Write-Host "  ⚠ 无法解析现有配置，将创建新配置" -ForegroundColor Yellow
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backup = "${opencodeJson}.bak.${timestamp}"
    Copy-Item $opencodeJson $backup -Force
    Write-Ok "已备份到 $(Split-Path $backup -Leaf)"
} else {
    Write-Skip "opencode.json 不存在，创建新配置"
}

$moaConfig | ConvertTo-Json -Depth 10 | Set-Content $opencodeJson -Encoding UTF8
Write-Ok "opencode.json 已更新"

# 2.5 检查 opencode-go provider，如有需要提示输入 key
$needKey = $true
try {
    $check = Get-Content $opencodeJson -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($check.provider -and $check.provider.'opencode-go') { $needKey = $false }
} catch {}
if ($needKey) {
    Write-Host "`n⚠️ 未检测到 opencode-go provider。19 个 agent 全部使用 opencode-go/<model>，需要 Go API Key。" -ForegroundColor Yellow
    Write-Host "  可以在 opencode.ai/auth 创建后输入（非交互环境直接跳过）。" -ForegroundColor Gray
    try { $apiKey = Read-Host "`n请输入你的 OpenCode Go API Key（留空跳过）" } catch { $apiKey = "" }
    if ($apiKey) {
        $providerBlock = @{
            npm  = "@ai-sdk/openai-compatible"
            name = "OpenCode Go (MoA)"
            options = @{
                baseURL = "https://opencode.ai/zen/go/v1"
                apiKey  = $apiKey
            }
            models = @{
                "deepseek-v4-flash" = @{ name = "deepseek-v4-flash" }
                "mimo-v2.5"        = @{ name = "mimo-v2.5" }
                "mimo-v2.5-pro"    = @{ name = "mimo-v2.5-pro" }
                "minimax-m3"       = @{ name = "minimax-m3" }
                "glm-5.2"          = @{ name = "glm-5.2" }
                "qwen3.7-max"      = @{ name = "qwen3.7-max" }
                "qwen3.7-plus"     = @{ name = "qwen3.7-plus" }
                "kimi-k2.7-code"   = @{ name = "kimi-k2.7-code" }
                "deepseek-v4-pro"  = @{ name = "deepseek-v4-pro" }
            }
        }
        $merged = Get-Content $opencodeJson -Raw -Encoding UTF8 | ConvertFrom-Json
        if (-not $merged.provider) { $merged | Add-Member -NotePropertyName 'provider' -NotePropertyValue @{} -Force }
        $merged.provider | Add-Member -NotePropertyName 'opencode-go' -NotePropertyValue $providerBlock -Force
        if (-not $merged.model) { $merged | Add-Member -NotePropertyName 'model' -NotePropertyValue 'opencode-go/deepseek-v4-flash' -Force }
        $merged | ConvertTo-Json -Depth 10 | Set-Content $opencodeJson -Encoding UTF8
        Write-Ok "opencode-go provider 已配置"
    } else {
            Write-Host "  ⚠ 未提供 key。已在 opencode.json 写入占位符 <YOUR_GO_API_KEY>。" -ForegroundColor Yellow
    Write-Host "  -> 请编辑 opencode.json 的 provider.opencode-go.apiKey 填入真实 key（opencode.ai/auth 创建），再重启 OpenCode。" -ForegroundColor Gray
    Write-Host "  -> OpenCode 仅加载 opencode.json 与系统级 ~/.config/opencode/opencode.json，不加载 user_config.json。" -ForegroundColor Gray
    $placeholderProvider = @{
        npm  = "@ai-sdk/openai-compatible"
        name = "OpenCode Go (MoA)"
        options = @{
            baseURL = "https://opencode.ai/zen/go/v1"
            apiKey  = "<YOUR_GO_API_KEY>"
        }
        models = @{
            "deepseek-v4-flash" = @{ name = "deepseek-v4-flash" }
            "mimo-v2.5"        = @{ name = "mimo-v2.5" }
            "mimo-v2.5-pro"    = @{ name = "mimo-v2.5-pro" }
            "minimax-m3"       = @{ name = "minimax-m3" }
            "glm-5.2"          = @{ name = "glm-5.2" }
            "qwen3.7-max"      = @{ name = "qwen3.7-max" }
            "qwen3.7-plus"     = @{ name = "qwen3.7-plus" }
            "kimi-k2.7-code"   = @{ name = "kimi-k2.7-code" }
            "deepseek-v4-pro"  = @{ name = "deepseek-v4-pro" }
        }
    }
    $merged = Get-Content $opencodeJson -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $merged.provider) { $merged | Add-Member -NotePropertyName 'provider' -NotePropertyValue @{} -Force }
    $merged.provider | Add-Member -NotePropertyName 'opencode-go' -NotePropertyValue $placeholderProvider -Force
    if (-not $merged.model) { $merged | Add-Member -NotePropertyName 'model' -NotePropertyValue 'opencode-go/deepseek-v4-flash' -Force }
    $merged | ConvertTo-Json -Depth 10 | Set-Content $opencodeJson -Encoding UTF8
    Write-Ok "opencode-go provider 已写入（占位符 key）"
    }

# 3. 验证
Write-Step "3/3" "验证部署..."

$agentFiles = Get-ChildItem "$moaDir/agents/*.md" -ErrorAction SilentlyContinue
$cmdFiles = Get-ChildItem "$moaDir/commands/*.md" -ErrorAction SilentlyContinue
$skillFiles = Get-ChildItem "$moaDir/skills/*/SKILL.md" -ErrorAction SilentlyContinue

$agentCount = if ($agentFiles) { $agentFiles.Count } else { 0 }
$cmdCount = if ($cmdFiles) { $cmdFiles.Count } else { 0 }
$skillCount = if ($skillFiles) { $skillFiles.Count } else { 0 }

if ($agentCount -eq 19) { Write-Ok "Agents: 19" } else { Write-Fail "Agents: $agentCount (期望 19)" }
if ($cmdCount -eq 5) { Write-Ok "Commands: 5" } else { Write-Fail "Commands: $cmdCount (期望 5)" }
if ($skillCount -eq 3) { Write-Ok "Skills: 3" } else { Write-Fail "Skills: $skillCount (期望 3)" }
Write-Ok "Config: ok"

Write-Host "`n=== 安装完成 ===" -ForegroundColor Cyan
Write-Host "重启 OpenCode 使配置生效。" -ForegroundColor Yellow
Write-Host "按 Tab 循环切换 agent（Win 桌面端亦可用 Ctrl+.）切换到「门童路由员」开始使用。" -ForegroundColor Yellow
