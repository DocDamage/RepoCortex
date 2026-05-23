#Requires -Version 5.1
<#
.SYNOPSIS
    Build orchestrator for LLMWorkflow with dependency-aware testing and boundary enforcement.
.DESCRIPTION
    Detects changed files, determines affected contexts via dependency graph,
    runs boundary violation scans, enforces advisory file size limits, and executes
    Pester tests for only the affected contexts.
#>
[CmdletBinding()]
param(
    [switch]$WhatIf,
    [switch]$Test,
    [switch]$Lint,
    [switch]$Docs,
    [switch]$CI,
    [string[]]$ChangedFiles,
    [string]$ProjectRoot = (Resolve-Path (Join-Path (Join-Path $PSScriptRoot '..') '..')),
    [string]$ModuleRoot = (Join-Path $ProjectRoot 'module\LLMWorkflow')
)

Set-StrictMode -Version Latest

#region Dependency Graph

$script:ContextGraph = [ordered]@{
    '_shared'    = @()
    'Workflow'   = @('_shared')
    'Telemetry'  = @('_shared')
    'Retrieval'  = @('_shared', 'Workflow')
    'Ingestion'  = @('_shared', 'Retrieval')
    'GameAssets' = @('_shared', 'Ingestion')
    'Governance' = @('_shared', 'Workflow', 'Retrieval')
    'MCP'        = @('_shared', 'Workflow', 'Retrieval')
    'Federation' = @('_shared', 'Workflow', 'Telemetry')
    'Platform'   = @('_shared', 'Workflow', 'Retrieval', 'Ingestion', 'MCP')
}

function Get-ContextFromPath {
    param([string]$FilePath)
    $rel = $FilePath -replace '^.*module[\\/]LLMWorkflow[\\/]', ''
    if ($rel -match '^contexts[\\/]([^\\/]+)[\\/]') {
        return $matches[1]
    }
    # Legacy path mapping
    $legacyMap = @{
        'core'       = 'Workflow'
        'workflow'   = 'Workflow'
        'telemetry'  = 'Telemetry'
        'retrieval'  = 'Retrieval'
        'ingestion'  = 'Ingestion'
        'governance' = 'Governance'
        'pack'       = 'Workflow'
        'policy'     = 'Platform'
        'mcp'        = 'MCP'
        'snapshot'   = 'Platform'
        'interpack'  = 'Federation'
    }
    foreach ($key in $legacyMap.Keys) {
        if ($rel -match "^$key[\\/]") {
            return $legacyMap[$key]
        }
    }
    if ($rel -match '^(LLMWorkflow\.GameFunctions|DashboardViews)\.ps1$') { return 'GameAssets' }
    if ($rel -match '^(LLMWorkflow\.HealFunctions)\.ps1$') { return 'Platform' }
    if ($rel -match '^(LLMWorkflow\.Dashboard)\.ps1$') { return 'Telemetry' }
    return 'Workflow'
}

function Get-AffectedContexts {
    param([string[]]$Files)
    $direct = $Files | ForEach-Object { Get-ContextFromPath $_ } | Select-Object -Unique
    $affected = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($ctx in $direct) {
        [void]$affected.Add($ctx)
        # Add all contexts that depend on this one
        foreach ($node in $script:ContextGraph.Keys) {
            if ($script:ContextGraph[$node] -contains $ctx) {
                [void]$affected.Add($node)
            }
        }
    }
    # Topological sort based on graph
    $ordered = @()
    $visited = [System.Collections.Generic.HashSet[string]]::new()
    function Visit-Node {
        param([string]$n)
        if ($visited.Contains($n)) { return }
        [void]$visited.Add($n)
        foreach ($dep in $script:ContextGraph[$n]) {
            Visit-Node -n $dep
        }
        $script:ordered += $n
    }
    $script:ordered = @()
    foreach ($c in $affected | Sort-Object) {
        Visit-Node -n $c
    }
    return $script:ordered | Where-Object { $affected.Contains($_) }
}

#endregion

#region Boundary & Size Enforcement

