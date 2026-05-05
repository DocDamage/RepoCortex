Set-StrictMode -Version Latest

#===============================================================================
# Retrieval Activity Dashboard
#===============================================================================

function Get-RetrievalMetrics {
    <#
    .SYNOPSIS
        Gets retrieval metrics for a pack.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [string]$PackId,
        [TimeSpan]$TimeSpan,
        [string]$ProjectRoot = '.',
        [string]$TelemetryDir = '',
        [string]$CacheFile = ''
    )
    
    $metrics = @{
        queryCount = 0
        cacheHitRate = 0.0
        avgResponseTime = 0
        confidenceDistribution = @{
            high = 0    # > 0.8
            medium = 0  # 0.5 - 0.8
            low = 0     # < 0.5
        }
        abstainRate = 0.0
        abstainCount = 0
        escalationRate = 0.0
        escalationCount = 0
        p95Latency = 0
        p99Latency = 0
        dataAvailable = $false
    }
    
    # Resolve telemetry directory (configurable or default)
    $telemetryDir = if ($TelemetryDir) { $TelemetryDir } else { Join-Path $ProjectRoot '.llm-workflow' 'telemetry' }
    $telemetryFile = Join-Path $telemetryDir "$PackId" "p95RetrievalLatencyMs.jsonl"
    
    if (Test-Path -LiteralPath $telemetryFile) {
        try {
            $cutoff = [DateTime]::UtcNow - $TimeSpan
            $parseFailures = 0
            $entries = Get-Content -LiteralPath $telemetryFile -Encoding UTF8 -ErrorAction Stop | 
                ForEach-Object {
                    try { 
                        $_ | ConvertFrom-Json -ErrorAction Stop 
                    } catch { 
                        $parseFailures++
                        $null 
                    }
                } | 
                Where-Object { $_ -and [DateTime]::Parse($_.timestamp) -gt $cutoff }
            
            if ($parseFailures -gt 0) {
                Write-Warning "Telemetry file for $PackId contained $parseFailures unparseable line(s)."
            }
            if ($entries) {
                $latencies = $entries | ForEach-Object { $_.value }
                $metrics.p95Latency = Get-PercentileValue -Values $latencies -Percentile 95
                $metrics.p99Latency = Get-PercentileValue -Values $latencies -Percentile 99
                $metrics.avgResponseTime = ($latencies | Measure-Object -Average).Average
                $metrics.dataAvailable = $true
            }
        }
        catch {
            Write-Warning "Failed to read telemetry for $PackId`: $_"
        }
    }
    else {
        Write-Verbose "Telemetry file not found for pack $PackId`: $telemetryFile"
    }
    
    # Resolve cache file (configurable or default)
    $cacheFile = if ($CacheFile) { $CacheFile } else { Join-Path $ProjectRoot '.llm-workflow' 'cache' 'retrieval-cache.jsonl' }
    if (Test-Path -LiteralPath $cacheFile) {
        try {
            $parseFailures = 0
            $cacheEntries = Get-Content -LiteralPath $cacheFile -Encoding UTF8 -ErrorAction Stop | 
                ForEach-Object {
                    try { 
                        $_ | ConvertFrom-Json -ErrorAction Stop 
                    } catch { 
                        $parseFailures++
                        $null 
                    }
                } | 
                Where-Object { $_ -and $_.packVersions -and $_.packVersions.$PackId }
            
            if ($parseFailures -gt 0) {
                Write-Warning "Cache file contained $parseFailures unparseable line(s)."
            }
            if ($cacheEntries) {
                $hitCount = ($cacheEntries | ForEach-Object { $_.metadata.hitCount } | Measure-Object -Sum).Sum
                $totalAccess = $cacheEntries.Count + $hitCount
                if ($totalAccess -gt 0) {
                    $metrics.cacheHitRate = [math]::Round($hitCount / $totalAccess, 2)
                    $metrics.dataAvailable = $true
                }
            }
        }
        catch {
            Write-Warning "Failed to read cache metrics for $PackId`: $_"
        }
    }
    else {
        Write-Verbose "Cache file not found: $cacheFile"
    }
    
    return $metrics
}

