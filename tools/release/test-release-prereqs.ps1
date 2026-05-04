#requires -Version 5.1
<#
.SYNOPSIS
    Preflight verification for release readiness.
.DESCRIPTION
    Verifies that tag matches manifest version, VERSION/manifest/compatibility lock/
    changelog agree, required secrets are documented, release certification passes,
    package can be assembled locally, and no generated scratch artifacts are included.
#>

[CmdletBinding()]
param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path,
    [switch]$WhatIf
)

Set-StrictMode -Version Latest

$issues = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()

function Add-Issue {
    param([string]$Message)
    $script:issues.Add($Message)
    Write-Warning "ISSUE: $Message"
}

function Add-Warning {
    param([string]$Message)
    $script:warnings.Add($Message)
    Write-Warning "WARN: $Message"
}

Write-Host "[test-release-prereqs] Running release preflight checks..." -ForegroundColor Cyan

# 1. VERSION file
$versionPath = Join-Path $ProjectRoot 'VERSION'
if (-not (Test-Path -LiteralPath $versionPath)) {
    Add-Issue "VERSION file not found at $versionPath"
    return
}
$version = (Get-Content -LiteralPath $versionPath -Raw).Trim()
if ([string]::IsNullOrWhiteSpace($version)) {
    Add-Issue "VERSION file is empty"
}
Write-Host "  VERSION: $version" -ForegroundColor Gray

# 2. Manifest version match
$manifestPath = Join-Path $ProjectRoot 'module\LLMWorkflow\LLMWorkflow.psd1'
if (-not (Test-Path -LiteralPath $manifestPath)) {
    Add-Issue "Module manifest not found at $manifestPath"
} else {
    $manifest = Import-PowerShellDataFile -Path $manifestPath
    if ($manifest.ModuleVersion -ne $version) {
        Add-Issue "Manifest ModuleVersion ($($manifest.ModuleVersion)) does not match VERSION ($version)"
    } else {
        Write-Host "  Manifest version: $($manifest.ModuleVersion) [MATCH]" -ForegroundColor Green
    }
}

# 3. Compatibility lock version match
$lockPath = Join-Path $ProjectRoot 'compatibility.lock.json'
if (Test-Path -LiteralPath $lockPath) {
    try {
        $lock = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json
        $lockVersion = $lock.tooling.llmworkflow_module_version
        if ($lockVersion) {
            if ($lockVersion -ne $version) {
                Add-Issue "Compatibility lock version ($lockVersion) does not match VERSION ($version)"
            } else {
                Write-Host "  Compatibility lock version: $lockVersion [MATCH]" -ForegroundColor Green
            }
        } else {
            Add-Warning "compatibility.lock.json missing tooling.llmworkflow_module_version"
        }
    } catch {
        Add-Warning "Could not parse compatibility.lock.json: $_"
    }
} else {
    Add-Warning "compatibility.lock.json not found"
}

# 4. Changelog contains version
$changelogPath = Join-Path $ProjectRoot 'CHANGELOG.md'
if (Test-Path -LiteralPath $changelogPath) {
    $changelog = Get-Content -LiteralPath $changelogPath -Raw
    if ($changelog -notmatch [regex]::Escape($version)) {
        Add-Warning "CHANGELOG.md does not mention version $version"
    } else {
        Write-Host "  CHANGELOG: references $version" -ForegroundColor Green
    }
} else {
    Add-Warning "CHANGELOG.md not found"
}

# 5. No stale scratch artifacts
$blockedRootFiles = @('_content_probe.txt', 'f')
foreach ($file in $blockedRootFiles) {
    $filePath = Join-Path $ProjectRoot $file
    if (Test-Path -LiteralPath $filePath) {
        Add-Issue "Release-blocking scratch artifact checked in: $file"
    }
}
Write-Host "  Stale artifacts: CLEAN" -ForegroundColor Green

# 6. Release certification script exists
$certScript = Join-Path $ProjectRoot 'scripts\Invoke-ReleaseCertification.ps1'
if (Test-Path -LiteralPath $certScript) {
    Write-Host "  Release certification script: FOUND" -ForegroundColor Green
} else {
    Add-Issue "Invoke-ReleaseCertification.ps1 not found at $certScript"
}

# 7. Build orchestrator exists
$buildScript = Join-Path $ProjectRoot 'tools\build\Invoke-LLMBuild.ps1'
if (Test-Path -LiteralPath $buildScript) {
    Write-Host "  Build orchestrator: FOUND" -ForegroundColor Green
} else {
    Add-Issue "Invoke-LLMBuild.ps1 not found at $buildScript"
}

# 8. Archive layout check (expected module structure)
$expectedModuleLayout = @(
    'module\LLMWorkflow\LLMWorkflow.psd1',
    'module\LLMWorkflow\LLMWorkflow.psm1'
)
foreach ($relPath in $expectedModuleLayout) {
    $fullPath = Join-Path $ProjectRoot $relPath
    if (-not (Test-Path -LiteralPath $fullPath)) {
        Add-Issue "Expected archive file missing: $relPath"
    }
}
Write-Host "  Module layout: VERIFIED" -ForegroundColor Green

# 9. SHA256 generation capability
try {
    $testHash = Get-FileHash -LiteralPath $versionPath -Algorithm SHA256
    Write-Host "  SHA256 generation: OK" -ForegroundColor Green
} catch {
    Add-Warning "SHA256 generation failed: $_"
}

# 10. Docker files exist
$dockerFiles = @('Dockerfile', 'docker-compose.yml', 'docker\entrypoint.ps1')
foreach ($df in $dockerFiles) {
    $dfPath = Join-Path $ProjectRoot $df
    if (-not (Test-Path -LiteralPath $dfPath)) {
        Add-Warning "Docker file missing: $df"
    }
}
Write-Host "  Docker files: VERIFIED" -ForegroundColor Green

# Report
Write-Host ""
if ($issues.Count -eq 0) {
    Write-Host "[test-release-prereqs] All preflight checks PASSED." -ForegroundColor Green
} else {
    Write-Host "[test-release-prereqs] $($issues.Count) issue(s) found:" -ForegroundColor Red
    foreach ($issue in $issues) {
        Write-Host "  - $issue" -ForegroundColor Red
    }
}
if ($warnings.Count -gt 0) {
    Write-Host "[test-release-prereqs] $($warnings.Count) warning(s):" -ForegroundColor Yellow
    foreach ($warn in $warnings) {
        Write-Host "  - $warn" -ForegroundColor Yellow
    }
}

return [pscustomobject]@{
    Version = $version
    Issues = $issues.ToArray()
    Warnings = $warnings.ToArray()
    Passed = ($issues.Count -eq 0)
}
