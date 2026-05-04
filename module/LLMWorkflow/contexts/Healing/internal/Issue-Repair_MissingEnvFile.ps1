Set-StrictMode -Version Latest

function Repair-HealingIssue_MissingEnvFile {
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

                $envPath = Join-Path $projectPath ".env"
                $template = Get-DefaultEnvTemplate
                
                if ($WhatIf) {
                    $changes += "Would create .env file at: $envPath"
                    $success = $true
                    $message = "Would create .env file (WhatIf mode)"
                } else {
                    $template | Out-File -FilePath $envPath -Encoding UTF8
                    $changes += "Created .env file at: $envPath"
                    Write-HealLog -Message "Created .env file: $envPath" -Level "SUCCESS"
                    $success = $true
                    $message = "Created .env file from template"
                    
                    Write-HealHistoryEntry -Operation "Repair" -IssueType 'MissingEnvFile' -Status "Success" `
                        -Details "Created $envPath" -ProjectRoot $ProjectRoot -WhatIf:$WhatIf
                }

    return @{
        Success = $success
        IssueType = 'MissingEnvFile'
        Message = $message
        Changes = $changes
    }
}

