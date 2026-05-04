Set-StrictMode -Version Latest

#===============================================================================
# HTML Conversion Helper Functions
#===============================================================================

function Convert-HealthToHtmlSection {
    param($Data, $ThemeColors)
    
    $packRows = $Data.packs | ForEach-Object {
        $badgeClass = switch ($_.status) {
            'Healthy' { 'badge-healthy' }
            'Degraded' { 'badge-warning' }
            'Critical' { 'badge-critical' }
            default { '' }
        }
        "<tr><td>$($_.packId)</td><td>$($_.score)</td><td><span class='badge $badgeClass'>$($_.status)</span></td><td>$($_.warnings)</td><td>$($_.criticalIssues)</td></tr>"
    }
    
    return @"
<div class="card">
    <h2>Pack Health</h2>
    <div class="metric-grid">
        <div class="metric">
            <div class="metric-value">$($Data.summary.totalPacks)</div>
            <div class="metric-label">Total Packs</div>
        </div>
        <div class="metric">
            <div class="metric-value $(if($Data.summary.averageScore -ge 80){'status-healthy'}elseif($Data.summary.averageScore -ge 60){'status-warning'}else{'status-critical'})">$($Data.summary.averageScore)</div>
            <div class="metric-label">Avg Score</div>
        </div>
        <div class="metric">
            <div class="metric-value status-healthy">$($Data.summary.healthy)</div>
            <div class="metric-label">Healthy</div>
        </div>
        <div class="metric">
            <div class="metric-value status-critical">$($Data.summary.critical)</div>
            <div class="metric-label">Critical</div>
        </div>
    </div>
    <table>
        <thead>
            <tr><th>Pack ID</th><th>Score</th><th>Status</th><th>Warnings</th><th>Critical</th></tr>
        </thead>
        <tbody>
            $($packRows -join "`n")
        </tbody>
    </table>
</div>
"@
}

function Convert-RetrievalToHtmlSection {
    param($Data, $ThemeColors)
    
    $packRows = $Data.packs | ForEach-Object {
        $cacheRate = [math]::Round($_.cacheHitRate * 100, 1)
        "<tr><td>$($_.packId)</td><td>$($_.queryCount)</td><td>$cacheRate%</td><td>$($_.avgResponseTime)ms</td><td>$($_.p95Latency)ms</td></tr>"
    }
    
    return @"
<div class="card">
    <h2>Retrieval Activity ($($Data.timeRange))</h2>
    <div class="metric-grid">
        <div class="metric">
            <div class="metric-value">$($Data.summary.totalQueries)</div>
            <div class="metric-label">Total Queries</div>
        </div>
        <div class="metric">
            <div class="metric-value">$([math]::Round($Data.summary.avgCacheHitRate * 100, 1))%</div>
            <div class="metric-label">Cache Hit Rate</div>
        </div>
        <div class="metric">
            <div class="metric-value">$($Data.summary.avgResponseTime)ms</div>
            <div class="metric-label">Avg Latency</div>
        </div>
    </div>
    <table>
        <thead>
            <tr><th>Pack ID</th><th>Queries</th><th>Cache Hit</th><th>Avg Latency</th><th>P95 Latency</th></tr>
        </thead>
        <tbody>
            $($packRows -join "`n")
        </tbody>
    </table>
</div>
"@
}

function Convert-GraphToHtmlSection {
    param($Data, $ThemeColors)
    
    $mermaidGraph = Convert-ToMermaidGraph -Data $Data
    
    return @"
<div class="card">
    <h2>Cross-Pack Relationships</h2>
    <div class="mermaid">
$($mermaidGraph -replace '```mermaid', '' -replace '```', '')
    </div>
</div>
"@
}

function Convert-GatewayToHtmlSection {
    param($Data, $ThemeColors)
    
    $cbRows = $Data.circuitBreakers | ForEach-Object {
        $badgeClass = switch ($_.state) {
            'CLOSED' { 'badge-healthy' }
            'OPEN' { 'badge-critical' }
            'HALF_OPEN' { 'badge-warning' }
            default { '' }
        }
        "<tr><td>$($_.packId)</td><td><span class='badge $badgeClass'>$($_.state)</span></td><td>$($_.failureCount)</td><td>$($_.successCount)</td></tr>"
    }
    
    $statusClass = if ($Data.gatewayStatus.isRunning) { 'status-healthy' } else { 'status-critical' }
    
    return @"
<div class="card">
    <h2>MCP Gateway Status</h2>
    <div class="metric-grid">
        <div class="metric">
            <div class="metric-value $statusClass">$(if($Data.gatewayStatus.isRunning){'ONLINE'}else{'OFFLINE'})</div>
            <div class="metric-label">Status</div>
        </div>
        <div class="metric">
            <div class="metric-value">$($Data.gatewayStatus.routeCount)</div>
            <div class="metric-label">Routes</div>
        </div>
        <div class="metric">
            <div class="metric-value">$($Data.gatewayStatus.sessionCount)</div>
            <div class="metric-label">Sessions</div>
        </div>
        <div class="metric">
            <div class="metric-value">$($Data.gatewayStatus.uptime)</div>
            <div class="metric-label">Uptime</div>
        </div>
    </div>
    <h3>Circuit Breakers</h3>
    <table>
        <thead>
            <tr><th>Pack ID</th><th>State</th><th>Failures</th><th>Successes</th></tr>
        </thead>
        <tbody>
            $($cbRows -join "`n")
        </tbody>
    </table>
</div>
"@
}

function Convert-FederationToHtmlSection {
    param($Data, $ThemeColors)
    
    $nodeRows = $Data.nodes | ForEach-Object {
        $badgeClass = switch ($_.status) {
            'active' { 'badge-healthy' }
            'suspended' { 'badge-warning' }
            'offline' { 'badge-critical' }
            default { '' }
        }
        $lastSync = if ($_.lastSync) { [DateTime]::Parse($_.lastSync).ToString('yyyy-MM-dd HH:mm') } else { 'Never' }
        "<tr><td>$($_.nodeId)</td><td><span class='badge $badgeClass'>$($_.status)</span></td><td>$($_.trustLevel)</td><td>$($_.syncDirection)</td><td>$lastSync</td></tr>"
    }
    
    return @"
<div class="card">
    <h2>Federated Memory</h2>
    <div class="metric-grid">
        <div class="metric">
            <div class="metric-value">$($Data.summary.totalNodes)</div>
            <div class="metric-label">Total Nodes</div>
        </div>
        <div class="metric">
            <div class="metric-value status-healthy">$($Data.summary.activeNodes)</div>
            <div class="metric-label">Active</div>
        </div>
        <div class="metric">
            <div class="metric-value status-warning">$($Data.summary.suspendedNodes)</div>
            <div class="metric-label">Suspended</div>
        </div>
        <div class="metric">
            <div class="metric-value">$($Data.summary.pendingConflicts)</div>
            <div class="metric-label">Conflicts</div>
        </div>
    </div>
    <table>
        <thead>
            <tr><th>Node ID</th><th>Status</th><th>Trust</th><th>Direction</th><th>Last Sync</th></tr>
        </thead>
        <tbody>
            $($nodeRows -join "`n")
        </tbody>
    </table>
</div>
"@
}
