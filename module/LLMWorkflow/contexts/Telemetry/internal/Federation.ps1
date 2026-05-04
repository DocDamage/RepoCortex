Set-StrictMode -Version Latest

#===============================================================================
# Federation Status
#===============================================================================

function Write-ConsoleFederationStatus {
    <#
    .SYNOPSIS
        Writes federation status to console.
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
    Write-Host "$bold$cyan   FEDERATED MEMORY STATUS$reset"
    Write-Host "$bold$cyan========================================$reset"
    Write-Host ''
    
    $s = $Data.summary
    Write-Host "$bold Summary:$reset"
    Write-Host "  Total Nodes: $($s.totalNodes)"
    Write-Host "  Active: $(if($UseAnsi){$a.Green})$($s.activeNodes)$reset"
    Write-Host "  Suspended: $(if($UseAnsi){$a.Yellow})$($s.suspendedNodes)$reset"
    Write-Host "  Offline: $(if($UseAnsi){$a.Red})$($s.offlineNodes)$reset"
    Write-Host "  Pending Conflicts: $($s.pendingConflicts)"
    Write-Host "  Access Grants: $($s.totalAccessGrants)"
    Write-Host ''
    
    if ($Data.nodes.Count -gt 0) {
        Write-Host "$bold Federation Nodes:$reset"
        Write-Host ($('-' * 90))
        
        $header = '{0,-20} {1,-12} {2,-14} {3,-15} {4,-20}' -f 
            'Node ID', 'Status', 'Trust Level', 'Sync Direction', 'Last Sync'
        Write-Host "$bold$header$reset"
        Write-Host ($('-' * 90))
        
        foreach ($node in $Data.nodes) {
            $statusColor = switch ($node.status) {
                'active' { if ($UseAnsi) { $a.Green } else { '' } }
                'suspended' { if ($UseAnsi) { $a.Yellow } else { '' } }
                'offline' { if ($UseAnsi) { $a.Red } else { '' } }
                default { '' }
            }
            
            $lastSync = if ($node.lastSync) { 
                [DateTime]::Parse($node.lastSync).ToString('yyyy-MM-dd HH:mm') 
            } else { 'Never' }
            
            $row = '{0,-20} {1}{2,-12}{3} {4,-14} {5,-15} {6,-20}' -f 
                $node.nodeId, $statusColor, $node.status, $reset, 
                $node.trustLevel, $node.syncDirection, $lastSync
            
            Write-Host $row
        }
        Write-Host ($('-' * 90))
    }
}
