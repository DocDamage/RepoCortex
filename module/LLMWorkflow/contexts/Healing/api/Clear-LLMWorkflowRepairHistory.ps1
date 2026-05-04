Set-StrictMode -Version Latest

function Clear-LLMWorkflowRepairHistory {
    <#
    .SYNOPSIS
        Clears the repair history log.
    .DESCRIPTION
        Removes all repair history entries. Use with caution.
    .PARAMETER Confirm
        Confirm the deletion.
    .EXAMPLE
        Clear-LLMWorkflowRepairHistory -Confirm
        Clears all repair history after confirmation.
    #>
    [CmdletBinding()]
    param(
        [switch]$Confirm
    )
    
    if (-not $Confirm) {
        Write-Warning "Use -Confirm to clear repair history. This action cannot be undone."
        return
    }
    
    if (Test-Path -LiteralPath $script:HealHistoryPath) {
        Remove-Item -LiteralPath $script:HealHistoryPath -Force
        Write-Information "Repair history cleared." -InformationAction Continue
    } else {
        Write-Information "No repair history to clear." -InformationAction Continue
    }
}

