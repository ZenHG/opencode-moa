# translate-readmes.ps1 — Auto-translate README files via GitHub Models
# Usage: pwsh ./scripts/translate-readmes.ps1 [-Target <lang>] [-DryRun]
#
# Detects which source README changed (README.md or README.zh.md),
# translates to all other language READMEs using GitHub Models (free),
# validates output with existing CI checks.

param(
    [string]$Target = "all",
    [switch]$DryRun
)

$ErrorActionPreference = "Continue"

$scriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$base        = Split-Path $scriptDir
$githubToken = $env:GITHUB_TOKEN
$apiUrl      = "https://models.github.ai/inference/chat/completions"
$model       = "openai/gpt-4o-mini"

$targetLangs = @{
    "ja" = "日本語"
    "ko" = "한국어"
    "es" = "Español"
    "fr" = "Français"
    "de" = "Deutsch"
}

$protectedPatterns = @(
    '<!--\s*ARCH-IMG\s*-->', '<!--\s*/ARCH-IMG\s*-->',
    '<!--\s*COST-IMG\s*-->', '<!--\s*/COST-IMG\s*-->',
    'opencode-go/', '^!\['
)

# ── Helper: call GitHub Models with retry ──
function Call-Model {
    param(
        [string]$Messages,
        [int]$MaxRetries = 2
    )
    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            $body = @{
                model    = $model
                messages = @( @{ role = "user"; content = $Messages } )
                max_tokens = 8192
                temperature = 0.3
            } | ConvertTo-Json -Depth 10

            $response = Invoke-RestMethod `
                -Uri $apiUrl `
                -Method Post `
                -Headers @{
                    "Authorization"  = "Bearer $githubToken"
                    "Content-Type"   = "application/json"
                    "Accept"         = "application/vnd.github+json"
                    "X-GitHub-Api-Version" = "2022-11-28"
                } `
                -Body $body `
                -TimeoutSec 180

            return $response.choices[0].message.content
        }
        catch {
            $err = $_.Exception.Message
            $is429 = $err -match '429'
            Write-Host "  [WARN] Attempt $attempt/$MaxRetries failed: $err" -ForegroundColor Yellow
            if ($attempt -lt $MaxRetries) {
                $delay = if ($is429) { 120 } else { [math]::Min(30, [math]::Pow(2, $attempt - 1) * 2) }
                Write-Host "  Retrying in ${delay}s..." -ForegroundColor Gray
                Start-Sleep -Seconds $delay
            } else {
                Write-Host "  [FAIL] All $MaxRetries attempts exhausted" -ForegroundColor Red
                return $null
            }
        }
    }
    return $null
}

# ── Helper: build prompt for a section ──
function Build-Prompt {
    param([string]$Chunk, [string]$Lang, [string]$Context)
    return @"
Translate the following markdown into $Lang. Maintain EXACTLY the same structure, headings, tables, ASCII diagrams, anchors, and code blocks.

RULES:
- DO NOT translate: model IDs, command names, file paths, anchor comments (<!-- ARCH-IMG -->), markdown code blocks, or ASCII diagram characters.
- DO translate: all prose text, table cells with natural language descriptions, headings text, and UI-facing strings.
- PRESERVE the exact same heading level, table alignment, blank lines, and anchor placement.
- Output ONLY the translated markdown with NO extra commentary.
- DO NOT wrap the output in code fences.

Content to translate ($Context):
$Chunk
"@
}

# ── Helper: split content into ~8KB chunks at ## headings ──
function Split-Chunks {
    param([string]$Content, [int]$MinSize = 6000)
    $lines = $Content -split "`n"
    $sections = @(); $buf = ""
    foreach ($line in $lines) {
        if ($line -match '^## ') {
            if ($buf) { $sections += $buf }; $buf = ""
        }
        $buf = if ($buf) { "$buf`n$line" } else { $line }
    }
    if ($buf) { $sections += $buf }

    if ($sections.Count -eq 0) { return @() }

    $chunks = @(); $acc = $sections[0]
    for ($i = 1; $i -lt $sections.Count; $i++) {
        if ($acc.Length -ge $MinSize) { $chunks += $acc; $acc = "" }
        $acc = if ($acc) { "$acc`n`n$($sections[$i])" } else { $sections[$i] }
    }
    if ($acc) { $chunks += $acc }
    return $chunks
}

