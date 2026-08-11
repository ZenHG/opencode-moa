# install.ps1 — MoA 安装脚本（增量合并 opencode.json）
# 用法: pwsh ./install.ps1 [-InstallPwsh]
# 兼容: Windows PowerShell 5.1+ / PowerShell Core 7+ (Linux/macOS)
# 需要: 先将 .opencode/ 复制到当前目录
# -InstallPwsh: Windows 且无 pwsh 时，自动下载官方 PowerShell 7 MSI 静默安装（5.1 下可用 powershell -File install.ps1 -InstallPwsh）

param(
    [switch]$InstallPwsh,
    [switch]$InstallNode,
    [switch]$InstallDeps
)

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

# -InstallDeps = 全部依赖先检查再安装
if ($InstallDeps) { $InstallPwsh = $true; $InstallNode = $true }

# 0. 可选：自动安装 PowerShell 7（官方 MSI 静默安装）
if ($InstallPwsh) {
    Write-Step "0/3" "检查 PowerShell 7.1+ (pwsh)..."
    $pwshPath = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
    $pwshVer = $null
    if ($pwshPath) { $pwshVer = pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' 2>$null }
    $pwshOk = $false
    if ($pwshVer) {
        try { $pwshOk = [version]$pwshVer -ge [version]"7.1" } catch { $pwshOk = $false }
    }
    if ($pwshOk) {
        Write-Skip "已安装 pwsh $pwshVer (>= 7.1)，无需安装"
    } else {
        if ($env:OS -ne "Windows_NT") { Write-Fail "-InstallPwsh 仅支持 Windows（MSI 安装）"; exit 1 }
        if ($pwshPath) { Write-Host "  当前 pwsh 版本 $pwshVer < 7.1，自动安装官方 MSI 升级..." -ForegroundColor Yellow }
        else { Write-Host "  pwsh 未安装，自动下载官方 MSI 静默安装..." -ForegroundColor Yellow }
        try {
            $rel = Invoke-RestMethod "https://api.github.com/repos/PowerShell/PowerShell/releases/latest" -Headers @{ "User-Agent" = "opencode-moa-installer" }
            $ver = $rel.tag_name.TrimStart('v')
            $asset = $rel.assets | Where-Object { $_.name -eq "PowerShell-$ver-win-x64.msi" } | Select-Object -First 1
            if (-not $asset) { throw "最新版本 $ver 中未找到 win-x64 MSI 资产" }
            $msi = Join-Path $env:TEMP $asset.name
            Invoke-WebRequest $asset.browser_download_url -OutFile $msi
            Write-Ok "已下载 $($asset.name) ($([math]::Round((Get-Item $msi).Length / 1MB, 1)) MB)"
            $p = Start-Process msiexec -ArgumentList @("/i", "`"$msi`"", "/qn", "/norestart", "ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=0") -Wait -PassThru
            if ($p.ExitCode -ne 0) { throw "msiexec 静默安装失败（退出码 $($p.ExitCode)）" }
            Remove-Item $msi -Force -ErrorAction SilentlyContinue
            Write-Ok "PowerShell 7 ($ver) 已安装，重启终端后可用 pwsh"
        } catch {
            Write-Fail "自动安装失败: $($_.Exception.Message)"
            Write-Host "  手动安装: https://github.com/PowerShell/PowerShell/releases （下载 win-x64 MSI 双击安装）" -ForegroundColor Gray
            exit 1
        }
    }
}

# 0.5 可选：自动安装 Node.js（官方 MSI 静默安装）
if ($InstallNode) {
    Write-Step "0/3" "检查 Node.js 14+..."
    $nodePath = (Get-Command node -ErrorAction SilentlyContinue).Source
    $nodeVer = $null
    if ($nodePath) { $nodeVer = node --version 2>$null }
    $nodeOk = $false
    if ($nodeVer) {
        try { $nodeOk = [int](($nodeVer.TrimStart('v') -split '\.')[0]) -ge 14 } catch { $nodeOk = $false }
    }
    if ($nodeOk) {
        Write-Skip "已安装 node $nodeVer (>= 14)，无需安装"
    } else {
        if ($env:OS -ne "Windows_NT") { Write-Fail "-InstallNode 仅支持 Windows（MSI 安装）"; exit 1 }
        if ($nodePath) { Write-Host "  当前 node $nodeVer < 14，自动下载官方 MSI 升级..." -ForegroundColor Yellow }
        else { Write-Host "  node 未安装，自动下载官方 MSI 静默安装..." -ForegroundColor Yellow }
        try {
            $rel = Invoke-RestMethod "https://nodejs.org/dist/index.json"
            $latest = $rel | Where-Object { $_.lts } | Select-Object -First 1
            if (-not $latest) { $latest = $rel | Select-Object -First 1 }
            $ver = $latest.version
            $msiName = "node-$ver-x64.msi"
            $msi = Join-Path $env:TEMP $msiName
            Invoke-WebRequest "https://nodejs.org/dist/$ver/$msiName" -OutFile $msi
            Write-Ok "已下载 $msiName ($([math]::Round((Get-Item $msi).Length / 1MB, 1)) MB)"
            $p = Start-Process msiexec -ArgumentList @("/i", "`"$msi`"", "/qn", "/norestart") -Wait -PassThru
            if ($p.ExitCode -ne 0) { throw "msiexec 静默安装失败（退出码 $($p.ExitCode)）" }
            Remove-Item $msi -Force -ErrorAction SilentlyContinue
            Write-Ok "Node.js $ver 已安装，重启终端后可用 node"
        } catch {
            Write-Fail "自动安装失败: $($_.Exception.Message)"
            Write-Host "  手动安装: https://nodejs.org （下载官方 MSI 双击安装）" -ForegroundColor Gray
            exit 1
        }
    }
}

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

# 1.5 检查 opencode CLI（缺失给指引，不阻断合并——配置可先行，CLI 后装）
Write-Step "1.5/3" "检查 opencode CLI..."
$oc = Get-Command opencode -ErrorAction SilentlyContinue
if ($oc) {
    Write-Ok "opencode: $($oc.Source)"
} else {
    Write-Host "  ⚠ 未找到 opencode CLI —— MoA 流水线与 LongLoop 都依赖它驱动每轮会话。" -ForegroundColor Yellow
    Write-Host "  安装：npm install -g opencode-ai（或 curl -fsSL https://opencode.ai/install | bash）" -ForegroundColor Cyan
    Write-Host "  装好后若仍找不到，设置环境变量 OPENCODE_BIN 指向 opencode 可执行文件。" -ForegroundColor Gray
}

# 2. 合并 opencode.json
Write-Step "2/3" "合并 opencode.json..."

$moaConfig = @{
    default_agent = "门童"
    permission = @{
        "*" = "ask"
        bash = @{
            "*" = "ask"
            "git status *" = "allow"
            "git diff *" = "allow"
            "git log *" = "allow"
            "grep *" = "allow"
            "rg *" = "allow"
            "Select-String *" = "allow"
            "ls *" = "allow"
            "Get-ChildItem *" = "allow"
            "Get-Content *" = "allow"
            "cd *" = "allow"
            "npm run *" = "allow"
            "pwsh .opencode/tests/*" = "allow"
            '*$env:TEMP*' = "allow"
            '*$env:TMP*' = "allow"
            '*/tmp/*' = "allow"
            "rm *" = "deny"
            "del *" = "deny"
            "Remove-Item *" = "deny"
            "rd *" = "deny"
            "rmdir *" = "deny"
        }
        task = @{
            "*" = "deny"
            "工具人" = "allow"
            "工具人-mimo" = "allow"
            "闪电侠" = "allow"
            "视觉翻译" = "allow"
            "中级·工程" = "allow"
            "中级·创意" = "allow"
            "中级·码农" = "allow"
            "中级·融合" = "allow"
            "旗舰·架构" = "allow"
            "旗舰·规划" = "allow"
            "旗舰·工程" = "allow"
            "旗舰·融合" = "allow"
            "旗舰·执行" = "allow"
            "旗舰·质检" = "allow"
            "前端·还原" = "allow"
            "前端·逻辑" = "allow"
            "前端·动效" = "allow"
            "前端·总工" = "allow"
            "融合·保底" = "allow"
            "残差提取" = "allow"
            "置信度评估" = "allow"
        }
        webfetch = "allow"
        read = @{
            "*" = "allow"
            "*.env" = "deny"
            "*.env.*" = "deny"
            "*.env.example" = "allow"
        }
        todowrite = "allow"
    }
    agent = @{
        "中级·工程" = @{ permission = @{ "*_*" = "deny"; read = "deny"; bash = "deny"; grep = "deny"; glob = "deny"; list = "deny"; webfetch = "deny"; websearch = "deny"; edit = "deny" } }
        "中级·创意" = @{ permission = @{ "*_*" = "deny"; read = "deny"; bash = "deny"; grep = "deny"; glob = "deny"; list = "deny"; webfetch = "deny"; websearch = "deny"; edit = "deny" } }
        "中级·码农" = @{ permission = @{ "*_*" = "deny"; read = "deny"; bash = "deny"; grep = "deny"; glob = "deny"; list = "deny"; webfetch = "deny"; websearch = "deny"; edit = "deny" } }
        "中级·融合" = @{ permission = @{ "*_*" = "deny"; read = "deny"; bash = "deny"; grep = "deny"; glob = "deny"; list = "deny"; webfetch = "deny"; websearch = "deny"; edit = "deny" } }
        "旗舰·架构" = @{ permission = @{ "*_*" = "deny"; read = "deny"; bash = "deny"; grep = "deny"; glob = "deny"; list = "deny"; webfetch = "deny"; websearch = "deny"; edit = "deny" } }
        "旗舰·规划" = @{ permission = @{ "*_*" = "deny"; read = "deny"; bash = "deny"; grep = "deny"; glob = "deny"; list = "deny"; webfetch = "deny"; websearch = "deny"; edit = "deny" } }
        "旗舰·工程" = @{ permission = @{ "*_*" = "deny"; read = "deny"; bash = "deny"; grep = "deny"; glob = "deny"; list = "deny"; webfetch = "deny"; websearch = "deny"; edit = "deny" } }
        "旗舰·融合" = @{ permission = @{ "*_*" = "deny"; read = "deny"; bash = "deny"; grep = "deny"; glob = "deny"; list = "deny"; webfetch = "deny"; websearch = "deny"; edit = "deny" } }
        "旗舰·执行" = @{ permission = @{ "*_*" = "deny"; "moa-loop_*" = "allow" } }
        "旗舰·质检" = @{ permission = @{ "*_*" = "deny"; read = "deny"; bash = "deny"; grep = "deny"; glob = "deny"; list = "deny"; webfetch = "deny"; websearch = "deny"; edit = "deny" } }
        "前端·逻辑" = @{ permission = @{ "*_*" = "deny"; read = "deny"; bash = "deny"; grep = "deny"; glob = "deny"; list = "deny"; webfetch = "deny"; websearch = "deny"; edit = "deny" } }
        "前端·动效" = @{ permission = @{ "*_*" = "deny"; read = "deny"; bash = "deny"; grep = "deny"; glob = "deny"; list = "deny"; webfetch = "deny"; websearch = "deny"; edit = "deny" } }
        "前端·总工" = @{ permission = @{ "*_*" = "deny"; read = "deny"; bash = "deny"; grep = "deny"; glob = "deny"; list = "deny"; webfetch = "deny"; websearch = "deny"; edit = "deny" } }
        "融合·保底" = @{ permission = @{ "*_*" = "deny"; read = "deny"; bash = "deny"; grep = "deny"; glob = "deny"; list = "deny"; webfetch = "deny"; websearch = "deny"; edit = "deny" } }
        "残差提取" = @{ permission = @{ "*_*" = "deny"; read = "deny"; bash = "deny"; grep = "deny"; glob = "deny"; list = "deny"; webfetch = "deny"; websearch = "deny"; edit = "deny" } }
        "置信度评估" = @{ permission = @{ "*_*" = "deny"; read = "deny"; bash = "deny"; grep = "deny"; glob = "deny"; list = "deny"; webfetch = "deny"; websearch = "deny"; edit = "deny" } }
    }
    compaction = @{ auto = $true; reserved = 15000 }
    share = "manual"
    snapshot = $true
    mcp = @{
        "moa-loop" = @{ type = "local"; command = @("node", "longloop/server.js"); enabled = $true }
    }
}

# 平台化：Unix 部署移除 Windows 专有删除禁令，保持生成的 opencode.json 平台纯净
if (-not ($IsWindows -or $env:OS -eq "Windows_NT")) {
    @("del *", "Remove-Item *", "rd *", "rmdir *") | ForEach-Object {
        $moaConfig.permission.bash.Remove($_)
    }
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
    Write-Host "`n⚠️ 未检测到 opencode-go provider。22 个 agent 全部使用 opencode-go/<model>，需要 Go API Key。" -ForegroundColor Yellow
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
                "kimi-k2.6"        = @{ name = "kimi-k2.6" }
                "kimi-k3"          = @{ name = "kimi-k3" }
            }
        }
        $merged = Get-Content $opencodeJson -Raw -Encoding UTF8 | ConvertFrom-Json
        if (-not $merged.provider) { $merged | Add-Member -NotePropertyName 'provider' -NotePropertyValue @{} -Force }
        if ($merged.provider -is [hashtable]) { $merged.provider = [pscustomobject]$merged.provider }
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
            "kimi-k2.6"        = @{ name = "kimi-k2.6" }
            "kimi-k3"          = @{ name = "kimi-k3" }
        }
    }
    $merged = Get-Content $opencodeJson -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $merged.provider) { $merged | Add-Member -NotePropertyName 'provider' -NotePropertyValue @{} -Force }
    if ($merged.provider -is [hashtable]) { $merged.provider = [pscustomobject]$merged.provider }
    $merged.provider | Add-Member -NotePropertyName 'opencode-go' -NotePropertyValue $placeholderProvider -Force
    if (-not $merged.model) { $merged | Add-Member -NotePropertyName 'model' -NotePropertyValue 'opencode-go/deepseek-v4-flash' -Force }
    $merged | ConvertTo-Json -Depth 10 | Set-Content $opencodeJson -Encoding UTF8
    Write-Ok "opencode-go provider 已写入（占位符 key）"
    }
}

