Set-StrictMode -Version Latest

#===============================================================================
# MCP Gateway Status
#===============================================================================

function Write-ConsoleGatewayStatus {
    <#
    .SYNOPSIS
        Writes gateway status to console.
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
    Write-Host "$bold$cyan   $($script:ProductBrandName) MCP Gateway$reset"
    Write-Host "$bold$cyan========================================$reset"
    Write-Host ''
    
    $gs = $Data.gatewayStatus
    $statusColor = if ($gs.isRunning) { if ($UseAnsi) { $a.Green } else { '' } } 
                   else { if ($UseAnsi) { $a.Red } else { '' } }
    $statusText = if ($gs.isRunning) { 'RUNNING' } else { 'STOPPED' }
    
    Write-Host "$bold Gateway Status:$reset $statusColor$statusText$reset"
    Write-Host "  Uptime: $($gs.uptime)"
    Write-Host "  Routes: $($gs.enabledRouteCount)/$($gs.routeCount) enabled"
    Write-Host "  Sessions: $($gs.activeSessions)/$($gs.sessionCount) active"
    Write-Host ''
    
    if ($Data.circuitBreakers.Count -gt 0) {
        Write-Host "$bold Circuit Breakers:$reset"
        Write-Host ($('-' * 60))
        
        $header = '{0,-20} {1,12} {2,10} {3,10}' -f 'Pack ID', 'State', 'Failures', 'Successes'
        Write-Host "$bold$header$reset"
        Write-Host ($('-' * 60))
        
        foreach ($cb in $Data.circuitBreakers) {
            $stateColor = switch ($cb.state) {
                'CLOSED' { if ($UseAnsi) { $a.Green } else { '' } }
                'OPEN' { if ($UseAnsi) { $a.Red } else { '' } }
                'HALF_OPEN' { if ($UseAnsi) { $a.Yellow } else { '' } }
                default { '' }
            }
            
            $row = '{0,-20} {1}{2,12}{3} {4,10} {5,10}' -f 
                $cb.packId, $stateColor, $cb.state, $reset, $cb.failureCount, $cb.successCount
            Write-Host $row
        }
        Write-Host ($('-' * 60))
    }
}