function Get-PercentileValue {
    <#
    .SYNOPSIS
        Calculates percentile value from array.
    #>
    param(
        [double[]]$Values,
        [int]$Percentile
    )
    
    if (-not $Values -or $Values.Count -eq 0) { return 0 }
    
    $sorted = $Values | Sort-Object
    $index = ($Percentile / 100) * ($sorted.Count - 1)
    $lower = [math]::Floor($index)
    $upper = [math]::Ceiling($index)
    $weight = $index - $lower
    
    if ($lower -eq $upper) { return $sorted[$lower] }
    
    return $sorted[$lower] * (1 - $weight) + $sorted[$upper] * $weight
}

function Write-ConsoleRetrievalDashboard {
    <#
    .SYNOPSIS
        Writes retrieval dashboard to console.
    #>
    [CmdletBinding()]
    param(
        [hashtable]$Data,
        [switch]$UseAnsi
    )
    
    $a = $script:AnsiColors
    $reset = if ($UseAnsi) { $a.Reset } else { '' }
    $bold = if ($UseAnsi) { $a.Bold } else { '' }
    $cyan = if ($UseAnsi) { $a.Cyan } else { '' }
    
    Write-Host "$bold$cyan========================================$reset"
    Write-Host "$bold$cyan   $($script:ProductBrandName) Retrieval Activity$reset"
    Write-Host "$bold$cyan   Time Range: $($Data.timeRange)$reset"
    Write-Host "$bold$cyan========================================$reset"
    Write-Host ''
    
    # Summary
    Write-Host "$bold Summary:$reset"
    $cacheColor = if ($Data.summary.avgCacheHitRate -ge 0.8) { if ($UseAnsi) { $a.Green } else { '' } }
                  elseif ($Data.summary.avgCacheHitRate -ge 0.5) { if ($UseAnsi) { $a.Yellow } else { '' } }
                  else { if ($UseAnsi) { $a.Red } else { '' } }
    Write-Host "  Avg Cache Hit Rate: $cacheColor$([math]::Round($Data.summary.avgCacheHitRate * 100, 1))%$reset"
    Write-Host "  Avg Response Time: $($Data.summary.avgResponseTime)ms"
    Write-Host "  Total Abstains: $($Data.summary.totalAbstains)"
    Write-Host "  Total Escalations: $($Data.summary.totalEscalations)"
    Write-Host ''
    
    # Pack Details
    if ($Data.packs.Count -gt 0) {
        Write-Host "$bold Pack Metrics:$reset"
        Write-Host ($('-' * 90))
        
        $header = '{0,-20} {1,10} {2,12} {3,12} {4,12} {5,12}' -f 
            'Pack ID', 'Queries', 'Cache Hit %', 'Avg Latency', 'P95 Latency', 'P99 Latency'
        Write-Host "$bold$header$reset"
        Write-Host ($('-' * 90))
        
        foreach ($pack in $Data.packs) {
            $cacheRate = [math]::Round($pack.cacheHitRate * 100, 1)
            $cacheColor = if ($cacheRate -ge 80) { if ($UseAnsi) { $a.Green } else { '' } }
                          elseif ($cacheRate -ge 50) { if ($UseAnsi) { $a.Yellow } else { '' } }
                          else { if ($UseAnsi) { $a.Red } else { '' } }
            
            $row = '{0,-20} {1,10} {2}{3,11}%{4} {5,11}ms {6,11}ms {7,11}ms' -f 
                $pack.packId, $pack.queryCount, $cacheColor, $cacheRate, $reset,
                $pack.avgResponseTime, $pack.p95Latency, $pack.p99Latency
            
            Write-Host $row
        }
        Write-Host ($('-' * 90))
    }
}
