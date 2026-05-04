Set-StrictMode -Version Latest

function Write-HealSuppressedException {
    <#
    .SYNOPSIS
        Emits verbose diagnostics for intentionally suppressed exceptions.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Context,

        [Parameter(Mandatory=$true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    Write-Verbose "[LLMWorkflow.HealFunctions] $($Context): $($ErrorRecord.Exception.Message)"
}

function Resolve-HealLiteralPath {
    <#
    .SYNOPSIS
        Resolves a literal path to an absolute path, returning $null on known non-fatal misses.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)]
        [string]$LiteralPath,

        [string]$Context = 'Path resolution'
    )

    try {
        return (Resolve-Path -LiteralPath $LiteralPath -ErrorAction Stop | Select-Object -ExpandProperty Path -First 1)
    } catch [System.Management.Automation.ItemNotFoundException] {
        return $null
    } catch {
        Write-HealSuppressedException -Context "$Context for '$LiteralPath'" -ErrorRecord $_
        return $null
    }
}

function Get-HealCommandPath {
    <#
    .SYNOPSIS
        Resolves an executable command name to a source path.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)]
        [string]$CommandName,

        [string]$Context = 'Command resolution'
    )

    try {
        $command = Get-Command -Name $CommandName -ErrorAction Stop | Select-Object -First 1
        if ($null -eq $command) {
            return $null
        }
        return [string]$command.Source
    } catch [System.Management.Automation.CommandNotFoundException] {
        return $null
    } catch {
        Write-HealSuppressedException -Context "$Context for '$CommandName'" -ErrorRecord $_
        return $null
    }
}

function Get-HealChildItems {
    <#
    .SYNOPSIS
        Safely enumerates child items for wildcard and direct paths.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [ValidateSet('Any', 'File', 'Directory')]
        [string]$ItemType = 'Any',

        [string]$Context = 'Child item enumeration'
    )

    $params = @{
        Path = $Path
        ErrorAction = 'Stop'
    }
    switch ($ItemType) {
        'File' { $params['File'] = $true }
        'Directory' { $params['Directory'] = $true }
    }

    try {
        return @(Get-ChildItem @params)
    } catch [System.Management.Automation.ItemNotFoundException] {
        return @()
    } catch {
        Write-HealSuppressedException -Context "$Context for '$Path'" -ErrorRecord $_
        return @()
    }
}

function Get-HealFileLines {
    <#
    .SYNOPSIS
        Safely reads file lines, returning an empty array if unavailable.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [string]$Context = 'File read'
    )

    try {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            return @()
        }
        return @(Get-Content -Path $Path -ErrorAction Stop)
    } catch [System.Management.Automation.ItemNotFoundException] {
        return @()
    } catch {
        Write-HealSuppressedException -Context "$Context for '$Path'" -ErrorRecord $_
        return @()
    }
}

function Get-HealWorkflowVersion {
    <#
    .SYNOPSIS
        Gets the workflow version used in heal-history entries with a safe fallback.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    try {
        $versionCommand = Get-Command -Name 'Get-LLMWorkflowVersion' -ErrorAction Stop
        if ($null -eq $versionCommand) {
            return 'unknown'
        }

        $versionInfo = Get-LLMWorkflowVersion
        if ($null -ne $versionInfo -and $versionInfo.PSObject.Properties.Name -contains 'manifestVersion') {
            $manifestVersion = [string]$versionInfo.manifestVersion
            if (-not [string]::IsNullOrWhiteSpace($manifestVersion)) {
                return $manifestVersion
            }
        }
    } catch [System.Management.Automation.CommandNotFoundException] {
        return 'unknown'
    } catch {
        Write-HealSuppressedException -Context 'Workflow version lookup' -ErrorRecord $_
    }

    return 'unknown'
}