function Test-BuildBoundaries {
    param([string]$ContextRoot)
    $violations = @()
    $contextDirs = Get-ChildItem -Path $ContextRoot -Directory | Where-Object { $_.Name -ne '_shared' }
    foreach ($ctxDir in $contextDirs) {
        $ps1Files = Get-ChildItem -Path $ctxDir.FullName -Recurse -Filter '*.ps1'
        foreach ($file in $ps1Files) {
            $content = Get-Content -LiteralPath $file.FullName -Raw
            # Detect dot-sourcing outside own context or _shared
            $pattern = '\.\s+["\'']?([^"\''\r\n]+)["\'']?'
            $matches = [regex]::Matches($content, $pattern)
            foreach ($m in $matches) {
                $target = $m.Groups[1].Value
                if ($target -match '^\$') { continue } # variable-based dot-source, skip static check
                $resolved = $target
                try {
                    if (-not [System.IO.Path]::IsPathRooted($target)) {
                        $resolved = Join-Path (Split-Path -Parent $file.FullName) $target
                    }
                    $resolved = Resolve-Path -Path $resolved -ErrorAction Stop
                } catch { continue }
                $targetRel = $resolved.Path -replace '^.*contexts[\\/]', ''
                $targetCtx = ($targetRel -split '[\\/]')[0]
                $ownCtx = $ctxDir.Name
                if ($targetCtx -ne '_shared' -and $targetCtx -ne $ownCtx) {
                    $violations += "BOUNDARY VIOLATION: $($file.FullName) imports $resolved ($ownCtx -> $targetCtx)"
                }
            }
        }
    }
    return $violations
}

function Test-FileSizeLimits {
    param([string]$ContextRoot)
    $issues = @()
    $allPs1 = Get-ChildItem -Path $ContextRoot -Recurse -Filter '*.ps1'
    foreach ($f in $allPs1) {
        $lines = (Get-Content -LiteralPath $f.FullName | Measure-Object).Count
        if ($lines -gt 300) {
            $issues += "SIZE WARNING: $($f.FullName) has $lines lines (advisory max 300; refactor recommended)"
        }
        elseif ($lines -gt 200) {
            $issues += "SIZE WARNING: $($f.FullName) has $lines lines (advisory max 300)"
        }
    }
    return $issues
}

#endregion

#region Actions

if (-not $ChangedFiles -and ($Test -or $CI)) {
    # Auto-detect changed files from git
    $gitRoot = $ProjectRoot
    $diffOutput = & git -C $gitRoot diff --name-only HEAD~1 2>$null
    if ($LASTEXITCODE -eq 0 -and $diffOutput) {
        $ChangedFiles = $diffOutput | Where-Object { $_ -match '\.ps1$|\.psd1$|\.psm1$' }
    }
    if (-not $ChangedFiles) {
        Write-Warning "No changed files detected; running full test suite."
        $ChangedFiles = @('*')
    }
}

$affected = Get-AffectedContexts -Files $ChangedFiles
Write-Information "Affected contexts: $($affected -join ', ')" -InformationAction Continue

$boundaryViolations = Test-BuildBoundaries -ContextRoot (Join-Path $ModuleRoot 'contexts')
$sizeIssues = Test-FileSizeLimits -ContextRoot (Join-Path $ModuleRoot 'contexts')

if ($boundaryViolations) {
    foreach ($v in $boundaryViolations) { Write-Error $v }
}
if ($sizeIssues) {
    foreach ($s in $sizeIssues) { Write-Warning $s }
}

if ($WhatIf) {
    Write-Output "WhatIf: Would lint, then test these contexts: $($affected -join ', ')"
    if ($boundaryViolations) { Write-Output "Boundary violations found: $($boundaryViolations.Count)" }
    if ($sizeIssues) { Write-Output "Size issues found: $($sizeIssues.Count)" }

    # Gate: fail if stale scratch/probe artifacts are present
    foreach ($probe in @('_content_probe.txt', 'f')) {
        $probePath = Join-Path $ProjectRoot $probe
        if (Test-Path -LiteralPath $probePath) {
            throw "Release-blocking scratch/stale artifact is checked in: $probe"
        }
    }

    # Gate: run CI validators if present
    foreach ($validator in @('tools\ci\check-template-drift.ps1', 'tools\ci\validate-compatibility-lock.ps1', 'tools\ci\validate-docs-truth.ps1')) {
        $vPath = Join-Path $ProjectRoot $validator
        if (Test-Path -LiteralPath $vPath) {
            & $vPath
        } else {
            Write-Warning "CI validator not found (skipped): $validator"
        }
    }

    return
}

