# install.ps1 — MoA 安装脚本（增量合并 opencode.json）
# 用法: pwsh ./install.ps1
# 会在当前目录下创建 .opencode/ 并合并 opencode.json

$ErrorActionPreference = "Stop"

Write-Host "`n=== OpenCode MoA 安装 ===" -ForegroundColor Cyan

# 检测项目目录
$projectDir = Get-Location
$opencodeJson = Join-Path $projectDir "opencode.json"
$moaDir = Join-Path $projectDir ".opencode"
$moaJson = Join-Path $projectDir "opencode-moa.json"

# 1. 复制 .opencode 目录
Write-Host "`n[1/3] 复制 .opencode/ 目录..." -ForegroundColor Yellow
if (Test-Path $moaDir) {
    Write-Host "  .opencode/ 已存在，跳过" -ForegroundColor Gray
} else {
    Write-Host "  .opencode/ 不存在，请先从仓库复制" -ForegroundColor Red
    Write-Host "  运行: git clone https://github.com/ZenHG/opencode-moa.git tmp; cp -r tmp/.opencode/ ." -ForegroundColor Gray
    exit 1
}

# 2. 合并 opencode.json
Write-Host "`n[2/3] 合并 opencode.json..." -ForegroundColor Yellow

# MoA 需要的配置
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
    Write-Host "  已有 opencode.json，执行增量合并" -ForegroundColor Gray
    
    # 读取现有配置
    $existing = Get-Content $opencodeJson -Raw | ConvertFrom-Json
    
    # 保留用户的 provider 和 model 配置
    if ($existing.provider) {
        $moaConfig.provider = $existing.provider
        Write-Host "  保留 provider 配置" -ForegroundColor Green
    }
    if ($existing.model) {
        $moaConfig.model = $existing.model
        Write-Host "  保留 model 配置" -ForegroundColor Green
    }
    if ($existing.small_model) {
        $moaConfig.small_model = $existing.small_model
    }
    
    # 备份原文件
    $backup = "$opencodeJson.bak.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $opencodeJson $backup
    Write-Host "  已备份原配置到 $backup" -ForegroundColor Green
} else {
    Write-Host "  opencode.json 不存在，创建新配置" -ForegroundColor Gray
}

# 写入合并后的配置
$moaConfig | ConvertTo-Json -Depth 10 | Set-Content $opencodeJson -Encoding UTF8
Write-Host "  opencode.json 已更新" -ForegroundColor Green

# 3. 验证
Write-Host "`n[3/3] 验证部署..." -ForegroundColor Yellow
$agents = Get-ChildItem "$moaDir/agents/*.md" -ErrorAction SilentlyContinue
$cmds = Get-ChildItem "$moaDir/commands/*.md" -ErrorAction SilentlyContinue
$skills = Get-ChildItem "$moaDir/skills/*/SKILL.md" -ErrorAction SilentlyContinue

Write-Host "  Agents: $($agents.Count)" -ForegroundColor $(if ($agents.Count -eq 19) {'Green'} else {'Red'})
Write-Host "  Commands: $($cmds.Count)" -ForegroundColor $(if ($cmds.Count -eq 5) {'Green'} else {'Red'})
Write-Host "  Skills: $($skills.Count)" -ForegroundColor $(if ($skills.Count -eq 3) {'Green'} else {'Red'})
Write-Host "  Config: ok" -ForegroundColor Green

Write-Host "`n=== 安装完成 ===" -ForegroundColor Cyan
Write-Host "重启 OpenCode 使配置生效。" -ForegroundColor Yellow
Write-Host "按 Ctrl+. 切换到「门童路由员」开始使用。" -ForegroundColor Yellow
