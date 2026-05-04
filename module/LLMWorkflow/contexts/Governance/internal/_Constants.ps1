#requires -Version 5.1
Set-StrictMode -Version Latest

$script:GoldenTaskModuleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))

# Module-level configuration
$script:GoldenTaskConfig = @{
    Version = '1.0.0'
    ResultsDirectory = Join-Path (Join-Path $script:GoldenTaskModuleRoot 'data') 'golden-tasks'
    SuitesDirectory = Join-Path (Join-Path $script:GoldenTaskModuleRoot 'data') 'golden-suites'
    DefaultMinConfidence = 0.8
    MaxParallelJobs = 4
    HistoryRetentionDays = 365
}

# Ensure directories exist
if (-not (Test-Path $script:GoldenTaskConfig.ResultsDirectory)) {
    $null = New-Item -ItemType Directory -Path $script:GoldenTaskConfig.ResultsDirectory -Force
}
if (-not (Test-Path $script:GoldenTaskConfig.SuitesDirectory)) {
    $null = New-Item -ItemType Directory -Path $script:GoldenTaskConfig.SuitesDirectory -Force
}
