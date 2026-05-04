Set-StrictMode -Version Latest

function Get-LLMWorkflowRepairHistory {
    <#
    .SYNOPSIS
        Retrieves the history of repair operations.
    .DESCRIPTION
        Shows past fixes applied by llmheal, including timestamps, issue types, and outcomes.
    .PARAMETER Count
        Number of recent entries to show (default: 50).
    .PARAMETER Since
        Only show entries since this date/time.
    .PARAMETER IssueType
        Filter by specific issue type.
    .PARAMETER ProjectRoot
        Filter by project root path.
    .EXAMPLE
        Get-LLMWorkflowRepairHistory
        Shows the last 50 repair operations.
    .EXAMPLE
        Get-LLMWorkflowRepairHistory -Count 10 -Since (Get-Date).AddDays(-7)
        Shows the last 10 repairs from the past week.
    #>
    [CmdletBinding()]
    [OutputType([array])]
    param(
        [int]$Count = 50,
        [DateTime]$Since = [DateTime]::MinValue,
        [IssueType[]]$IssueType = @(),
        [string]$ProjectRoot = ""
    )
    
    if (-not (Test-Path -LiteralPath $script:HealHistoryPath)) {
        Write-Verbose "No repair history found at: $script:HealHistoryPath"
        return @()
    }
    
    $entries = Get-Content -Path $script:HealHistoryPath | ForEach-Object {
        try {
            $_ | ConvertFrom-Json
        } catch {
            $null
        }
    } | Where-Object { $_ -ne $null }
    
    # Apply filters
    if ($Since -ne [DateTime]::MinValue) {
        $entries = $entries | Where-Object { 
            $entryTime = [DateTime]::Parse($_.timestamp)
            $entryTime -ge $Since
        }
    }
    
    if ($IssueType.Count -gt 0) {
        $typeNames = $IssueType | ForEach-Object { $_.ToString() }
        $entries = $entries | Where-Object { $typeNames -contains $_.issueType }
    }
    
    if (-not [string]::IsNullOrWhiteSpace($ProjectRoot)) {
        $resolvedRoot = Resolve-HealLiteralPath -LiteralPath $ProjectRoot -Context 'Repair-history project-root resolution'
        if ($resolvedRoot) {
            $entries = $entries | Where-Object { $_.projectRoot -eq $resolvedRoot }
        }
    }
    
    # Sort by timestamp (newest first) and take requested count
    $entries = $entries | Sort-Object { [DateTime]::Parse($_.timestamp) } -Descending | Select-Object -First $Count
    
    return $entries
}

