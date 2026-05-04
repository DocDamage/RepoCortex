Set-StrictMode -Version Latest

#===============================================================================
# Federation Status
#===============================================================================

<#
.SYNOPSIS
    Displays federated memory status dashboard.

.DESCRIPTION
    Shows connected federation nodes, sync status, last sync times, conflict
    counts, and access grants summary.

.PARAMETER OutputFormat
    Output format: 'Console', 'HTML', or 'JSON'.

.PARAMETER UseAnsi
    Use ANSI color codes.

.PARAMETER ExportPath
    Path to export output.

.EXAMPLE
    Show-FederationStatus
    
    Displays federated memory status.

.OUTPUTS
    System.Collections.Hashtable or formatted output.
#>
function Show-FederationStatus {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter()]
        [ValidateSet('Console', 'HTML', 'JSON')]
        [string]$OutputFormat = 'Console',
        
        [Parameter()]
        [switch]$UseAnsi,
        
        [Parameter()]
        [string]$ExportPath = ''
    )
    
    begin {
        $useAnsiColors = $UseAnsi -or (Test-AnsiSupport)
        
        $statusData = @{
            generatedAt = [DateTime]::UtcNow.ToString('o')
            version = $script:DashboardVersion
            summary = @{
                totalNodes = 0
                activeNodes = 0
                suspendedNodes = 0
                offlineNodes = 0
                pendingConflicts = 0
                totalAccessGrants = 0
            }
            nodes = @()
        }
    }
    
    process {
        # Try to get federation data
        $federations = @()
        try {
            $fedCmd = Get-DashboardCommand -CommandName 'Get-MemoryFederations'
            if ($fedCmd) {
                $federations = Get-MemoryFederations
            }
        }
        catch {
            Write-Verbose "Federation module not available"
        }
        
        if ($federations -and $federations.Count -gt 0) {
            foreach ($fed in $federations) {
                $node = @{
                    nodeId = $fed.FederationId
                    peerUrl = $fed.PeerUrl
                    status = $fed.Status
                    trustLevel = $fed.TrustLevel
                    syncDirection = $fed.SyncDirection
                    lastSync = $fed.LastSync
                    syncCount = if ($fed.syncCount) { $fed.syncCount } else { 0 }
                }
                $statusData.nodes += $node
                $statusData.summary.totalNodes++
                
                switch ($fed.Status) {
                    'active' { $statusData.summary.activeNodes++ }
                    'suspended' { $statusData.summary.suspendedNodes++ }
                    'offline' { $statusData.summary.offlineNodes++ }
                }
            }
        }
        # Note: When no federation data is available, summary retains its defaults
        # (all zeros) to distinguish "no data" from "connected but idle"
        
        # Output
        switch ($OutputFormat) {
            'Console' {
                Write-ConsoleFederationStatus -Data $statusData -UseAnsi:$useAnsiColors
            }
            'HTML' {
                $html = Convert-ToFederationStatusHTML -Data $statusData -Theme 'dark'
                if ($ExportPath) {
                    $html | Out-File -FilePath $ExportPath -Encoding UTF8
                }
                return $html
            }
            'JSON' {
                $json = $statusData | ConvertTo-Json -Depth 10
                if ($ExportPath) {
                    $json | Out-File -FilePath $ExportPath -Encoding UTF8
                }
                return $json
            }
        }
        
        return $statusData
    }
}
