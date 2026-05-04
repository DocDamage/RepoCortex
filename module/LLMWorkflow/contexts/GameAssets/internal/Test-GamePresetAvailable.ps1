Set-StrictMode -Version Latest

function Test-GamePresetAvailable {
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    return (Test-Path -LiteralPath $GamePresetPath)
}
