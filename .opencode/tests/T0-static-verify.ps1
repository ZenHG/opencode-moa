# T0-static-verify.ps1 — 99 项静态检查 (0 token)
# 验证: 模型分配、权限分组、基础设施

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$base = Join-Path (Split-Path (Split-Path $scriptDir)) ""
$agentDir = Join-Path $base ".opencode/agents"
$cmdDir  = Join-Path $base ".opencode/commands"
$skillDir = Join-Path $base ".opencode/skills"

$pass = 0; $fail = 0

function Check($name, $ok) {
    if ($ok) { $script:pass++; Write-Host "  [PASS] $name" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $name" -ForegroundColor Red }
}

Write-Host "`n=== 基础设施 ===" -ForegroundColor Yellow
Check "agents dir" (Test-Path "$agentDir")
Check "commands dir" (Test-Path "$cmdDir")
Check "skills dir" (Test-Path "$skillDir")
Check "opencode.json" (Test-Path (Join-Path $base "opencode.json"))

Write-Host "`n=== Agent count ===" -ForegroundColor Yellow
$agents = Get-ChildItem "$agentDir/*.md" -ErrorAction SilentlyContinue
Check "Agent files = 22" ($agents.Count -eq 22)

Write-Host "`n=== Command count ===" -ForegroundColor Yellow
$cmds = Get-ChildItem "$cmdDir/*.md" -ErrorAction SilentlyContinue
Check "Command files = 5" ($cmds.Count -eq 5)

Write-Host "`n=== Skill count ===" -ForegroundColor Yellow
$skills = Get-ChildItem "$skillDir/*/SKILL.md" -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch "[/\\]opencode-moa[/\\]SKILL\.md$" }
Check "Skill files = $($skills.Count) (excl. meta)" ($skills.Count -ge 1)

Write-Host "`n=== Command prefix ===" -ForegroundColor Yellow
$moaCmds = Get-ChildItem "$cmdDir/moa-*.md" -ErrorAction SilentlyContinue
Check "moa- commands = 5" ($moaCmds.Count -eq 5)

Write-Host "`n=== Model assignment ===" -ForegroundColor Yellow

$expectedModels = @{
    "门童" = "deepseek-v4-flash"
    "工具人"     = "deepseek-v4-flash"
    "工具人-mimo" = "mimo-v2.5"
    "闪电侠"     = "deepseek-v4-flash"
    "视觉翻译官"  = "qwen3.7-plus"
    "中级·工程"  = "kimi-k2.6"
    "中级·创意"  = "qwen3.7-plus"
    "中级·码农"  = "deepseek-v4-flash"
    "中级·融合"  = "kimi-k2.7-code"
    "旗舰·架构"  = "qwen3.7-max"
    "旗舰·规划"  = "deepseek-v4-flash"
    "旗舰·工程"  = "deepseek-v4-flash"
    "旗舰·融合"  = "kimi-k3"
    "旗舰·执行"  = "deepseek-v4-flash"
    "旗舰·质检"  = "deepseek-v4-pro"
    "前端·还原"  = "qwen3.7-plus"
    "前端·逻辑"  = "qwen3.7-plus"
    "前端·动效"  = "mimo-v2.5-pro"
    "前端·总工"  = "deepseek-v4-flash"
    "残差提取者"  = "deepseek-v4-flash"
    "置信度评估者" = "deepseek-v4-flash"
    "融合·保底"  = "deepseek-v4-pro"
}

foreach ($name in $expectedModels.Keys) {
    $file = Join-Path $agentDir "$name.md"
    if (Test-Path $file) {
        $content = Get-Content $file -Raw -Encoding utf8
        $hasModel = $content -match "model:\s*opencode-go/$($expectedModels[$name])"
        Check "$($name) model=$($expectedModels[$name])" $hasModel
    } else {
        Check "$($name) file exists" $false
    }
}

Write-Host "`n=== reasoningEffort coverage ===" -ForegroundColor Yellow
$reCount = 0
foreach ($f in (Get-ChildItem "$agentDir/*.md")) {
    $c = Get-Content $f.FullName -Raw -Encoding utf8
    $reCount += ([regex]::Matches($c, "reasoningEffort:")).Count
}
Check "reasoningEffort = 22" ($reCount -eq 22)

