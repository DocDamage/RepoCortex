Set-StrictMode -Version Latest

function Initialize-HealHistoryStore {
    <#
    .SYNOPSIS
        Ensures the heal history directory and files exist.
    #>
    [CmdletBinding()]
    param()
    
    $storeDir = Split-Path -Parent $script:HealHistoryPath
    if (-not (Test-Path -LiteralPath $storeDir)) {
        New-Item -ItemType Directory -Path $storeDir -Force | Out-Null
    }
}

function Write-HealHistoryEntry {
    <#
    .SYNOPSIS
        Writes a heal operation entry to the history log.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Operation,
        
        [Parameter(Mandatory=$true)]
        [string]$IssueType,
        
        [Parameter(Mandatory=$true)]
        [string]$Status,
        
        [string]$Details = "",
        [string]$ProjectRoot = ".",
        [switch]$WhatIf
    )
    
    Initialize-HealHistoryStore
    
    $resolvedProjectRoot = Resolve-HealLiteralPath -LiteralPath $ProjectRoot -Context 'Heal history project-root resolution'

    $entry = [ordered]@{
        timestamp = [DateTime]::UtcNow.ToString("o")
        operation = $Operation
        issueType = $IssueType
        status = $Status
        details = $Details
        projectRoot = if ([string]::IsNullOrWhiteSpace($resolvedProjectRoot)) { $ProjectRoot } else { $resolvedProjectRoot }
        whatIf = $WhatIf.IsPresent
        version = Get-HealWorkflowVersion
    }
    
    $jsonLine = ($entry | ConvertTo-Json -Compress)
    Add-Content -Path $script:HealHistoryPath -Value $jsonLine -Encoding UTF8
    
    # Trim history if too large
    $lines = @(Get-HealFileLines -Path $script:HealHistoryPath -Context 'Heal history trim read')
    if (@($lines).Count -gt $script:MaxHistoryEntries) {
        $lines | Select-Object -Last $script:MaxHistoryEntries | Set-Content -Path $script:HealHistoryPath -Encoding UTF8
    }
}

function Write-HealLog {
    <#
    .SYNOPSIS
        Writes a message to the heal log file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    Initialize-HealHistoryStore
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timestamp] [$Level] $Message"
    Add-Content -Path $script:HealLogPath -Value $logLine -Encoding UTF8
}


