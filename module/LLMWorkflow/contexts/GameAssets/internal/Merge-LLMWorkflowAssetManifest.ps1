Set-StrictMode -Version Latest

function Merge-LLMWorkflowAssetManifest {
    [CmdletBinding()]
    param(
        $ExistingManifest,

        [Parameter(Mandatory = $true)]
        [string]$ProjectName
    )

    $manifest = New-LLMWorkflowDefaultAssetManifest -ProjectName $ProjectName
    if ($null -eq $ExistingManifest) {
        return $manifest
    }

    foreach ($propertyName in @("project", "version", "created", "lastUpdated")) {
        $property = $ExistingManifest.PSObject.Properties[$propertyName]
        if ($null -ne $property -and -not [string]::IsNullOrWhiteSpace([string]$property.Value)) {
            $manifest[$propertyName] = $property.Value
        }
    }

    if ($null -ne $ExistingManifest.PSObject.Properties["templates"] -and $null -ne $ExistingManifest.templates) {
        foreach ($templateProperty in $ExistingManifest.templates.PSObject.Properties) {
            $manifest.templates[$templateProperty.Name] = $templateProperty.Value
        }
    }

    if ($null -ne $ExistingManifest.PSObject.Properties["exampleAssets"] -and $null -ne $ExistingManifest.exampleAssets) {
        $manifest.exampleAssets = @($ExistingManifest.exampleAssets)
    }

    if ($null -ne $ExistingManifest.PSObject.Properties["categories"] -and $null -ne $ExistingManifest.categories) {
        foreach ($categoryProperty in $ExistingManifest.categories.PSObject.Properties) {
            if (-not $manifest.categories.Contains($categoryProperty.Name)) {
                $manifest.categories[$categoryProperty.Name] = [ordered]@{
                    description = "Imported legacy category"
                    folder = "assets/$($categoryProperty.Name)"
                    assetCount = 0
                    assets = @()
                }
            }

            if ($null -ne $categoryProperty.Value.PSObject.Properties["description"] -and
                -not [string]::IsNullOrWhiteSpace([string]$categoryProperty.Value.description)) {
                $manifest.categories[$categoryProperty.Name].description = $categoryProperty.Value.description
            }

            if ($null -ne $categoryProperty.Value.PSObject.Properties["folder"] -and
                -not [string]::IsNullOrWhiteSpace([string]$categoryProperty.Value.folder)) {
                $manifest.categories[$categoryProperty.Name].folder = $categoryProperty.Value.folder
            }

            if ($null -ne $categoryProperty.Value.PSObject.Properties["assets"] -and $null -ne $categoryProperty.Value.assets) {
                $manifest.categories[$categoryProperty.Name].assets = @($categoryProperty.Value.assets)
                $manifest.categories[$categoryProperty.Name].assetCount = @($categoryProperty.Value.assets).Count
            }
        }
    }

    if ($null -ne $ExistingManifest.PSObject.Properties["licenseSummary"] -and $null -ne $ExistingManifest.licenseSummary) {
        foreach ($licenseProperty in $ExistingManifest.licenseSummary.PSObject.Properties) {
            $manifest.licenseSummary[$licenseProperty.Name] = $licenseProperty.Value
        }
    }

    return $manifest
}
