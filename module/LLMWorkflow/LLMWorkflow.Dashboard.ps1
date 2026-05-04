#requires -Version 5.1
<#
.SYNOPSIS
    Legacy shim for LLM Workflow Dashboard.
.DESCRIPTION
    Sources the decomposed Telemetry context and invokes the dashboard main function.
    Kept for backward compatibility with direct script invocation.
#>
[CmdletBinding()]
param(
    [string]$ProjectRoot = ".",
    [ValidateSet("auto", "openai", "claude", "kimi", "gemini", "glm", "ollama")]
    [string]$Provider = "auto",
    [switch]$CheckContext,
    [int]$TimeoutSec = 10,
    [switch]$NoInteractive,
    [int]$RefreshInterval = 0
)

Set-StrictMode -Version Latest

$ctxDir = Join-Path $PSScriptRoot 'contexts/Telemetry'
foreach ($shimFile in (Get-ChildItem -Path (Join-Path $ctxDir 'internal') -Filter '*.ps1' -File)) {
    . $shimFile.FullName
}
foreach ($shimFile in (Get-ChildItem -Path (Join-Path $ctxDir 'api') -Filter '*.ps1' -File)) {
    . $shimFile.FullName
}

Invoke-LLMWorkflowDashboardMain -ProjectRoot $ProjectRoot -Provider $Provider -CheckContext:$CheckContext -TimeoutSec $TimeoutSec -NoInteractive:$NoInteractive -RefreshInterval $RefreshInterval