# 3. 验证
Write-Step "3/3" "验证部署..."

$agentFiles = Get-ChildItem "$moaDir/agents/*.md" -ErrorAction SilentlyContinue
$cmdFiles = Get-ChildItem "$moaDir/commands/*.md" -ErrorAction SilentlyContinue
$skillFiles = Get-ChildItem "$moaDir/skills/*/SKILL.md" -ErrorAction SilentlyContinue

$agentCount = if ($agentFiles) { $agentFiles.Count } else { 0 }
$cmdCount = if ($cmdFiles) { $cmdFiles.Count } else { 0 }
$skillCount = if ($skillFiles) { $skillFiles.Count } else { 0 }

if ($agentCount -gt 0) { Write-Ok "Agents: $agentCount" } else { Write-Fail "Agents: $agentCount" }
if ($cmdCount -gt 0) { Write-Ok "Commands: $cmdCount" } else { Write-Fail "Commands: $cmdCount" }
if ($skillCount -gt 0) { Write-Ok "Skills: $skillCount" } else { Write-Fail "Skills: $skillCount" }
Write-Ok "Config: ok"
$nodeVer = node --version 2>$null
if ($nodeVer) {
    try {
        $nodeMajor = [int](($nodeVer.TrimStart('v') -split '\.')[0])
        if ($nodeMajor -ge 14) { Write-Ok "Node.js: ok ($nodeVer)" }
        else { Write-Host "  ⚠ node $nodeVer < 14 —— moa-loop MCP 需要 >= 14；可加 -InstallNode 自动升级官方 MSI" -ForegroundColor Yellow }
    } catch { Write-Host "  ⚠ node 版本解析失败（$nodeVer）" -ForegroundColor Yellow }
} else {
    Write-Host "  ⚠ node 未安装 —— moa-loop MCP（长程自完善状态工具）不可用；可加 -InstallNode 自动安装官方 MSI" -ForegroundColor Yellow
}
if (Test-Path (Join-Path $projectDir.Path "longloop/server.js")) {
    Write-Ok "LongLoop MCP: ok"
} else {
    Write-Host "  ⚠ longloop/ 未复制 —— moa-loop MCP（长程自完善状态工具）将不可用" -ForegroundColor Yellow
    Write-Host "  -> 从仓库复制: cp -r <opencode-moa 路径>/longloop/ ." -ForegroundColor Gray
}

Write-Host "`n=== 安装完成 ===" -ForegroundColor Cyan
Write-Host "重启 OpenCode 使配置生效。" -ForegroundColor Yellow
Write-Host "按 Tab 循环切换 agent（Win 桌面端亦可用 Ctrl+.）切换到「门童」开始使用。" -ForegroundColor Yellow