if ($Lint) {
    $customRules = Get-ChildItem -Path (Join-Path $PSScriptRoot 'PSScriptAnalyzer') -Filter '*.psm1' -ErrorAction Ignore
    $analyzerParams = @{
        Path = (Join-Path $ModuleRoot 'contexts')
        Recurse = $true
        Severity = @('Error','Warning')
    }
    if ($customRules) {
        $analyzerParams['CustomRulePath'] = $customRules.FullName
    }
    $results = Invoke-ScriptAnalyzer @analyzerParams
    if ($results | Where-Object Severity -eq 'Error') {
        $results | Where-Object Severity -eq 'Error' | Format-Table -AutoSize
        throw "PSScriptAnalyzer found errors."
    }
    $results | Where-Object Severity -eq 'Warning' | Format-Table -AutoSize
    Write-Information "Lint complete." -InformationAction Continue
}

if ($Test) {
    $testRoot = Join-Path $ProjectRoot 'tests'
    $testFiles = Get-ChildItem -Path $testRoot -Filter '*.Tests.ps1' | ForEach-Object { $_.FullName }

    # Map test files to contexts (naive name-based mapping)
    $testsToRun = @()
    foreach ($tf in $testFiles) {
        $tfName = Split-Path -Leaf $tf
        $matched = $false
        foreach ($ctx in $affected) {
            $ctxPattern = $ctx -replace 'GameAssets','GameAsset|SpriteSheet|Atlas|UnrealDescriptor|RPGMaker'
            if ($tfName -match $ctxPattern) {
                $testsToRun += $tf
                $matched = $true
                break
            }
        }
        if (-not $matched -and $affected -contains 'Workflow') {
            # Core tests run when Workflow is affected
            if ($tfName -match 'Core|Primitive|Module|Compatibility') {
                $testsToRun += $tf
            }
        }
    }

    if (-not $testsToRun) {
        Write-Warning "No specific test files mapped for affected contexts. Running core smoke tests."
        $testsToRun = @(Join-Path $testRoot 'CoreModule.Tests.ps1')
    }

    $testsToRun = $testsToRun | Select-Object -Unique
    Write-Information "Running tests: $($testsToRun | ForEach-Object { Split-Path -Leaf $_ } | Join-String -Separator ', ')" -InformationAction Continue

    $pesterRunner = Join-Path $ProjectRoot 'tools\ci\invoke-pester-safe.ps1'
    if (-not (Test-Path -LiteralPath $pesterRunner)) {
        throw "Pester runner not found: $pesterRunner"
    }

    foreach ($t in $testsToRun) {
        $pesterArgs = @{
            Path = @($t)
            Verbosity = 'Detailed'
        }
        if ($CI) {
            $pesterArgs['CI'] = $true
        }
        & $pesterRunner @pesterArgs
        if ($LASTEXITCODE -ne 0) {
            throw "Pester failed for test file: $t"
        }
    }
}

if ($Docs) {
    # Run docs-truth validation
    $docsValidator = Join-Path $ProjectRoot 'tools\ci\validate-docs-truth.ps1'
    if (Test-Path -LiteralPath $docsValidator) {
        & $docsValidator
    } else {
        Write-Warning "docs-truth validator not found: $docsValidator"
    }

    # Mojibake / encoding corruption guard over release-facing docs
    $releaseDocs = @(
        'README.md',
        'PROGRESS.md',
        'docs\implementation\PROGRESS.md',
        'docs\implementation\REMAINING_WORK.md',
        'docs\releases\RELEASE_STATE.md',
        'docs\releases\V1_RELEASE_CRITERIA.md',
        'docs\releases\RELEASE_CERTIFICATION_CHECKLIST.md',
        'docs\reference\DOCS_TRUTH_MATRIX.md'
    )

    $mojibakePattern = 'Â|â€|âœ|ðŸ'
    $badFiles = [System.Collections.Generic.List[string]]::new()

    foreach ($relativePath in $releaseDocs) {
        $path = Join-Path $ProjectRoot $relativePath
        if (-not (Test-Path -LiteralPath $path)) { continue }
        $content = Get-Content -LiteralPath $path -Raw
        if ($content -match $mojibakePattern) {
            $badFiles.Add($relativePath)
        }
    }

    if ($badFiles.Count -gt 0) {
        throw "Release-facing documentation contains mojibake/encoding corruption: $($badFiles -join ', ')"
    }

    Write-Information 'Docs validation complete. No mojibake detected.' -InformationAction Continue
}

Write-Information "Build complete." -InformationAction Continue

#endregion
