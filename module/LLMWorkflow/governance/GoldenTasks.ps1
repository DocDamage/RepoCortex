#requires -Version 5.1
Set-StrictMode -Version Latest
<#
.SYNOPSIS
    Golden Tasks Evaluation Module for LLM Workflow Platform - Phase 6

.DESCRIPTION
    Legacy shim that dot-sources the decomposed Governance context files.
    All functions have been moved to contexts/Governance/ for the Modular Monolith architecture.
#>

# Backward-compatible configuration for direct dot-sourcing
$script:GoldenTaskModuleRoot = Split-Path -Parent $PSScriptRoot
$script:GoldenTaskConfig = @{
    Version = '1.0.0'
    ResultsDirectory = Join-Path (Join-Path $script:GoldenTaskModuleRoot 'data') 'golden-tasks'
    SuitesDirectory = Join-Path (Join-Path $script:GoldenTaskModuleRoot 'data') 'golden-suites'
    DefaultMinConfidence = 0.8
    MaxParallelJobs = 4
    HistoryRetentionDays = 365
}

if (-not (Test-Path $script:GoldenTaskConfig.ResultsDirectory)) {
    $null = New-Item -ItemType Directory -Path $script:GoldenTaskConfig.ResultsDirectory -Force
}
if (-not (Test-Path $script:GoldenTaskConfig.SuitesDirectory)) {
    $null = New-Item -ItemType Directory -Path $script:GoldenTaskConfig.SuitesDirectory -Force
}

# Dot-source decomposed Governance context files
$governanceCtx = Join-Path (Join-Path (Join-Path $PSScriptRoot '..') 'contexts') 'Governance'

$internalDir = Join-Path $governanceCtx 'internal'
if (Test-Path -LiteralPath $internalDir) {
    foreach ($file in (Get-ChildItem -Path $internalDir -Filter '*.ps1' -File | Sort-Object Name)) {
        . $file.FullName
    }
}

$apiDir = Join-Path $governanceCtx 'api'
if (Test-Path -LiteralPath $apiDir) {
    foreach ($file in (Get-ChildItem -Path $apiDir -Filter '*.ps1' -File | Sort-Object Name)) {
        . $file.FullName
    }
}

# Legacy helper shims (now empty; kept for load-order compatibility)
$legacyHelpers = @('GoldenTaskDefinitions.ps1', 'GoldenTaskHelpers.ps1')
foreach ($helperFile in $legacyHelpers) {
    $helperPath = Join-Path $PSScriptRoot $helperFile
    if (Test-Path -LiteralPath $helperPath) {
        . $helperPath
    }
}

Export-ModuleMember -Function @(
    'New-GoldenTask'
    'Invoke-GoldenTask'
    'Test-GoldenTaskResult'
    'Get-GoldenTaskScore'
    'Get-GoldenTaskMetrics'
    'Export-GoldenTaskReport'
    'Export-GoldenTaskResults'
    'Invoke-PackGoldenTasks'
    'Get-PredefinedGoldenTasks'
    'Get-GoldenTaskResults'
    'New-GoldenTaskSuite'
    'Export-GoldenTaskSuite'
    'Import-GoldenTaskSuite'
    'Invoke-GoldenTaskSuite'
    'Compare-GoldenTaskRuns'
    'Test-PropertyBasedExpectation'
)
