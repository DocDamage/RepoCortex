Set-StrictMode -Version Latest

function Repair-HealingIssue_MissingChromaDB {
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
                    $changes += "Would run: python -m pip install chromadb"
                    $success = $true
                    $message = "Would install ChromaDB (WhatIf mode)"
                } else {
                    $python = Test-IsPythonAvailable
                    if (-not $python) {
                        $success = $false
                        $message = "Cannot install ChromaDB - Python not available"
                    } else {
                        Write-Information "Installing ChromaDB..." -InformationAction Continue
                        try {
                            $output = & $python.Command -m pip install chromadb 2>&1
                            $exitCode = $LASTEXITCODE
                            
                            if ($exitCode -eq 0) {
                                $changes += "Installed ChromaDB via pip"
                                $success = $true
                                $message = "ChromaDB installed successfully"
                                Write-HealLog -Message "Installed ChromaDB" -Level "SUCCESS"
                            } else {
                                $changes += "pip install failed with exit code $exitCode"
                                $success = $false
                                $message = "Failed to install ChromaDB"
                            }
                        } catch {
                            $changes += "Exception during install: $($_.Exception.Message)"
                            $success = $false
                            $message = "Failed to install ChromaDB: $($_.Exception.Message)"
                        }
                    }
                    
                    Write-HealHistoryEntry -Operation "Repair" -IssueType 'MissingChromaDB' -Status $(if ($success) { "Success" } else { "Failed" }) `
                        -Details ($changes -join "; ") -ProjectRoot $ProjectRoot -WhatIf:$WhatIf
                }

    return @{
        Success = $success
        IssueType = 'MissingChromaDB'
        Message = $message
        Changes = $changes
    }
}

