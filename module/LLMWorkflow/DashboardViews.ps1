Set-StrictMode -Version Latest

# Legacy shim - sources Telemetry context functions
$ctxDir = Join-Path $PSScriptRoot 'contexts/Telemetry'
foreach ($shimFile in (Get-ChildItem -Path (Join-Path $ctxDir 'internal') -Filter '*.ps1' -File)) {
    . $shimFile.FullName
}
foreach ($shimFile in (Get-ChildItem -Path (Join-Path $ctxDir 'api') -Filter '*.ps1' -File)) {
    . $shimFile.FullName
}