# ── Helper: validate translated output quality ──
function Test-Translation {
    param([string]$Source, [string]$Translated)
    $errors = @()

    # Headings preserved
    $srcH = $sourceContent | Select-String -Pattern '^#{2,3}\s' | ForEach-Object { $_.Line }
    $tgtH = $Translated | Select-String -Pattern '^#{2,3}\s' | ForEach-Object { $_.Line }
    if ($srcH.Count -ne $tgtH.Count) {
        $errors += "Heading count mismatch: source=$($srcH.Count), translated=$($tgtH.Count)"
    }

    # ARCH-IMG anchors present
    if ($Translated -notmatch '<!--\s*ARCH-IMG\s*-->') {
        $errors += "ARCH-IMG anchor missing"
    }
    if ($Translated -notmatch '<!--\s*/ARCH-IMG\s*-->') {
        $errors += "Closing ARCH-IMG anchor missing"
    }

    # Cost allocation: translated && cost source found
    $srcHasCost = $Source -match '\$\d+\.\d+/1M'
    $tgtHasCost = $Translated -match '\$\d+\.\d+/1M'
    if ($srcHasCost -and -not $tgtHasCost) {
        $errors += "Cost indicators lost in translation"
    }

    # Empty output guard
    if ([string]::IsNullOrWhiteSpace($Translated)) {
        $errors += "Translated output is empty"
    }

    return $errors
}

# ── Step 1: Detect source README changes ──
Write-Host "`n=== README Auto-Translation ===" -ForegroundColor Cyan

$changedFiles = git diff --name-only HEAD~1..HEAD 2>$null
$sourceReadme = $null

foreach ($f in $changedFiles) {
    if ($f -eq "README.md")    { $sourceReadme = "README.md";    break }
    if ($f -eq "README.zh.md") { $sourceReadme = "README.zh.md"; break }
}

if (-not $sourceReadme) {
    Write-Host "  [SKIP] No source README changed in this commit" -ForegroundColor Gray
    exit 0
}

Write-Host "  Source: $sourceReadme" -ForegroundColor Green
$targetLangsToTranslate = @($targetLangs.Keys)
if ($Target -ne "all") {
    $targetLangsToTranslate = @($Target)
}

# ── Step 2: Read source content ──
$sourcePath = Join-Path $base $sourceReadme
if (-not (Test-Path $sourcePath)) {
    Write-Host "  [WARN] $sourceReadme not found, skipping" -ForegroundColor Yellow
    exit 0
}
$sourceContent = Get-Content $sourcePath -Raw -Encoding utf8
$chunks = Split-Chunks -Content $sourceContent

# ── Step 3: Translate each language ──
$overallSuccess = $true
$failedLangs = @()
$successfulLangs = @()

