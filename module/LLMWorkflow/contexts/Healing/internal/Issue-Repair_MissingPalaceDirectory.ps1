Set-StrictMode -Version Latest

function Repair-HealingIssue_MissingPalaceDirectory {
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
                    $changes += "Would create palace directory at ~/.mempalace/palace"
                    $changes += "Would create default collection 'mempalace_drawers'"
                    $success = $true
                    $message = "Would create palace directory and collection (WhatIf mode)"
                } else {
                    $palacePath = Join-Path $HOME ".mempalace" "palace"
                    $envPath = [Environment]::GetEnvironmentVariable("MEMPALACE_PALACE_PATH")
                    if ($envPath) {
                        $palacePath = $envPath.Replace("~", $HOME)
                    }
                    
                    try {
                        New-Item -ItemType Directory -Path $palacePath -Force | Out-Null
                        $changes += "Created palace directory: $palacePath"
                        
                        # Create default collection using Python
                        $python = Test-IsPythonAvailable
                        if ($python) {
                            $script = @"
import chromadb
client = chromadb.PersistentClient(path=r'$palacePath')
try:
    collection = client.create_collection('mempalace_drawers')
    print('CREATED')
except Exception as e:
    if 'already exists' in str(e):
        print('EXISTS')
    else:
        print('ERROR:', str(e))
"@
                            $result = & $python.Command -c $script 2>&1
                            if ($result -contains "CREATED") {
                                $changes += "Created default collection: mempalcace_drawers"
                            } elseif ($result -contains "EXISTS") {
                                $changes += "Collection already exists"
                            }
                        }
                        
                        $success = $true
                        $message = "Created palace directory with default collection"
                        Write-HealLog -Message "Created palace directory: $palacePath" -Level "SUCCESS"
                    } catch {
                        $success = $false
                        $message = "Failed to create palace directory: $($_.Exception.Message)"
                        $changes += "Error: $($_.Exception.Message)"
                    }
                    
                    Write-HealHistoryEntry -Operation "Repair" -IssueType 'MissingPalaceDirectory' -Status $(if ($success) { "Success" } else { "Failed" }) `
                        -Details ($changes -join "; ") -ProjectRoot $ProjectRoot -WhatIf:$WhatIf
                }

    return @{
        Success = $success
        IssueType = 'MissingPalaceDirectory'
        Message = $message
        Changes = $changes
    }
}

