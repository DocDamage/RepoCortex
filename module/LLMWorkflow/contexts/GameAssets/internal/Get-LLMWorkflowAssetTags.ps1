Set-StrictMode -Version Latest

function Get-LLMWorkflowAssetTags {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Category,

        [Parameter(Mandatory = $true)]
        [string]$AssetKind,

        $ExistingTags
    )

    $tags = New-Object System.Collections.Generic.List[string]
    foreach ($tag in @($ExistingTags)) {
        if (-not [string]::IsNullOrWhiteSpace([string]$tag) -and -not $tags.Contains([string]$tag)) {
            $tags.Add([string]$tag)
        }
    }

    foreach ($tag in @($Category, $AssetKind)) {
        if (-not [string]::IsNullOrWhiteSpace([string]$tag) -and -not $tags.Contains([string]$tag)) {
            $tags.Add([string]$tag)
        }
    }

    return @($tags)
}