foreach ($lang in $targetLangsToTranslate) {
    Write-Host "`n--- Translating to ${lang} ($($targetLangs[$lang])) ---" -ForegroundColor Yellow

    $targetFile = "README.$lang.md"
    $targetPath = Join-Path $base $targetFile
    if (-not (Test-Path $targetPath)) {
        Write-Host "  [WARN] $targetFile does not exist, skipping" -ForegroundColor Yellow
        continue
    }

    $translatedChunks = @()
    $langOk = $true

    for ($ci = 0; $ci -lt $chunks.Count; $ci++) {
        $chunk = $chunks[$ci]
        $context = if ($ci -eq 0) { "preamble" } else { "section" }
        $prompt = Build-Prompt -Chunk $chunk -Lang $targetLangs[$lang] -Context $context

        Write-Host "  Chunk $($ci+1)/$($chunks.Count) ($($chunk.Length)B)..." -ForegroundColor Gray
        $translated = Call-Model -Messages $prompt

        if (-not $translated) {
            Write-Host "  [FAIL] Chunk $($ci+1) failed for $lang" -ForegroundColor Red
            $langOk = $false
            $overallSuccess = $false
            break
        }

        # Strip accidental code fences
        $translated = $translated -replace '(?s)^\s*```[\w]*\s*\n?', ''
        $translated = $translated -replace '(?s)\s*```\s*$', ''
        $translatedChunks += $translated

        # Adaptive delay: only if more chunks remain
        if ($ci -lt $chunks.Count - 1) { Start-Sleep -Seconds 5 }
    }

    if (-not $langOk) {
        $failedLangs += $lang
        Write-Host "  [FAIL] Translation failed for $lang, keeping existing content" -ForegroundColor Red
        continue
    }

    $translated = $translatedChunks -join "`n`n"

    # ── Step 4: Validate output ──
    $validationErrors = Test-Translation -Source $sourceContent -Translated $translated
    if ($validationErrors.Count -gt 0) {
        Write-Host "  [WARN] Validation issues for ${lang}:" -ForegroundColor Yellow
        foreach ($e in $validationErrors) {
            Write-Host "    - $e" -ForegroundColor Yellow
        }
    }

    if ($DryRun) {
        Write-Host "  [DRY RUN] Would write to $targetFile" -ForegroundColor Gray
        $previewPath = Join-Path $base ".trans-preview.$lang.md"
        Set-Content -Path $previewPath -Value $translated -Encoding utf8
        Write-Host "  Preview saved to $previewPath" -ForegroundColor Cyan
        $successfulLangs += $lang
        continue
    }

    # ── Step 5: Save only once per language ──
    Set-Content -Path $targetPath -Value $translated -Encoding utf8
    Write-Host "  [OK] $targetFile updated" -ForegroundColor Green
    $successfulLangs += $lang
}

# ── Step 6: Run post-translation validation ──
if ($DryRun) {
    Write-Host "`n  [DRY RUN] No changes made. Use preview files to review." -ForegroundColor Cyan
    Write-Host "  Languages done: $($successfulLangs -join ', ')" -ForegroundColor Gray
    exit 0
}

$headersChanged = @()
foreach ($f in @("README.ja.md", "README.ko.md", "README.es.md", "README.fr.md", "README.de.md")) {
    $path = Join-Path $base $f
    if (Test-Path $path) {
        $diff = git diff -- "$f"
        if ($diff) { $headersChanged += $f }
    }
}

if ($headersChanged.Count -eq 0) {
    Write-Host "`n  [SKIP] No translation changes detected" -ForegroundColor Gray
    exit 0
}

if (-not $overallSuccess) {
    Write-Host "`n  [WARN] Some translations failed, but successful ones are saved:" -ForegroundColor Yellow
    Write-Host "  Failed: $($failedLangs -join ', ')" -ForegroundColor Red
    Write-Host "  Success: $($successfulLangs -join ', ')" -ForegroundColor Green
    Write-Host "  Run 'git diff --stat' to review, then manually revert failed ones if needed." -ForegroundColor Gray
    exit 1
}

Write-Host "`n--- Running post-translation checks ---" -ForegroundColor Cyan
pwsh .opencode/tests/T0-static-verify.ps1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [WARN] T0 static verify issues (non-fatal for translation)" -ForegroundColor Yellow
}

pwsh scripts/verify-images.ps1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [FAIL] Image anchor check failed in translated files, reverting" -ForegroundColor Red
    git checkout HEAD -- $($headersChanged -join ' ')
    exit 1
}

$env:LASTEXITCODE = 0
pwsh .opencode/tests/T1-readme-consistency.ps1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [WARN] T1 consistency check issues — review recommended" -ForegroundColor Yellow
}

Write-Host "`n  Translation complete."
Write-Host "  Changed: $($headersChanged -join ', ')" -ForegroundColor Green
Write-Host "  Run 'git diff --stat' to review, then commit." -ForegroundColor Gray
exit 0
