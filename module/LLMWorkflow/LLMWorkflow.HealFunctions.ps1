Set-StrictMode -Version Latest

# Legacy shim - sources Healing context functions
$ctxDir = Join-Path $PSScriptRoot 'contexts/Healing'
foreach ($shimFile in (Get-ChildItem -Path (Join-Path $ctxDir 'internal') -Filter '*.ps1' -File)) {
    . $shimFile.FullName
}
foreach ($shimFile in (Get-ChildItem -Path (Join-Path $ctxDir 'api') -Filter '*.ps1' -File)) {
    . $shimFile.FullName
}
