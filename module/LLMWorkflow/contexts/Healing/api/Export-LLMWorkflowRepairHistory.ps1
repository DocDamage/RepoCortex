Set-StrictMode -Version Latest

function Export-LLMWorkflowRepairHistory {
    <#
    .SYNOPSIS
        Exports repair history to a file.
    .DESCRIPTION
        Exports the repair history to JSON or CSV format.
    .PARAMETER OutputPath
        Path to the output file.
    .PARAMETER Format
        Output format: json or csv.
    .EXAMPLE
        Export-LLMWorkflowRepairHistory -OutputPath "repairs.json"
        Exports history to JSON file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [ValidateSet("json", "csv")]
        [string]$Format = "json"
    )
    
    $entries = Get-LLMWorkflowRepairHistory -Count 10000
    
    switch ($Format) {
        "json" {
            $entries | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding UTF8
        }
        "csv" {
            $entries | ForEach-Object {
                [pscustomobject]@{
                    Timestamp = $_.timestamp
                    Operation = $_.operation
                    IssueType = $_.issueType
                    Status = $_.status
                    Details = $_.details
                    ProjectRoot = $_.projectRoot
                    WhatIf = $_.whatIf
                    Version = $_.version
                }
            } | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        }
    }
    
    Write-Information "Exported $($entries.Count) entries to: $OutputPath" -InformationAction Continue
}

#===============================================================================
# Main Heal Function
#===============================================================================

