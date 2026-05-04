Set-StrictMode -Version Latest

function Repair-HealingIssue_MissingContextLatticeUrl {
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
                    $changes += "Would set default ContextLattice URL: http://127.0.0.1:8075"
                    $success = $true
                    $message = "Would set default URL (WhatIf mode)"
                } else {
                    $defaultUrl = "http://127.0.0.1:8075"
                    $changes += "Using default URL: $defaultUrl"
                    
                    # Also add to .env
                    $envPath = Join-Path $projectPath ".env"
                    if (Test-Path -LiteralPath $envPath) {
                        $envContent = Get-Content -LiteralPath $envPath -Raw
                        if ($envContent -notmatch "CONTEXTLATTICE_ORCHESTRATOR_URL\s*=") {
                            $envContent += "`nCONTEXTLATTICE_ORCHESTRATOR_URL=$defaultUrl`n"
                            $envContent | Out-File -FilePath $envPath -Encoding UTF8
                            $changes += "Added URL to .env file"
                        }
                    }
                    
                    $success = $true
                    $message = "Set default ContextLattice URL"
                    Write-HealLog -Message "Set default ContextLattice URL" -Level "SUCCESS"
                    
                    Write-HealHistoryEntry -Operation "Repair" -IssueType 'MissingContextLatticeUrl' -Status "Success" `
                        -Details ($changes -join "; ") -ProjectRoot $ProjectRoot -WhatIf:$WhatIf
                }

    return @{
        Success = $success
        IssueType = 'MissingContextLatticeUrl'
        Message = $message
        Changes = $changes
    }
}

