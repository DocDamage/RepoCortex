#requires -Version 5.1
Set-StrictMode -Version Latest
<#
.SYNOPSIS
    Legacy shim for golden task helper functions.
    All functions have been moved to contexts/Governance/internal/ and contexts/Governance/api/.
#>

$governanceCtx = Join-Path (Join-Path (Join-Path $PSScriptRoot '..') 'contexts') 'Governance'

foreach ($file in (Get-ChildItem -Path (Join-Path $governanceCtx 'internal') -Filter '*.ps1' -File | Sort-Object Name)) {
    if (-not (Get-Command -Name ($file.BaseName) -ErrorAction Ignore)) {
        . $file.FullName
    }
}

foreach ($file in (Get-ChildItem -Path (Join-Path $governanceCtx 'api') -Filter '*.ps1' -File | Sort-Object Name)) {
    if (-not (Get-Command -Name ($file.BaseName) -ErrorAction Ignore)) {
        . $file.FullName
    }
}
