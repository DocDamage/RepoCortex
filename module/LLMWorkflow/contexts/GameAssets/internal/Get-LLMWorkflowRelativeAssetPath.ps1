Set-StrictMode -Version Latest

function Get-LLMWorkflowRelativeAssetPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FullPath,

        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    $root = [System.IO.Path]::GetFullPath($ProjectPath)
    $path = [System.IO.Path]::GetFullPath($FullPath)
    if ($path.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relative = $path.Substring($root.Length).TrimStart("\", "/")
        return $relative.Replace("\", "/")
    }

    return $path.Replace("\", "/")
}
