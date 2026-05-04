Set-StrictMode -Version Latest

function Repair-HealingIssue_CorruptedSyncState {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [string]$ProjectPath,
        [string]$ProjectRoot,
        [switch]$WhatIf,
        [switch]$Force,
        [switch]$Interactive
    )

    $changes = @()
    $success = $false
    $message = ""

                $statePath = Join-Path $projectPath ".memorybridge" "sync-state.json"
                if ($WhatIf) {
                    $changes += "Would backup corrupted sync-state.json"
                    $changes += "Would create new empty sync-state.json"
                    $success = $true
                    $message = "Would repair sync state (WhatIf mode)"
                } else {
                    try {
                        if (Test-Path -LiteralPath $statePath) {
                            $backupPath = "$statePath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                            Copy-Item -LiteralPath $statePath -Destination $backupPath
                            $changes += "Backed up corrupted state to: $backupPath"
                        }
                        
                        $defaultState = @{
                            version = "1.0"
                            lastSync = $null
                            drawers = @{}
                        }
                        $defaultState | ConvertTo-Json -Depth 10 | Out-File -FilePath $statePath -Encoding UTF8
                        $changes += "Created new sync-state.json"
                        
                        $success = $true
                        $message = "Repaired sync state (backup created)"
                        Write-HealLog -Message "Repaired sync state: $statePath" -Level "SUCCESS"
                    } catch {
                        $success = $false
                        $message = "Failed to repair sync state: $($_.Exception.Message)"
                        $changes += "Error: $($_.Exception.Message)"
                    }
                    
                    Write-HealHistoryEntry -Operation "Repair" -IssueType 'CorruptedSyncState' -Status $(if ($success) { "Success" } else { "Failed" }) `
                        -Details ($changes -join "; ") -ProjectRoot $ProjectRoot -WhatIf:$WhatIf
                }

    return @{
        Success = $success
        IssueType = 'CorruptedSyncState'
        Message = $message
        Changes = $changes
    }
}

