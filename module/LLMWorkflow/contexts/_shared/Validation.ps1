Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Reusable parameter validation attributes and helpers for LLMWorkflow.
#>

function Test-LLMIsValidProvider {
    [CmdletBinding()]
    [OutputType([bool])]
    param([string]$Provider)
    $valid = @('auto','openai','kimi','gemini','glm','claude','ollama')
    return $valid -contains $Provider
}

function Test-LLMIsValidGameEngine {
    [CmdletBinding()]
    [OutputType([bool])]
    param([string]$Engine)
    $valid = @('Godot','Blender','RPGMaker','Unreal','Unity')
    return $valid -contains $Engine
}

function Assert-LLMProjectRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot
    )
    if (-not (Test-Path -LiteralPath $ProjectRoot)) {
        throw "Project root not found: $ProjectRoot"
    }
}
