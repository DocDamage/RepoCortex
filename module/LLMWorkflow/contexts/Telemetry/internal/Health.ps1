Set-StrictMode -Version Latest

#===============================================================================
# Pack Health Dashboard
#===============================================================================

function Get-BasicPackHealth {
    <#
    .SYNOPSIS
        Performs basic pack health check without HealthScore module.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [string]$PackId,
        [string]$ProjectRoot = '.'
    )
    
    $score = 100
    $status = 'Healthy'
    $warnings = @()
    $criticalIssues = @()
    $rawMetrics = @{
        totalSources = 0
        activeSources = 0
        staleSources = 0
        lockfileStatus = 'missing'
    }
    
    # Check manifest
    $manifestPath = Join-Path $ProjectRoot "packs/manifests/$PackId.json"
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        $score -= 20
        $criticalIssues += 'Manifest file not found'
    }
    
    # Check source registry
    $registryPath = Join-Path $ProjectRoot "packs/registries/$PackId.sources.json"
    if (Test-Path -LiteralPath $registryPath) {
        try {
            $registry = Get-Content -LiteralPath $registryPath -Raw | ConvertFrom-Json
            $rawMetrics.totalSources = if ($registry.sources) { $registry.sources.Count } else { 0 }
            $rawMetrics.activeSources = if ($registry.sources) { 
                ($registry.sources | Where-Object { $_.state -eq 'active' }).Count 
            } else { 0 }
        }
        catch {
            $score -= 10
            $warnings += 'Source registry unreadable'
        }
    }
    else {
        $score -= 20
        $criticalIssues += 'Source registry not found'
    }
    
    # Check lockfile
    $lockfilePath = Join-Path $ProjectRoot "packs/locks/$PackId.lock.json"
    if (Test-Path -LiteralPath $lockfilePath) {
        $rawMetrics.lockfileStatus = 'present'
    }
    else {
        $score -= 20
        $criticalIssues += 'Lockfile not found'
    }
    
    # Determine status
    if ($score -lt 60) {
        $status = 'Critical'
    }
    elseif ($score -lt 80) {
        $status = 'Degraded'
    }
    
    return @{
        packId = $PackId
        overallScore = [math]::Max(0, $score)
        status = $status
        severity = $status
        warnings = $warnings
        criticalIssues = $criticalIssues
        rawMetrics = $rawMetrics
    }
}

function Write-ConsoleHealthDashboard {
    <#
    .SYNOPSIS
        Writes health dashboard to console.
    #>
    [CmdletBinding()]
    param(
        [hashtable]$Data,
        [switch]$UseAnsi,
        [switch]$IncludeDetails
    )
    
    $a = $script:AnsiColors
    $reset = if ($UseAnsi) { $a.Reset } else { '' }
    $bold = if ($UseAnsi) { $a.Bold } else { '' }
    $cyan = if ($UseAnsi) { $a.Cyan } else { '' }
    
    # Header
    Write-Host "$bold$cyan========================================$reset"
    Write-Host "$bold$cyan   PACK HEALTH DASHBOARD$reset"
    Write-Host "$bold$cyan   Generated: $($Data.generatedAt)$reset"
    Write-Host "$bold$cyan========================================$reset"
    Write-Host ''
    
    # Summary
    Write-Host "$bold Summary:$reset"
    $summaryColor = if ($Data.summary.critical -gt 0) { if ($UseAnsi) { $a.Red } else { '' } }
                   elseif ($Data.summary.degraded -gt 0) { if ($UseAnsi) { $a.Yellow } else { '' } }
                   else { if ($UseAnsi) { $a.Green } else { '' } }
    
    Write-Host "  Total Packs: $($Data.summary.totalPacks)"
    Write-Host "  Average Score: $summaryColor$($Data.summary.averageScore)$reset"
    Write-Host "  Healthy: $(if($UseAnsi){$a.Green})$($Data.summary.healthy)$reset"
    Write-Host "  Degraded: $(if($UseAnsi){$a.Yellow})$($Data.summary.degraded)$reset"
    Write-Host "  Critical: $(if($UseAnsi){$a.Red})$($Data.summary.critical)$reset"
    Write-Host ''
    
    # Pack Details
    if ($Data.packs.Count -gt 0) {
        Write-Host "$bold Pack Details:$reset"
        Write-Host ($('-' * 70))
        
        # Header row
        $header = '{0,-20} {1,8} {2,10} {3,8} {4,10}' -f 'Pack ID', 'Score', 'Status', 'Warnings', 'Critical'
        Write-Host "$bold$header$reset"
        Write-Host ($('-' * 70))
        
        foreach ($pack in $Data.packs) {
            $statusInd = Format-StatusIndicator -Status $pack.status -UseAnsi:$UseAnsi
            $scoreColor = Get-HealthScoreColor -Score $pack.score -UseAnsi:$UseAnsi
            $scoreReset = if ($UseAnsi) { $reset } else { '' }
            
            $row = '{0,-20} {1}{2,8}{3} {4,-10} {5,8} {6,10}' -f 
                $pack.packId, $scoreColor, $pack.score, $scoreReset, 
                $statusInd, $pack.warnings, $pack.criticalIssues
            
            Write-Host $row
            
            if ($IncludeDetails -and $pack.components) {
                foreach ($component in $pack.components.GetEnumerator()) {
                    Write-Host "    - $($component.Key): $($component.Value) pts"
                }
            }
        }
        Write-Host ($('-' * 70))
    }
}
