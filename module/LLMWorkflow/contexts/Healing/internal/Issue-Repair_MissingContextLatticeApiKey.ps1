Set-StrictMode -Version Latest

function Repair-HealingIssue_MissingContextLatticeApiKey {
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
                    $changes += "Would prompt for ContextLattice API key"
                    $changes += "Would add key to .env file"
                    $success = $true
                    $message = "Would configure ContextLattice API key (WhatIf mode)"
                } else {
                    $envPath = Join-Path $projectPath ".env"
                    
                    if ($Interactive -or $Force) {
                        if ($Interactive) {
                            Write-Information "ContextLattice API Key Configuration"
                            Write-Information "You can obtain an API key from your ContextLattice orchestrator."
                            $apiKey = Read-SecureInput -Prompt "Enter your ContextLattice API key: "
                        } else {
                            # In Force mode without interactive, use environment key if set; otherwise use placeholder.
                            $apiKey = [Environment]::GetEnvironmentVariable("CONTEXTLATTICE_ORCHESTRATOR_API_KEY")
                            if ([string]::IsNullOrWhiteSpace($apiKey)) {
                                $apiKey = "your-api-key-here"
                            }
                        }
                        
                        $allowPlaceholder = ($Force -and -not $Interactive -and $apiKey -eq "your-api-key-here")
                        if (-not [string]::IsNullOrWhiteSpace($apiKey) -and ($apiKey -ne "your-api-key-here" -or $allowPlaceholder)) {
                            # Store securely in config instead of leaking to process-scoped env var.
                            # Process-scoped env vars are visible to child processes and other processes
                            # on the same machine, creating a credential leakage surface.
                            if ($apiKey -ne "your-api-key-here") {
                                # Store in module script scope only - not leaked to process env
                                $script:LLMWorkflowContextLatticeApiKey = ConvertTo-SecureString -String $apiKey -AsPlainText -Force
                                $changes += "Stored API key in module config"
                            } else {
                                $changes += "Configured placeholder API key for non-interactive force mode"
                            }
                            
                            # Add to .env file
                            if (Test-Path -LiteralPath $envPath) {
                                $envContent = Get-Content -LiteralPath $envPath -Raw
                                if ($envContent -match "CONTEXTLATTICE_ORCHESTRATOR_API_KEY\s*=") {
                                    # Replace existing
                                    $envContent = $envContent -replace "CONTEXTLATTICE_ORCHESTRATOR_API_KEY\s*=.*", "CONTEXTLATTICE_ORCHESTRATOR_API_KEY=$apiKey"
                                } else {
                                    # Add new
                                    $envContent += "`nCONTEXTLATTICE_ORCHESTRATOR_API_KEY=$apiKey`n"
                                }
                                $envContent | Out-File -FilePath $envPath -Encoding UTF8
                                $changes += "Updated API key in .env file"
                            } else {
                                # Create new .env with just the key
                                "CONTEXTLATTICE_ORCHESTRATOR_API_KEY=$apiKey`n" | Out-File -FilePath $envPath -Encoding UTF8
                                $changes += "Created .env file with API key"
                            }
                            
                            $success = $true
                            $message = if ($apiKey -eq "your-api-key-here") {
                                "Configured placeholder ContextLattice API key in .env (manual update required)"
                            } else {
                                "Configured ContextLattice API key"
                            }
                            Write-HealLog -Message $message -Level "SUCCESS"
                        } else {
                            $success = $false
                            $message = "No API key provided"
                            $changes += "User did not provide an API key"
                        }
                    } else {
                        $success = $false
                        $message = "Cannot configure API key in non-interactive mode without -Force"
                    }
                    
                    Write-HealHistoryEntry -Operation "Repair" -IssueType 'MissingContextLatticeApiKey' -Status $(if ($success) { "Success" } else { "Failed" }) `
                        -Details ($changes -join "; ") -ProjectRoot $ProjectRoot -WhatIf:$WhatIf
                }

    return @{
        Success = $success
        IssueType = 'MissingContextLatticeApiKey'
        Message = $message
        Changes = $changes
    }
}

