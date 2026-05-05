#requires -Version 5.1
<#
.SYNOPSIS
    Restores the repo-local Pester version used by invoke-pester-safe.ps1.

.DESCRIPTION
    Downloads Pester 5.7.1 into modules/Pester/5.7.1. The modules/Pester
    directory is intentionally ignored by git so the repository can use a
    reproducible local test dependency without vendoring the full module.
#>
[CmdletBinding()]
param(
    [string]$Version = '5.7.1',
    [string]$ProjectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
)

$ErrorActionPreference = 'Stop'

$moduleRoot = Join-Path $ProjectRoot 'modules'
$manifestPath = Join-Path $moduleRoot "Pester\$Version\Pester.psd1"

if (Test-Path -LiteralPath $manifestPath) {
    $manifest = Import-PowerShellDataFile -Path $manifestPath
    if ($manifest.ModuleVersion -eq $Version) {
        Write-Output "Pester $Version already installed at $manifestPath"
        return [pscustomobject]@{
            Installed = $true
            Version = $Version
            Path = $manifestPath
            Changed = $false
        }
    }
}

New-Item -ItemType Directory -Path $moduleRoot -Force | Out-Null
Save-Module -Name Pester -RequiredVersion $Version -Path $moduleRoot -Force

if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "Pester $Version install did not produce expected manifest: $manifestPath"
}

Write-Output "Pester $Version installed at $manifestPath"
return [pscustomobject]@{
    Installed = $true
    Version = $Version
    Path = $manifestPath
    Changed = $true
}
