Set-StrictMode -Version Latest

function Repair-LLMWorkflowIssue {
    <#
    .SYNOPSIS
        Repairs a specific issue in the LLM Workflow environment.
    .DESCRIPTION
        Attempts to fix a detected issue automatically. Returns repair result details.
    .PARAMETER IssueType
        The type of issue to repair.
    .PARAMETER ProjectRoot
        Path to the project root.
    .PARAMETER WhatIf
        Show what would be done without making changes.
    .PARAMETER Force
        Auto-apply fixes without prompting.
    .PARAMETER Interactive
        Show prompts for user input when needed.
    .EXAMPLE
        Repair-LLMWorkflowIssue -IssueType MissingEnvFile -Force
        Creates a .env file from template without prompting.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory=$true)]
        [IssueType]$IssueType,

        [string]$ProjectRoot = ".",
        [switch]$WhatIf,
        [switch]$Force,
        [switch]$Interactive
    )

    $projectPath = Resolve-HealLiteralPath -LiteralPath $ProjectRoot -Context 'Issue repair project-root resolution'
    if (-not $projectPath) {
        return @{
            Success = $false
            IssueType = $IssueType
            Message = "Project root does not exist: $ProjectRoot"
            Changes = @()
        }
    }

    $repairParams = @{
        ProjectPath = $projectPath
        ProjectRoot = $ProjectRoot
        WhatIf = $WhatIf
        Force = $Force
        Interactive = $Interactive
    }

    try {
        switch ($IssueType) {
            "MissingEnvFile" { return (Repair-HealingIssue_MissingEnvFile @repairParams) }
            "InvalidPythonPath" { return (Repair-HealingIssue_InvalidPythonPath @repairParams) }
            "MissingChromaDB" { return (Repair-HealingIssue_MissingChromaDB @repairParams) }
            "MissingPalaceDirectory" { return (Repair-HealingIssue_MissingPalaceDirectory @repairParams) }
            "CorruptedSyncState" { return (Repair-HealingIssue_CorruptedSyncState @repairParams) }
            "TemplateDrift" { return (Repair-HealingIssue_TemplateDrift @repairParams) }
            "MissingContextLatticeApiKey" { return (Repair-HealingIssue_MissingContextLatticeApiKey @repairParams) }
            "MissingContextLatticeUrl" { return (Repair-HealingIssue_MissingContextLatticeUrl @repairParams) }
            "MissingBridgeConfig" { return (Repair-HealingIssue_MissingBridgeConfig @repairParams) }
            "CorruptedBridgeConfig" { return (Repair-HealingIssue_CorruptedBridgeConfig @repairParams) }
            default {
                return @{
                    Success = $false
                    IssueType = $IssueType
                    Message = "Unknown issue type: $IssueType"
                    Changes = @("No repair action defined for this issue type")
                }
            }
        }
    } catch {
        $errMsg = "Exception during repair: $($_.Exception.Message)"
        Write-HealLog -Message "Exception repairing $IssueType`: $errMsg" -Level "ERROR"
        return @{
            Success = $false
            IssueType = $IssueType
            Message = $errMsg
            Changes = @("Error: $errMsg")
        }
    }
}
