Set-StrictMode -Version Latest

function Repair-HealingIssue_TemplateDrift {
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
                    $changes += "Would re-sync tool templates from module"
                    $success = $true
                    $message = "Would re-sync templates (WhatIf mode)"
                } else {
                    try {
                        $toolkitSource = Join-Path $PSScriptRoot "templates" "tools"
                        $toolsTarget = Join-Path $projectPath "tools"
                        
                        $tools = @("codemunch", "contextlattice", "memorybridge")
                        foreach ($tool in $tools) {
                            $sourceDir = Join-Path $toolkitSource $tool
                            $targetDir = Join-Path $toolsTarget $tool
                            
                            if ((Test-Path -LiteralPath $sourceDir) -and -not (Test-Path -LiteralPath $targetDir)) {
                                Copy-Item -Path $sourceDir -Destination $targetDir -Recurse -Force
                                $changes += "Synced $tool template"
                            }
                        }
                        
                        $success = $true
                        $message = "Re-synced templates from module"
                        Write-HealLog -Message "Re-synced templates" -Level "SUCCESS"
                    } catch {
                        $success = $false
                        $message = "Failed to re-sync templates: $($_.Exception.Message)"
                        $changes += "Error: $($_.Exception.Message)"
                    }
                    
                    Write-HealHistoryEntry -Operation "Repair" -IssueType 'TemplateDrift' -Status $(if ($success) { "Success" } else { "Failed" }) `
                        -Details ($changes -join "; ") -ProjectRoot $ProjectRoot -WhatIf:$WhatIf
                }

    return @{
        Success = $success
        IssueType = 'TemplateDrift'
        Message = $message
        Changes = $changes
    }
}