Write-Host "`n=== reasoningEffort value (must be lowercase gateway enum) ===" -ForegroundColor Yellow
$validRE = @('low','medium','high','max','xhigh','none','minimal')
$reBad = 0
foreach ($f in (Get-ChildItem "$agentDir/*.md")) {
    $c = Get-Content $f.FullName -Raw -Encoding utf8
    foreach ($m in [regex]::Matches($c, '(?m)^\s*reasoningEffort:\s*(\S+)\s*$')) {
        $v = $m.Groups[1].Value.TrimEnd(',')
        if ($validRE -notcontains $v) { $reBad++ }
    }
}
Check "reasoningEffort values all valid lowercase" ($reBad -eq 0)

Write-Host "`n=== task: count ===" -ForegroundColor Yellow
$taskCount = 0
foreach ($f in (Get-ChildItem "$agentDir/*.md")) {
    $c = Get-Content $f.FullName -Raw -Encoding utf8
    $taskCount += ([regex]::Matches($c, "(?m)^\s+task:")).Count
}
Check "task: = 22" ($taskCount -eq 22)

Write-Host "`n=== Permission groups ===" -ForegroundColor Yellow
$toolAgents = @("工具人", "工具人-mimo", "视觉翻译官")
foreach ($a in $toolAgents) {
    $c = Get-Content (Join-Path $agentDir "$a.md") -Raw -Encoding utf8
    Check "$($a) edit=deny" ($c -match "edit:\s*deny")
    Check "$($a) bash=deny" ($c -match "bash:\s*deny")
}

$taskDenyAgents = @("工具人", "工具人-mimo")
foreach ($a in $taskDenyAgents) {
    $c = Get-Content (Join-Path $agentDir "$a.md") -Raw -Encoding utf8
    Check "$($a) task=deny" ($c -match "task:\s*deny")
}

$execAgents = @("闪电侠", "旗舰·执行", "前端·还原")
foreach ($a in $execAgents) {
    $c = Get-Content (Join-Path $agentDir "$a.md") -Raw -Encoding utf8
    Check "$($a) edit=allow" ($c -match "edit:\s*allow")
    Check "$($a) lsp=allow" ($c -match "lsp:\s*allow")
    Check "$($a) no bash=allow" ($c -notmatch "bash:\s*allow")
    Check "$($a) no bash block (global single-source)" ($c -notmatch '(?m)^\s*bash:')
    Check "$($a) task=deny" ($c -match "task:\s*deny")
}


Write-Host "`n=== Install script consistency ===" -ForegroundColor Yellow
$installPs1 = Join-Path $base "install.ps1"
$installSh = Join-Path $base "install.sh"
$staleAgentCountPatterns = @(
    "19 agents",
    "19 个 agent",
    "期望 19",
    "Agents: 19",
    "agentCount -eq 19",
    "AGENT_COUNT -eq 19"
)
foreach ($scriptPath in @($installPs1, $installSh)) {
    if (Test-Path $scriptPath) {
        $scriptContent = Get-Content $scriptPath -Raw -Encoding utf8
        $hasStalePattern = $false
        foreach ($pattern in $staleAgentCountPatterns) {
            if ($scriptContent -like "*$pattern*") { $hasStalePattern = $true }
        }
        Check "$(Split-Path $scriptPath -Leaf) has no stale 19-agent wording" (-not $hasStalePattern)
    } else {
        Check "$(Split-Path $scriptPath -Leaf) exists" $false
    }
}

Write-Host "`n=== opencode.json permission security ===" -ForegroundColor Yellow
$ocJsonRaw = Get-Content (Join-Path $base "opencode.json") -Raw -Encoding utf8
$oc = $ocJsonRaw | ConvertFrom-Json
Check "no instructions AGENTS.md reference" ($ocJsonRaw -notmatch '"instructions"')
Check "global * ask" ($oc.permission."*" -eq "ask")
Check "bash * ask first" ($oc.permission.bash."*" -eq "ask")
$bashKeys = @($oc.permission.bash.PSObject.Properties.Name)
foreach ($k in @('git status *','git diff *','git log *','grep *','rg *','ls *','Get-ChildItem *','Get-Content *','Select-String *','cd *','npm run *','pwsh .opencode/tests/*')) {
    Check "bash allow: $k" ($bashKeys -contains $k)
}
foreach ($k in @('rm *','del *','Remove-Item *','rd *','rmdir *')) {
    Check "bash ask: $k" ($oc.permission.bash.$k -eq "ask")
}
Check "read *.env deny" ($oc.permission.read."*.env" -eq "deny")
Check "read *.env.example allow" ($oc.permission.read."*.env.example" -eq "allow")
$agentBlockCount = @($oc.agent.PSObject.Properties.Name).Count
Check "agent override blocks = 10" ($agentBlockCount -eq 10)
$mcpDenyCount = ([regex]::Matches($ocJsonRaw, '"\*_\*":')).Count
Check "MCP deny (*_*) in 10 agent blocks only" ($mcpDenyCount -eq 10)
$taskObjCount = ([regex]::Matches($ocJsonRaw, '"task":  \{')).Count
Check "task object only in global permission (1)" ($taskObjCount -eq 1)
$askStarCount = ([regex]::Matches($ocJsonRaw, '"\*":\s*"ask"')).Count
Check '`"*"`: ask only global+bash (2)' ($askStarCount -eq 2)

