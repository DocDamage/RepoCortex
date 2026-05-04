Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Cross-platform path utilities for LLMWorkflow.
.DESCRIPTION
    Provides Join-Path wrappers and platform detection that work correctly
    on Windows PowerShell 5.1, PowerShell 7+ on Windows, and PowerShell 7+ on Linux/macOS.
#>

function Test-IsWindows {
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    return ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows) -or
           ($PSVersionTable.PSVersion.Major -lt 6 -and $env:OS -eq 'Windows_NT')
}

function Join-LLMPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ValueFromRemainingArguments)]
        [string[]]$PathSegments
    )
    if ($PathSegments.Count -eq 0) {
        return ''
    }
    $result = $PathSegments[0]
    for ($i = 1; $i -lt $PathSegments.Count; $i++) {
        $result = Join-Path -Path $result -ChildPath $PathSegments[$i]
    }
    return $result
}

function Get-LLMConfigRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param([string]$ProjectRoot = '.')
    return Join-LLMPath (Resolve-Path $ProjectRoot).Path '.llm-workflow'
}

function Get-LLMWorkflowLogRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param([string]$ProjectRoot = '.')
    $configRoot = Get-LLMConfigRoot -ProjectRoot $ProjectRoot
    return Join-LLMPath $configRoot 'logs'
}
