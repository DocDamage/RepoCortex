Set-StrictMode -Version Latest

function Get-AnsiColor {
    <#
    .SYNOPSIS
        Gets ANSI color code for a status.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Status,
        
        [switch]$UseAnsi
    )
    
    if (-not $UseAnsi) { return '' }
    
    $normalizedStatus = [string]$Status
    if (-not [string]::IsNullOrWhiteSpace($normalizedStatus)) {
        $normalizedStatus = $normalizedStatus.ToLowerInvariant()
    }
    $colorName = $script:StatusColors[$normalizedStatus]
    if (-not $colorName) { $colorName = 'White' }
    
    return $script:AnsiColors[$colorName]
}

function Format-StatusIndicator {
    <#
    .SYNOPSIS
        Formats a status indicator with optional ANSI colors.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Status,
        
        [switch]$UseAnsi
    )
    
    $indicators = @{
        healthy = '[OK]'
        degraded = '[WARN]'
        critical = '[CRIT]'
        warning = '[WARN]'
        ok = '[OK]'
        notice = '[INFO]'
        compliant = '[OK]'
        active = '[ON]'
        inactive = '[OFF]'
        suspended = '[HOLD]'
        offline = '[DOWN]'
        error = '[ERR]'
        closed = '[OK]'
        open = '[OPEN]'
        half_open = '[TEST]'
    }
    
    $normalizedStatus = [string]$Status
    if (-not [string]::IsNullOrWhiteSpace($normalizedStatus)) {
        $normalizedStatus = $normalizedStatus.ToLowerInvariant()
    }

    $indicator = $indicators[$normalizedStatus]
    if (-not $indicator) { $indicator = "[$Status]" }
    
    if ($UseAnsi) {
        $color = Get-AnsiColor -Status $Status -UseAnsi
        $reset = $script:AnsiColors.Reset
        return "$color$indicator$reset"
    }
    
    return $indicator
}

function Test-AnsiSupport {
    <#
    .SYNOPSIS
        Tests if the current environment supports ANSI colors.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    
    if ($PSVersionTable.PSVersion.Major -ge 7 -and $PSVersionTable.PSVersion.Minor -ge 2) {
        return $true
    }
    if ($env:TERM -and $env:TERM -ne 'dumb') { return $true }
    if ($env:WT_SESSION) { return $true }
    $isWindowsOS = if (Get-Variable -Name 'IsWindows' -ErrorAction Ignore) { $IsWindows } else { $env:OS -eq 'Windows_NT' }
    if ($isWindowsOS -or $PSVersionTable.PSVersion.Major -lt 6) {
        return ($Host.Name -eq 'ConsoleHost')
    }
    return $false
}

function Get-HealthScoreColor {
    <#
    .SYNOPSIS
        Returns color based on health score value.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [int]$Score,
        
        [switch]$UseAnsi
    )
    
    if ($Score -ge 80) {
        return if ($UseAnsi) { $script:AnsiColors.Green } else { 'Green' }
    }
    elseif ($Score -ge 60) {
        return if ($UseAnsi) { $script:AnsiColors.Yellow } else { 'Yellow' }
    }
    else {
        return if ($UseAnsi) { $script:AnsiColors.Red } else { 'Red' }
    }
}
