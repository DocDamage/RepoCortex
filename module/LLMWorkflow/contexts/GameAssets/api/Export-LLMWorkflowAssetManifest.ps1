Set-StrictMode -Version Latest

function Export-LLMWorkflowAssetManifest {
    <#
    .SYNOPSIS
        Generates or updates the asset tracking manifest.
    .DESCRIPTION
        Scans asset folders and generates a manifest with metadata and license tracking.
    .PARAMETER ProjectRoot
        Path to the project root. Defaults to current directory.
    .PARAMETER ScanFolders
        Scan asset folders for files and update the manifest.
    .PARAMETER OutputPath
        Custom output path for the manifest.
    .PARAMETER Format
        Output format (json or csv).
    .EXAMPLE
        Export-LLMWorkflowAssetManifest -ScanFolders
        Scans assets and updates the manifest.
    .EXAMPLE
        Export-LLMWorkflowAssetManifest -Format csv -OutputPath "assets/export.csv"
        Exports manifest to CSV format.
    #>
    [OutputType([pscustomobject])]
    [CmdletBinding()]
    param(
        [string]$ProjectRoot = ".",
        [switch]$ScanFolders,
        [string]$OutputPath = "",
        [ValidateSet("json", "csv")]
        [string]$Format = "json",
        [ValidateSet("inventory", "deep")]
        [string]$ExtractionDepth = "inventory"
    )
    
    $projectPath = Resolve-Path -LiteralPath $ProjectRoot
    $manifestPath = Join-Path (Join-Path $projectPath 'assets') 'ASSET_MANIFEST.json'
    
    # Load or create manifest
    $manifest = $null
    if (Test-Path -LiteralPath $manifestPath) {
        try {
            $content = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8
            $manifest = $content | ConvertFrom-Json
        } catch {
            Write-Warning "Failed to parse existing manifest, creating new one"
            $manifest = $null
        }
    }
    
    # Initialize default structure if needed
    if ($null -eq $manifest) {
        $manifest = New-LLMWorkflowDefaultAssetManifest -ProjectName (Split-Path -Leaf $projectPath)
    } else {
        $manifest = Merge-LLMWorkflowAssetManifest -ExistingManifest $manifest -ProjectName (Split-Path -Leaf $projectPath)
    }
    $manifest.lastUpdated = (Get-Date -Format "yyyy-MM-dd")
    $manifest.extractionDepth = $ExtractionDepth
    $manifest.provenance = [ordered]@{
        generatedBy = 'LLMWorkflow.GameFunctions'
        generatedAt = [DateTime]::UtcNow.ToString('o')
        projectRoot = $ProjectRoot
    }

    # Scan folders if requested
    if ($ScanFolders) {
        Write-Host "[gameteam] Scanning asset folders..." -ForegroundColor Cyan

        $totalCount = 0
        $totalSize = 0
        $licenseCounts = New-LLMWorkflowDefaultLicenseSummary
        $existingAssets = Get-LLMWorkflowExistingAssetLookup -Manifest $manifest
        $categorySequence = @($manifest.categories.Keys)
        $categoryCounters = @{}

        foreach ($categoryName in $categorySequence) {
            $manifest.categories[$categoryName].assets = @()
            $manifest.categories[$categoryName].assetCount = 0
            $categoryCounters[$categoryName] = 0
        }

        $assetsRoot = Join-Path $projectPath "assets"
        if (Test-Path -LiteralPath $assetsRoot) {
            $files = Get-ChildItem -LiteralPath $assetsRoot -File -Recurse |
                Where-Object { $_.Name -ne "ASSET_MANIFEST.json" }

            foreach ($file in $files) {
                $relativePath = Get-LLMWorkflowRelativeAssetPath -FullPath $file.FullName -ProjectPath $projectPath
                $extension = $file.Extension.ToLowerInvariant()
                $category = Get-LLMWorkflowAssetCategory -RelativePath $relativePath -Extension $extension
                $assetKind = Get-LLMWorkflowAssetKind -Category $category -RelativePath $relativePath -Extension $extension
                $engineFamily = Get-LLMWorkflowAssetEngineFamily -Category $category
                $existingAsset = $existingAssets[$relativePath.ToLowerInvariant()]

                if (-not $manifest.categories.Contains($category)) {
                    $manifest.categories[$category] = [ordered]@{
                        description = "Discovered during asset scan"
                        folder = "assets/$category"
                        assetCount = 0
                        assets = @()
                    }
                    $categoryCounters[$category] = 0
                    $categorySequence += $category
                }

                $categoryCounters[$category]++
                $assetId = if ($null -ne $existingAsset -and -not [string]::IsNullOrWhiteSpace([string]$existingAsset.id)) {
                    [string]$existingAsset.id
                } else {
                    "{0}-{1:D3}" -f $category, $categoryCounters[$category]
                }

                $license = if ($null -ne $existingAsset -and -not [string]::IsNullOrWhiteSpace([string]$existingAsset.license)) {
                    [string]$existingAsset.license
                } else {
                    "unknown"
                }

                $asset = [ordered]@{
                    id = $assetId
                    name = if ($null -ne $existingAsset -and -not [string]::IsNullOrWhiteSpace([string]$existingAsset.name)) { [string]$existingAsset.name } else { $file.BaseName }
                    fileName = $file.Name
                    path = $relativePath
                    category = $category
                    assetKind = $assetKind
                    engineFamily = $engineFamily
                    format = $file.Extension.TrimStart(".").ToLowerInvariant()
                    dimensions = if ($null -ne $existingAsset -and $null -ne $existingAsset.PSObject.Properties["dimensions"]) { [string]$existingAsset.dimensions } else { "" }
                    duration = if ($null -ne $existingAsset -and $null -ne $existingAsset.PSObject.Properties["duration"]) { [string]$existingAsset.duration } else { "" }
                    fileSize = Format-LLMWorkflowAssetFileSize -Bytes $file.Length
                    fileSizeBytes = [long]$file.Length
                    tags = Get-LLMWorkflowAssetTags -Category $category -AssetKind $assetKind -ExistingTags $(if ($null -ne $existingAsset) { $existingAsset.tags } else { @() })
                    status = if ($null -ne $existingAsset -and -not [string]::IsNullOrWhiteSpace([string]$existingAsset.status)) { [string]$existingAsset.status } else { "done" }
                    priority = if ($null -ne $existingAsset -and -not [string]::IsNullOrWhiteSpace([string]$existingAsset.priority)) { [string]$existingAsset.priority } else { "p2" }
                    assignedTo = if ($null -ne $existingAsset -and $null -ne $existingAsset.PSObject.Properties["assignedTo"]) { [string]$existingAsset.assignedTo } else { "" }
                    createdDate = if ($null -ne $existingAsset -and -not [string]::IsNullOrWhiteSpace([string]$existingAsset.createdDate)) { [string]$existingAsset.createdDate } else { $file.CreationTime.ToString("yyyy-MM-dd") }
                    modifiedDate = $file.LastWriteTime.ToString("yyyy-MM-dd")
                    source = if ($null -ne $existingAsset -and -not [string]::IsNullOrWhiteSpace([string]$existingAsset.source)) { [string]$existingAsset.source } else { Get-LLMWorkflowDefaultAssetSource -Category $category }
                    sourceUrl = if ($null -ne $existingAsset -and $null -ne $existingAsset.PSObject.Properties["sourceUrl"]) { [string]$existingAsset.sourceUrl } else { "" }
                    license = $license
                    licenseUrl = if ($null -ne $existingAsset -and $null -ne $existingAsset.PSObject.Properties["licenseUrl"]) { [string]$existingAsset.licenseUrl } else { "" }
                    author = if ($null -ne $existingAsset -and $null -ne $existingAsset.PSObject.Properties["author"]) { [string]$existingAsset.author } else { "" }
                    notes = if ($null -ne $existingAsset -and $null -ne $existingAsset.PSObject.Properties["notes"]) { [string]$existingAsset.notes } else { "" }
                }

                $manifest.categories[$category].assets += $asset
                $manifest.categories[$category].assetCount = @($manifest.categories[$category].assets).Count
                $totalCount++
                $totalSize += $file.Length

                $licenseKey = Get-LLMWorkflowLicenseSummaryKey -License $license
                $licenseCounts[$licenseKey]++
            }
        }

        foreach ($categoryName in $categorySequence) {
            $manifest.categories[$categoryName].assetCount = @($manifest.categories[$categoryName].assets).Count
        }

        $manifest.assetCount = $totalCount
        $manifest.totalSize = Format-LLMWorkflowAssetFileSize -Bytes $totalSize
        $manifest.licenseSummary = $licenseCounts

        Write-Host "[gameteam] Found $totalCount assets" -ForegroundColor Green
    }

    # Normalize license field across all assets
    foreach ($cat in @($manifest.categories.Keys)) {
        foreach ($asset in $manifest.categories[$cat].assets) {
            if ($null -eq $asset -or [string]::IsNullOrWhiteSpace([string]$asset.license)) {
                if ($asset -is [System.Collections.IDictionary]) { $asset['license'] = 'unknown' }
                else { $asset | Add-Member -NotePropertyName 'license' -NotePropertyValue 'unknown' -Force }
            }
        }
    }
    
    # Determine output path
    if ([string]::IsNullOrWhiteSpace($OutputPath)) {
        $OutputPath = $manifestPath
    } else {
        $OutputPath = Join-Path $projectPath $OutputPath
    }
    
    # Save in requested format
    if ($Format -eq "json") {
        $manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
        Write-Host "[gameteam] Manifest saved: $OutputPath" -ForegroundColor Green
    } elseif ($Format -eq "csv") {
        $csvData = @()
        $categoryNames = if ($manifest.categories -is [System.Collections.IDictionary]) {
            @($manifest.categories.Keys)
        } else {
            @($manifest.categories.PSObject.Properties.Name)
        }

        foreach ($category in $categoryNames) {
            $categoryData = if ($manifest.categories -is [System.Collections.IDictionary]) {
                $manifest.categories[$category]
            } else {
                $manifest.categories.PSObject.Properties[$category].Value
            }

            foreach ($asset in $categoryData.assets) {
                $csvData += [pscustomobject]@{
                    Category = $category
                    Name = $asset.name
                    FileName = $asset.fileName
                    Path = $asset.path
                    Format = $asset.format
                    Size = $asset.fileSize
                    License = $asset.license
                    Status = $asset.status
                    Tags = ($asset.tags -join ";")
                }
            }
        }
        $csvData | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding UTF8
        Write-Host "[gameteam] Manifest exported to CSV: $OutputPath" -ForegroundColor Green
    }
    
    return [pscustomobject]@{
        AssetCount = $manifest.assetCount
        TotalSize = $manifest.totalSize
        ManifestPath = $OutputPath
        Format = $Format
        ExtractionDepth = $manifest.extractionDepth
        Provenance = $manifest.provenance
    }
}
