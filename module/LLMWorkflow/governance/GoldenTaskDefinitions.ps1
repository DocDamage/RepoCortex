#requires -Version 5.1
Set-StrictMode -Version Latest
<#
.SYNOPSIS
    Legacy shim for predefined golden task definitions.
    All functions have been moved to contexts/Governance/internal/Get-Predefined*.ps1
#>

$governanceCtx = Join-Path (Join-Path (Join-Path $PSScriptRoot '..') 'contexts') 'Governance'

foreach ($file in (Get-ChildItem -Path (Join-Path $governanceCtx 'internal') -Filter 'Get-Predefined*.ps1' -File | Sort-Object Name)) {
    if (-not (Get-Command -Name ($file.BaseName) -ErrorAction Ignore)) {
        . $file.FullName
    }
}

foreach ($file in (Get-ChildItem -Path (Join-Path $governanceCtx 'api') -Filter 'Get-Predefined*.ps1' -File | Sort-Object Name)) {
    if (-not (Get-Command -Name ($file.BaseName) -ErrorAction Ignore)) {
        . $file.FullName
    }
}
