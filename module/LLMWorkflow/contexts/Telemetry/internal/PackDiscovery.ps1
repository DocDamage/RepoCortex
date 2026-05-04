Set-StrictMode -Version Latest

# In-memory cache for pack list discovery
$script:PackListCache = $null

function Get-PackList {
    <#
    .SYNOPSIS
        Discovers all packs in the workspace.
    #>
    [CmdletBinding()]
    [OutputType([array])]
    param(
        [string]$ProjectRoot = '.'
    )
    
    # Simple in-memory cache with 5-second TTL to reduce redundant disk I/O
    # during dashboard rendering when this function is called multiple times.
    $cacheKey = "PackList_$ProjectRoot"
    $now = [DateTime]::UtcNow
    if ($script:PackListCache -and $script:PackListCache[$cacheKey]) {
        $cached = $script:PackListCache[$cacheKey]
        if (($now - $cached.Timestamp).TotalSeconds -lt 5) {
            return $cached.Data
        }
    }
    
    $manifestDir = Join-Path (Join-Path $ProjectRoot 'packs') 'manifests'
    $packs = @()
    
    if (Test-Path -LiteralPath $manifestDir) {
        $packFiles = Get-DashboardChildItems -Path $manifestDir -Filter '*.json' -ItemType File -Context 'Pack manifest scan'
        foreach ($file in $packFiles) {
            try {
                $manifest = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction Stop | ConvertFrom-Json
                $packs += @{
                    packId = $manifest.packId
                    domain = $manifest.domain
                    version = $manifest.version
                    manifestPath = $file.FullName
                }
            }
            catch {
                Write-Warning "Failed to parse manifest: $($file.Name) - $_"
            }
        }
    }
    
    if (-not $script:PackListCache) {
        $script:PackListCache = @{}
    }
    $script:PackListCache[$cacheKey] = @{
        Timestamp = $now
        Data = $packs
    }
    
    return $packs
}