Write-Host "`n=== task whitelist consistency (opencode.json / router / installers) ===" -ForegroundColor Yellow
$taskWhitelist = @($oc.permission.task.PSObject.Properties.Name | Where-Object { $_ -ne '*' })
Check "task whitelist = 21" ($taskWhitelist.Count -eq 21)
$routerRaw = Get-Content (Join-Path $agentDir "门童.md") -Raw -Encoding utf8
$rm = [regex]::Match($routerRaw, '(?s)task:\s*\r?\n(?:\s+["''][^"'']+["'']:\s*deny\r?\n)?(?<body>(?:\s+["''][^"'']+["'']:\s*allow\r?\n)+)')
$routerList = @([regex]::Matches($rm.Groups['body'].Value, '["'']([^"'']+)["'']:\s*allow') | ForEach-Object { $_.Groups[1].Value })
Check "router whitelist matches opencode.json" ((Compare-Object $taskWhitelist $routerList).Count -eq 0)
$router = Get-Content (Join-Path $agentDir "门童.md") -Raw -Encoding utf8
Check "门童 唯一合法格式 + invalid 映射" ($router -match '唯一合法格式' -and $router -match "unavailable tool 'invalid'")
foreach ($inst in @((Join-Path $base "install.ps1"), (Join-Path $base "install.sh"))) {
    if (Test-Path $inst) {
        $ic = Get-Content $inst -Raw -Encoding utf8
        $names = @([regex]::Matches($ic, '"([^"\r\n*]+)"\s*[:=]\s*"allow"') | ForEach-Object { $_.Groups[1].Value } | Where-Object { $_ -notmatch '[\s\*]' })
        $missing = @($taskWhitelist | Where-Object { $names -notcontains $_ })
        Check "$(Split-Path $inst -Leaf) whitelist covers all 21 (missing: $($missing -join ','))" ($missing.Count -eq 0)
    }
}

Write-Host "`n=== Platform-specific deny branches in installers ===" -ForegroundColor Yellow
if (Test-Path $installPs1) {
    $ic = Get-Content $installPs1 -Raw -Encoding utf8
    Check "install.ps1 has platform deny branch" ($ic -match '\$IsWindows -or \$env:OS' -and $ic -match 'permission\.bash\.Remove')
}
if (Test-Path $installSh) {
    $ic = Get-Content $installSh -Raw -Encoding utf8
    Check "install.sh has mingw/msys/cygwin detect" ($ic -match 'mingw\|msys\|cygwin')
    Check "install.sh has jq deny injection" ($ic -match 'DENY_EXTRA' -and $ic -match 'reduce \$extra\[\]')
}

Write-Host "`n=== README core-fact anchor ===" -ForegroundColor Yellow
$readmeEn = Join-Path $base "README.md"
$readmeZh = Join-Path $base "README.zh.md"
if (Test-Path $readmeEn) {
    $en = Get-Content $readmeEn -Raw -Encoding utf8
    Check "README.md asserts 22 agents / 5 commands / 3 skills" ($en -match "22 agents · 5 commands · 3 skills")
} else { Check "README.md exists" $false }
if (Test-Path $readmeZh) {
    $zh = Get-Content $readmeZh -Raw -Encoding utf8
    Check "README.zh.md asserts 22 个 agent / 5 个命令 / 3 个技能" ($zh -match "22 个 agent · 5 个命令 · 3 个技能")
} else { Check "README.zh.md exists" $false }

Write-Host "`n==============================" -ForegroundColor Yellow
Write-Host "  PASS: $pass  FAIL: $fail" -ForegroundColor $(if ($fail -eq 0) {'Green'} else {'Red'})
Write-Host "==============================`n" -ForegroundColor Yellow

exit ($fail -gt 0)
