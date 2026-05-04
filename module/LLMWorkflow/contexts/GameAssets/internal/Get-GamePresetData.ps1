Set-StrictMode -Version Latest

function Get-GamePresetData {
    [CmdletBinding()]
    param()
    
    if (-not (Test-Path -LiteralPath $GamePresetPath)) {
        throw "Game preset not found: $GamePresetPath"
    }
    
    try {
        $content = Get-Content -LiteralPath $GamePresetPath -Raw -Encoding UTF8
        return ($content | ConvertFrom-Json)
    } catch {
        throw "Failed to parse game preset: $($_.Exception.Message)"
    }
}
