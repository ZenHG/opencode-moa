# T3-permission-security.ps1 — 权限安全语义级回归测试 (0 token)
# 用 opencode Wildcard 语义 (Test-CmdPattern) 验证 bash 规则的实际匹配行为，
# 覆盖 T0 字符串断言做不到的形态: 命令+参数组合、`cmd *` 尾部特判、平台命令别名。
# 断言基线 = 白名单单源全局版 (opencode.json 全局 bash 段):
#   13 allow (git status/diff/log、grep/rg/Select-String、ls/Get-ChildItem、Get-Content、
#             cd、npm run、pwsh .opencode/tests/*) + 5 ask (rm/del/Remove-Item/rd/rmdir, 删除前询问用户)
#   + "*": "ask" 兜底; 执行层 frontmatter 无 bash 段。
# Usage: pwsh .opencode/tests/T3-permission-security.ps1

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$base = Split-Path (Split-Path $scriptDir)
$configPath = Join-Path $base "opencode.json"

$pass = 0; $fail = 0

function Check($name, $ok) {
    if ($ok) { $script:pass++; Write-Host "  [PASS] $name" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $name" -ForegroundColor Red }
}

# 复刻 opencode Wildcard.match 语义: * -> .*, `cmd *` 结尾特判为 ( .*)?, 大小写敏感, \ -> /
function Test-CmdPattern([string]$pattern, [string]$cmd) {
    $p = $pattern.Replace('\', '/')
    $tailOptional = $false
    if ($p -match ' \*$') {
        $p = $p.Substring(0, $p.Length - 2)
        $tailOptional = $true
    }
    $p = [regex]::Escape($p).Replace('\*', '.*')
    if ($tailOptional) { $p += '( .*)?' }
    return ($cmd -cmatch "^$p$")
}

$config = Get-Content $configPath -Raw -Encoding utf8 | ConvertFrom-Json
$bashRules = @()
foreach ($p in $config.permission.bash.PSObject.Properties) {
    $bashRules += [pscustomobject]@{ Pattern = $p.Name; Action = $p.Value }
}

# 最后一条匹配规则生效 (同 opencode evaluate 的 findLast); 无匹配返回 $null = ask 兜底
function Action-For([string]$cmd) {
    $hit = $null
    foreach ($r in $bashRules) {
        if (Test-CmdPattern $r.Pattern $cmd) { $hit = $r.Action }
    }
    return $hit
}

Write-Host "`n=== A1: 破坏性命令不得被 allow (ask/deny 均可) ===" -ForegroundColor Yellow
$destructive = @("git push", "git push -f origin main", "git reset --hard HEAD~1",
    "git clean -fd", "git clean -fdx", "git commit -m x", "git commit --amend")
foreach ($cmd in $destructive) {
    Check "不 allow '$cmd'" ((Action-For $cmd) -ne "allow")
}

Write-Host "`n=== A2: 破坏性删除命令必须 ask (删除前询问用户) ===" -ForegroundColor Yellow
$winDel = @("rm -rf dist", "del /q file.txt", "Remove-Item -Recurse -Force dist",
    "Remove-Item -Path .\dist -Recurse", "rd /s /q dist", "rmdir /s /q dist")
foreach ($cmd in $winDel) {
    Check "ask 命中 '$cmd'" ((Action-For $cmd) -eq "ask")
}

Write-Host "`n=== A3: 白名单正向命中 (安全读/构建/测试命令) ===" -ForegroundColor Yellow
$safe = @{
    "git status --porcelain" = "allow"; "git diff HEAD~1" = "allow"; "git log --oneline -5" = "allow"
    "grep -r foo src" = "allow"; "rg -l bar" = "allow"; "Select-String -Path a.ps1 -Pattern x" = "allow"
    "ls -la" = "allow"; "Get-ChildItem -Recurse" = "allow"; "Get-Content README.md" = "allow"
    "cd src" = "allow"; "npm run build" = "allow"; "pwsh .opencode/tests/run-all.ps1" = "allow"
}
foreach ($k in $safe.Keys) {
    Check "allow '$k'" ((Action-For $k) -eq $safe[$k])
}

Write-Host "`n=== A4: `cmd *` 尾部特判 — 裸命令也匹配 ===" -ForegroundColor Yellow
foreach ($cmd in @("git status", "git diff", "git log", "ls", "cd", "grep", "rg", "rm")) {
    $expect = if ($cmd -eq "rm") { "ask" } else { "allow" }
    Check "裸 '$cmd' → $expect" ((Action-For $cmd) -eq $expect)
}

Write-Host "`n=== A5: cat 不得 allow (防绕过 read 的 *.env deny) ===" -ForegroundColor Yellow
foreach ($cmd in @("cat .env", "cat config.env", "cat > file.txt")) {
    Check "不 allow '$cmd'" ((Action-For $cmd) -ne "allow")
}

Write-Host "`n=== A6: 未知命令回落 ask (兜底 `"*`" 存在) ===" -ForegroundColor Yellow
$fallback = $bashRules | Where-Object { $_.Pattern -eq "*" -and $_.Action -eq "ask" }
Check '全局 bash "*": "ask" 兜底存在' ($null -ne $fallback)
foreach ($cmd in @("curl -s https://x", "python script.py", "powershell -c x", "terraform apply", "winget install x")) {
    Check "未知命令 '$cmd' → ask" ((Action-For $cmd) -eq "ask")
}

Write-Host "`n==============================" -ForegroundColor Yellow
Write-Host "  PASS: $pass  FAIL: $fail" -ForegroundColor $(if ($fail -eq 0) {'Green'} else {'Red'})
Write-Host "==============================`n" -ForegroundColor Yellow

exit ($fail -gt 0)
