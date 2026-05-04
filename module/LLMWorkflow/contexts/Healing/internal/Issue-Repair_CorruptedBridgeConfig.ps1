Set-StrictMode -Version Latest

function Repair-HealingIssue_CorruptedBridgeConfig {
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

                $configPath = Join-Path $projectPath ".memorybridge" "bridge.config.json"
                if ($WhatIf) {
                    $changes += "Would backup corrupted bridge.config.json"
                    $changes += "Would recreate bridge.config.json with defaults"
                    $success = $true
                    $message = "Would repair bridge config (WhatIf mode)"
                } else {
                    try {
                        if (Test-Path -LiteralPath $configPath) {
                            $backupPath = "$configPath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                            Copy-Item -LiteralPath $configPath -Destination $backupPath
                            $changes += "Backed up corrupted config to: $backupPath"
                        }
                        
                        $defaultConfig = Get-DefaultBridgeConfig
                        $defaultConfig | Out-File -FilePath $configPath -Encoding UTF8
                        $changes += "Recreated bridge.config.json"
                        
                        $success = $true
                        $message = "Repaired bridge configuration (backup created)"
                        Write-HealLog -Message "Repaired bridge config: $configPath" -Level "SUCCESS"
                    } catch {
                        $success = $false
                        $message = "Failed to repair bridge config: $($_.Exception.Message)"
                        $changes += "Error: $($_.Exception.Message)"
                    }
                    
                    Write-HealHistoryEntry -Operation "Repair" -IssueType 'CorruptedBridgeConfig' -Status $(if ($success) { "Success" } else { "Failed" }) `
                        -Details ($changes -join "; ") -ProjectRoot $ProjectRoot -WhatIf:$WhatIf
                }

    return @{
        Success = $success
        IssueType = 'CorruptedBridgeConfig'
        Message = $message
        Changes = $changes
    }
}

