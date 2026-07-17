# T1-readme-consistency.ps1 — README / deploy-doc vs agents model consistency
# Verifies: 7 README diagrams + 2 deploy docs model assignment matches .opencode/agents/*.md
# Exit code: 0 = pass, 1 = fail

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$base = Split-Path (Split-Path $scriptDir)
$agentDir = Join-Path $base ".opencode/agents"

$pass = 0; $fail = 0
function Check($name, $ok, $detail = "") {
    if ($ok) { $script:pass++; Write-Host "  [PASS] $name" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $name $detail" -ForegroundColor Red }
}

# ── 1. Parse agents: name -> model-id (after opencode-go/) ──
$agentModels = @{}
foreach ($f in (Get-ChildItem "$agentDir/*.md")) {
    $c = Get-Content $f.FullName -Raw -Encoding utf8
    if ($c -match "model:\s*opencode-go/(\S+)") {
        $agentModels[$f.BaseName] = $Matches[1]
    }
}

# ── 2. Normalization map: README display name -> model-id ──
$displayToModel = @{
    "Flash"           = "deepseek-v4-flash"
    "MiMo"            = "mimo-v2.5"
    "MiMo-Pro"        = "mimo-v2.5-pro"
    "DeepSeek Pro"    = "deepseek-v4-pro"
    "DeepSeek V4 Pro" = "deepseek-v4-pro"
    "GLM 5.2"         = "glm-5.2"
    "GLM-5.2"         = "glm-5.2"
    "Qwen3.7 Max"     = "qwen3.7-max"
    "Qwen3.7 Plus"    = "qwen3.7-plus"
    "MiniMax M3"      = "minimax-m3"
    "Kimi K3"         = "kimi-k3"
    "Kimi K2.6"       = "kimi-k2.6"
    "Kimi K2.7 Code"  = "kimi-k2.7-code"
    "Kimi"            = "kimi-k2.7-code"
}
function Normalize($display) {
    $display = $display.Trim()
    if ($displayToModel.ContainsKey($display)) { return $displayToModel[$display] }
    return $display.ToLower() -replace '\s', ''
}

# ── 3. Check 7 README files ──
$readmeFiles = @("README.md","README.zh.md","README.ja.md","README.ko.md","README.es.md","README.fr.md","README.de.md")

# Role keywords that indicate an agent definition line
$rolePattern = 'flag-|fe-|tool-|swift|vision|mid-|concierge-router|门童路由员|融合·保底'

foreach ($rf in $readmeFiles) {
    $p = Join-Path $base $rf
    if (-not (Test-Path $p)) { Check "$rf exists" $false; continue }
    $lines = Get-Content $p -Encoding utf8

    $checked = 0
    $mismatches = @()

    foreach ($line in $lines) {
        if ($line -match 'failed') { continue }
        if ($line -notmatch $rolePattern) { continue }

        $cnName = $null
        $displayModel = $null

        if ($rf -eq "README.zh.md") {
            # Format A: 中文名 (Model)  — first diagram
            # Format B: 中文名 / role (Model)  — 22 Agents section
            if ($line -match '([一-鿿·]+)\s*\(([^)]+)\)' -and $line -notmatch '\/') {
                $cnName = $Matches[1].Trim()
                $displayModel = $Matches[2].Trim()
            } elseif ($line -match '([一-鿿·]+)\s*\/\s*\S+\s*\(([^)]+)\)') {
                $cnName = $Matches[1].Trim()
                $displayModel = $Matches[2].Trim()
            }
        } else {
            # Format: role (cnName, model)  or  (cnName, model)
            if ($line -match '\(([^,]+),\s*([^)]+)\)') {
                $cnName = $Matches[1].Trim()
                $displayModel = $Matches[2].Trim()
            }
        }

        if ($cnName -and $displayModel -and $agentModels.ContainsKey($cnName)) {
            $expected = $agentModels[$cnName]
            $actual = Normalize $displayModel
            $checked++
            if ($actual -ne $expected) {
                $mismatches += "$cnName (got '$displayModel'->'$actual', expected '$expected')"
            }
        }
    }

    if ($checked -eq 0) {
        Check "$rf : found agent-model pairs" $false
    } elseif ($mismatches.Count -eq 0) {
        Check "$rf : $checked agent-model pairs consistent" $true
    } else {
        Check "$rf : $checked pairs, $($mismatches.Count) mismatch" $false " [$($mismatches -join '; ')]"
    }
}

# ── 4. Check 2 deploy docs ──
$deployDocs = @("docs/opencode-moa.md","docs/opencode-moa.en.md")
foreach ($df in $deployDocs) {
    $p = Join-Path $base $df
    if (-not (Test-Path $p)) { Check "$df exists" $false; continue }
    $c = Get-Content $p -Raw -Encoding utf8
    $docModels = [regex]::Matches($c, 'model:\s*opencode-go/(\S+)') | ForEach-Object { $_.Groups[1].Value }
    $agentModelVals = $agentModels.Values | Sort-Object -Unique
    $docModelVals = $docModels | Sort-Object -Unique

    $missing = $agentModelVals | Where-Object { $_ -notin $docModelVals }
    $extra = $docModelVals | Where-Object { $_ -notin $agentModelVals }

    if ($missing.Count -eq 0 -and $extra.Count -eq 0) {
        Check "$df : all $($agentModelVals.Count) model-ids present" $true
    } else {
        if ($missing) { Check "$df : missing models [$($missing -join ', ')]" $false }
        if ($extra) { Check "$df : extra models [$($extra -join ', ')]" $false }
    }
}

Write-Host "`n==============================" -ForegroundColor Yellow
Write-Host "  PASS: $pass  FAIL: $fail" -ForegroundColor $(if ($fail -eq 0) {'Green'} else {'Red'})
Write-Host "==============================`n" -ForegroundColor Yellow

exit ($fail -gt 0)
