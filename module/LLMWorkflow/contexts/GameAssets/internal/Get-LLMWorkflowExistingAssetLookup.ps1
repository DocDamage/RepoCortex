Set-StrictMode -Version Latest

function Get-LLMWorkflowExistingAssetLookup {
    [CmdletBinding()]
    param(
        $Manifest
    )

    $lookup = @{}
    if ($null -eq $Manifest -or $null -eq $Manifest.categories) {
        return $lookup
    }

    $categoryNames = if ($Manifest.categories -is [System.Collections.IDictionary]) {
        @($Manifest.categories.Keys)
    } else {
        @($Manifest.categories.PSObject.Properties.Name)
    }

    foreach ($categoryName in $categoryNames) {
        $categoryValue = if ($Manifest.categories -is [System.Collections.IDictionary]) {
            $Manifest.categories[$categoryName]
        } else {
            $Manifest.categories.PSObject.Properties[$categoryName].Value
        }

        foreach ($asset in @($categoryValue.assets)) {
            if ($null -eq $asset -or [string]::IsNullOrWhiteSpace($asset.path)) {
                continue
            }

            $lookup[$asset.path.ToLowerInvariant()] = $asset
        }
    }

    return $lookup
}
