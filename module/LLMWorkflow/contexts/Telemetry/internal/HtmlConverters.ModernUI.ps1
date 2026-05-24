Set-StrictMode -Version Latest

function Get-DashboardModernUIAssetDataUri {
    param(
        [string]$ProjectRoot,
        [string[]]$RelativeCandidates
    )

    if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
        return ''
    }

    $resolvedRoot = try {
        (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
    }
    catch {
        $ProjectRoot
    }

    foreach ($relativePath in $RelativeCandidates) {
        $assetPath = Join-Path $resolvedRoot $relativePath
        if (-not (Test-Path -LiteralPath $assetPath -PathType Leaf)) {
            continue
        }

        $resolvedAssetPath = (Resolve-Path -LiteralPath $assetPath).Path
        $extension = [IO.Path]::GetExtension($resolvedAssetPath).TrimStart('.').ToLowerInvariant()
        if ($extension -eq 'jpg') {
            $extension = 'jpeg'
        }

        $bytes = [IO.File]::ReadAllBytes($resolvedAssetPath)
        return "data:image/$extension;base64,$([Convert]::ToBase64String($bytes))"
    }

    return ''
}

function New-DashboardModernUIChrome {
    param(
        [hashtable]$Assets
    )

    if (-not $Assets -or [string]::IsNullOrWhiteSpace([string]$Assets.Brand)) {
        return ''
    }

    $styleOne = if ([string]::IsNullOrWhiteSpace([string]$Assets.StyleOne)) { $Assets.Brand } else { $Assets.StyleOne }
    $styleTwo = if ([string]::IsNullOrWhiteSpace([string]$Assets.StyleTwo)) { $Assets.Brand } else { $Assets.StyleTwo }
    $action = if ([string]::IsNullOrWhiteSpace([string]$Assets.Action)) { $Assets.Brand } else { $Assets.Action }

    return @"
<aside class="modern-ui-rail" aria-label="Repo Cortex views">
    <div class="modern-ui-button is-active"><img src="$($Assets.Brand)" alt="Health"><span>Health</span></div>
    <div class="modern-ui-button"><img src="$styleOne" alt="Retrieval"><span>Search</span></div>
    <div class="modern-ui-button"><img src="$styleTwo" alt="Graph"><span>Graph</span></div>
    <div class="modern-ui-button"><img src="$action" alt="Gateway"><span>MCP</span></div>
    <div class="modern-ui-button"><img src="$($Assets.Brand)" alt="Federation"><span>Mesh</span></div>
</aside>
<section class="modern-ui-banner" aria-label="Repo Cortex summary">
    <div class="modern-ui-panel"><img src="$($Assets.Brand)" alt="Pack health"><div><strong>Pack Health</strong><span>Live release surface</span></div></div>
    <div class="modern-ui-panel"><img src="$styleOne" alt="Retrieval activity"><div><strong>Retrieval</strong><span>Evidence and memory flow</span></div></div>
    <div class="modern-ui-panel"><img src="$styleTwo" alt="Governance"><div><strong>Governance</strong><span>Policy and MCP control</span></div></div>
</section>
"@
}
