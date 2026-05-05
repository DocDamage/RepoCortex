Set-StrictMode -Version Latest

#===============================================================================
# Private Helper Functions
#===============================================================================

function Write-DashboardSuppressedException {
    <#
    .SYNOPSIS
        Emits diagnostics for intentionally suppressed dashboard exceptions.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Context,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    # Surface suppressed diagnostics as warnings so operators can see degradation
    # without needing Verbose logging enabled.
    Write-Warning "[DashboardViews] $($Context): $($ErrorRecord.Exception.Message)"
    Write-Verbose "[DashboardViews] $($Context) full error: $($ErrorRecord | Out-String)"
}

function Get-DashboardCommand {
    <#
    .SYNOPSIS
        Resolves a command if available and returns $null when absent.
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.CommandInfo])]
    param(
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [string]$CommandName
    )

    try {
        return (Get-Command -Name $CommandName -ErrorAction Stop | Select-Object -First 1)
    }
    catch [System.Management.Automation.CommandNotFoundException] {
        return $null
    }
    catch {
        Write-DashboardSuppressedException -Context "Command probe for '$CommandName'" -ErrorRecord $_
        return $null
    }
}

function Get-DashboardChildItems {
    <#
    .SYNOPSIS
        Safely enumerates child items for dashboards.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter()]
        [string]$Filter = '',

        [ValidateSet('Any', 'File', 'Directory')]
        [string]$ItemType = 'Any',

        [string]$Context = 'Child item enumeration'
    )

    $params = @{
        Path = $Path
        ErrorAction = 'Stop'
    }

    if (-not [string]::IsNullOrWhiteSpace($Filter)) {
        $params['Filter'] = $Filter
    }

    switch ($ItemType) {
        'File' { $params['File'] = $true }
        'Directory' { $params['Directory'] = $true }
    }

    try {
        return @(Get-ChildItem @params)
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        return @()
    }
    catch {
        Write-DashboardSuppressedException -Context "$Context at '$Path'" -ErrorRecord $_
        return @()
    }
}
