Set-StrictMode -Version Latest

#===============================================================================
# Retrieval Activity Dashboard
#===============================================================================

<#
.SYNOPSIS
    Displays retrieval activity metrics dashboard.

.DESCRIPTION
    Shows query counts, cache hit rates, response times, confidence score
    distribution, and abstain/escalation rates per pack.

.PARAMETER PackId
    Optional specific pack ID. If not specified, shows all packs.

.PARAMETER TimeRange
    Time range for metrics: '1h', '24h', '7d', '30d'.

.PARAMETER OutputFormat
    Output format: 'Console', 'HTML', or 'JSON'.

.PARAMETER ProjectRoot
    Project root directory.

.EXAMPLE
    Show-RetrievalActivityDashboard -TimeRange 24h
    
    Shows retrieval metrics for the last 24 hours.

.OUTPUTS
    System.Collections.Hashtable or formatted output.
#>
function Show-RetrievalActivityDashboard {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter()]
        [string]$PackId = '',
        
        [Parameter()]
        [ValidateSet('1h', '24h', '7d', '30d')]
        [string]$TimeRange = '24h',
        
        [Parameter()]
        [ValidateSet('Console', 'HTML', 'JSON')]
        [string]$OutputFormat = 'Console',
        
        [Parameter()]
        [string]$ProjectRoot = '.',
        
        [Parameter()]
        [switch]$UseAnsi,
        
        [Parameter()]
        [string]$ExportPath = ''
    )
    
    begin {
        $useAnsiColors = $UseAnsi -or (Test-AnsiSupport)
        
        $dashboardData = @{
            generatedAt = [DateTime]::UtcNow.ToString('o')
            version = $script:DashboardVersion
            timeRange = $TimeRange
            packs = @()
            summary = @{
                totalQueries = 0
                avgCacheHitRate = 0
                avgResponseTime = 0
                totalAbstains = 0
                totalEscalations = 0
            }
        }
        
        # Parse time range
        $timeSpan = switch ($TimeRange) {
            '1h' { [TimeSpan]::FromHours(1) }
            '24h' { [TimeSpan]::FromHours(24) }
            '7d' { [TimeSpan]::FromDays(7) }
            '30d' { [TimeSpan]::FromDays(30) }
        }
    }
    
    process {
        $packs = if ($PackId) {
            @(@{ packId = $PackId })
        }
        else {
            Get-PackList -ProjectRoot $ProjectRoot
        }
        
        $totalCacheHitRate = 0
        $totalResponseTime = 0
        $packCount = 0
        
        foreach ($pack in $packs) {
            $metrics = Get-RetrievalMetrics -PackId $pack.packId -TimeSpan $timeSpan -ProjectRoot $ProjectRoot
            
            $packEntry = @{
                packId = $pack.packId
                queryCount = $metrics.queryCount
                cacheHitRate = $metrics.cacheHitRate
                avgResponseTime = $metrics.avgResponseTime
                confidenceDistribution = $metrics.confidenceDistribution
                abstainRate = $metrics.abstainRate
                escalationRate = $metrics.escalationRate
                p95Latency = $metrics.p95Latency
                p99Latency = $metrics.p99Latency
            }
            
            $dashboardData.packs += $packEntry
            $dashboardData.summary.totalQueries += $metrics.queryCount
            $dashboardData.summary.totalAbstains += $metrics.abstainCount
            $dashboardData.summary.totalEscalations += $metrics.escalationCount
            $totalCacheHitRate += $metrics.cacheHitRate
            $totalResponseTime += $metrics.avgResponseTime
            $packCount++
        }
        
        if ($packCount -gt 0) {
            $dashboardData.summary.avgCacheHitRate = [math]::Round($totalCacheHitRate / $packCount, 2)
            $dashboardData.summary.avgResponseTime = [math]::Round($totalResponseTime / $packCount)
        }
        
        # Output
        switch ($OutputFormat) {
            'Console' {
                Write-ConsoleRetrievalDashboard -Data $dashboardData -UseAnsi:$useAnsiColors
            }
            'HTML' {
                $html = Convert-ToRetrievalDashboardHTML -Data $dashboardData -Theme 'dark'
                if ($ExportPath) {
                    $html | Out-File -FilePath $ExportPath -Encoding UTF8
                }
                return $html
            }
            'JSON' {
                $json = $dashboardData | ConvertTo-Json -Depth 10
                if ($ExportPath) {
                    $json | Out-File -FilePath $ExportPath -Encoding UTF8
                }
                return $json
            }
        }
        
        return $dashboardData
    }
}
