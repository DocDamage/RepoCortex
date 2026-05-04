Set-StrictMode -Version Latest

# Legacy shim - sources GameAssets context functions
$GameTemplateRoot = Join-Path (Join-Path $PSScriptRoot 'templates') 'game'
$GamePresetPath = Join-Path $GameTemplateRoot "game-preset.json"

$ctxDir = Join-Path $PSScriptRoot 'contexts/GameAssets'
foreach ($shimFile in (Get-ChildItem -Path (Join-Path $ctxDir 'internal') -Filter '*.ps1' -File)) {
    . $shimFile.FullName
}
foreach ($shimFile in (Get-ChildItem -Path (Join-Path $ctxDir 'api') -Filter '*.ps1' -File)) {
    . $shimFile.FullName
}
