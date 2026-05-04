Set-StrictMode -Version Latest

function Test-InteractiveShell {
    [CmdletBinding()]
    param()
    
    if ($NoInteractive) { return $false }
    if ($env:CI -or $env:TF_BUILD -or $env:GITHUB_ACTIONS -or $env:JENKINS_HOME) { return $false }
    
    try {
        if (-not $Host.UI.RawUI) { return $false }
        if ($Host.Name -match "ISE|Visual Studio Code") { return $true }
        if ($Host.Name -eq "ConsoleHost") { return $true }
    } catch {
        return $false
    }
    
    return $true
}

function Test-AnsiSupport {
    [CmdletBinding()]
    param()
    
    if ($PSVersionTable.PSVersion.Major -ge 7 -and $PSVersionTable.PSVersion.Minor -ge 2) {
        return $true
    }
    if ($env:TERM -and $env:TERM -ne "dumb") { return $true }
    if ($env:WT_SESSION) { return $true }
    $isWindowsPlatform = ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows) -or ($PSVersionTable.PSVersion.Major -lt 6 -and $env:OS -eq 'Windows_NT')
    if ($isWindowsPlatform) {
        return ($Host.Name -eq "ConsoleHost")
    }
    return $false
}

function Write-DashboardSuppressedException {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Context,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    # Surface suppressed diagnostics as warnings so operators can see degradation
    # without needing Verbose logging enabled.
    Write-Warning "[LLMWorkflow.Dashboard] $($Context): $($ErrorRecord.Exception.Message)"
    Write-Verbose "[LLMWorkflow.Dashboard] $($Context) full error: $($ErrorRecord | Out-String)"
}

function Get-DashboardCommand {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.CommandInfo])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    try {
        return (Get-Command -Name $Name -ErrorAction Stop | Select-Object -First 1)
    } catch [System.Management.Automation.CommandNotFoundException] {
        return $null
    } catch {
        Write-DashboardSuppressedException -Context "Command probe for '$Name'" -ErrorRecord $_
        return $null
    }
}

function Get-DashboardCheckStatus {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Check
    )

    if ($Check.Ok) {
        return "OK"
    }

    if ($Check.Name -in @("python_version", "codemunch_version", "chromadb_version") -and $Check.Detail -match "^Found\s+") {
        return "WARN"
    }
    if ($Check.Name -eq "contextlattice_env" -and $Check.Detail -match "^Need\s+") {
        return "WARN"
    }
    if ($Check.Name -in @("contextlattice_health", "contextlattice_status") -and $Check.Detail -match "^Missing context env vars") {
        return "WARN"
    }

    return "FAIL"
}

#endregion

#region Core Check Functions

