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
Check "Agent files = 19" ($agents.Count -eq 19)

Write-Host "`n=== Command count ===" -ForegroundColor Yellow
$cmds = Get-ChildItem "$cmdDir/*.md" -ErrorAction SilentlyContinue
Check "Command files = 5" ($cmds.Count -eq 5)

Write-Host "`n=== Skill count ===" -ForegroundColor Yellow
$skills = Get-ChildItem "$skillDir/*/SKILL.md" -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch "[/\\]opencode-moa[/\\]SKILL\.md$" }
Check "Skill files = 3 (excl. meta)" ($skills.Count -eq 3)

Write-Host "`n=== Command prefix ===" -ForegroundColor Yellow
$moaCmds = Get-ChildItem "$cmdDir/moa-*.md" -ErrorAction SilentlyContinue
Check "moa- commands = 5" ($moaCmds.Count -eq 5)

Write-Host "`n=== Model assignment ===" -ForegroundColor Yellow

$expectedModels = @{
    "门童路由员" = "deepseek-v4-flash"
    "工具人"     = "deepseek-v4-flash"
    "工具人-mimo" = "mimo-v2.5"
    "闪电侠"     = "deepseek-v4-flash"
    "视觉翻译官"  = "mimo-v2.5"
    "中级·工程"  = "minimax-m3"
    "中级·创意"  = "deepseek-v4-pro"
    "中级·码农"  = "deepseek-v4-flash"
    "中级·融合"  = "kimi-k2.7-code"
    "旗舰·架构"  = "qwen3.7-max"
    "旗舰·规划"  = "glm-5.2"
    "旗舰·工程"  = "minimax-m3"
    "旗舰·融合"  = "kimi-k2.7-code"
    "旗舰·实现"  = "deepseek-v4-flash"
    "旗舰·质检"  = "deepseek-v4-pro"
    "前端·还原"  = "mimo-v2.5"
    "前端·逻辑"  = "qwen3.7-plus"
    "前端·动效"  = "mimo-v2.5-pro"
    "前端·总工"  = "kimi-k2.7-code"
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
Check "reasoningEffort = 19" ($reCount -eq 19)

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
Check "task: = 9" ($taskCount -eq 9)

Write-Host "`n=== Permission groups ===" -ForegroundColor Yellow
$toolAgents = @("工具人", "工具人-mimo", "视觉翻译官")
foreach ($a in $toolAgents) {
    $c = Get-Content (Join-Path $agentDir "$a.md") -Raw -Encoding utf8
    Check "$($a) edit=deny" ($c -match "edit:\s*deny")
    Check "$($a) bash=deny" ($c -match "bash:\s*deny")
}

$execAgents = @("闪电侠", "旗舰·实现", "前端·还原")
foreach ($a in $execAgents) {
    $c = Get-Content (Join-Path $agentDir "$a.md") -Raw -Encoding utf8
    Check "$($a) edit=allow" ($c -match "edit:\s*allow")
    Check "$($a) bash=allow" ($c -match "bash:\s*allow")
}

Write-Host "`n==============================" -ForegroundColor Yellow
Write-Host "  PASS: $pass  FAIL: $fail" -ForegroundColor $(if ($fail -eq 0) {'Green'} else {'Red'})
Write-Host "==============================`n" -ForegroundColor Yellow

exit ($fail -gt 0)
