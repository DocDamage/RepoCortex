Set-StrictMode -Version Latest

function Repair-HealingIssue_MissingBridgeConfig {
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

                if ($WhatIf) {
                    $changes += "Would create default bridge.config.json"
                    $success = $true
                    $message = "Would create bridge config (WhatIf mode)"
                } else {
                    try {
                        $bridgeDir = Join-Path $projectPath ".memorybridge"
                        $configPath = Join-Path $bridgeDir "bridge.config.json"
                        
                        if (-not (Test-Path -LiteralPath $bridgeDir)) {
                            New-Item -ItemType Directory -Path $bridgeDir -Force | Out-Null
                            $changes += "Created .memorybridge directory"
                        }
                        
                        $defaultConfig = Get-DefaultBridgeConfig
                        $defaultConfig | Out-File -FilePath $configPath -Encoding UTF8
                        $changes += "Created bridge.config.json"
                        
                        $success = $true
                        $message = "Created default bridge configuration"
                        Write-HealLog -Message "Created bridge config: $configPath" -Level "SUCCESS"
                    } catch {
                        $success = $false
                        $message = "Failed to create bridge config: $($_.Exception.Message)"
                        $changes += "Error: $($_.Exception.Message)"
                    }
                    
                    Write-HealHistoryEntry -Operation "Repair" -IssueType 'MissingBridgeConfig' -Status $(if ($success) { "Success" } else { "Failed" }) `
                        -Details ($changes -join "; ") -ProjectRoot $ProjectRoot -WhatIf:$WhatIf
                }

    return @{
        Success = $success
        IssueType = 'MissingBridgeConfig'
        Message = $message
        Changes = $changes
    }
}

