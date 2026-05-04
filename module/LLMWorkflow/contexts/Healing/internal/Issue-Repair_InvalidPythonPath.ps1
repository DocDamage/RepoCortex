Set-StrictMode -Version Latest

function Repair-HealingIssue_InvalidPythonPath {
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
                    $changes += "Would search for Python installations"
                    $success = $true
                    $message = "Would search for and configure Python (WhatIf mode)"
                } else {
                    $foundPythons = Find-PythonInstallation
                    if ($foundPythons.Count -eq 0) {
                        $success = $false
                        $message = "No Python installation found on system"
                        $changes += "Searched common Python locations - none found"
                    } elseif ($foundPythons.Count -eq 1 -or $Force) {
                        $selected = $foundPythons[0]
                        $changes += "Found Python: $($selected.Path) ($($selected.Version))"
                        
                        # Add to PATH for current session
                        $pythonDir = Split-Path -Parent $selected.Path
                        $pathEntries = $env:PATH -split [System.IO.Path]::PathSeparator
                        if ($pathEntries -notcontains $pythonDir) {
                            $env:PATH = "$pythonDir$([System.IO.Path]::PathSeparator)$env:PATH"
                            $changes += "Added Python directory to PATH for current session"
                        } else {
                            $changes += "Python directory already in PATH"
                        }
                        
                        # Suggest permanent addition
                        if ($Interactive -and -not $Force) {
                            Write-Information "Found Python at: $($selected.Path)"
                            Write-Information "Added to current session PATH."
                            Write-Information "To add permanently, run:"
                            Write-Information "  [Environment]::SetEnvironmentVariable('PATH', '`$env:PATH;$pythonDir', 'User')"
                        }
                        
                        $success = $true
                        $message = "Configured Python: $($selected.Path)"
                        Write-HealLog -Message "Configured Python: $($selected.Path)" -Level "SUCCESS"
                    } else {
                        if ($Interactive) {
                            Write-Information "Multiple Python installations found:"
                            for ($i = 0; $i -lt $foundPythons.Count; $i++) {
                                Write-Information "  [$i] $($foundPythons[$i].Path) - $($foundPythons[$i].Version)"
                            }
                            $choice = Read-Host "Select Python to use (0-$($foundPythons.Count - 1))"
                            if ($choice -match '^\d+$' -and [int]$choice -lt $foundPythons.Count) {
                                $selected = $foundPythons[[int]$choice]
                                $pythonDir = Split-Path -Parent $selected.Path
                                $pathEntries = $env:PATH -split [System.IO.Path]::PathSeparator
                                if ($pathEntries -notcontains $pythonDir) {
                                    $env:PATH = "$pythonDir$([System.IO.Path]::PathSeparator)$env:PATH"
                                }
                                $changes += "Selected and configured: $($selected.Path)"
                                $success = $true
                                $message = "Configured Python: $($selected.Path)"
                            } else {
                                $success = $false
                                $message = "Invalid selection"
                            }
                        } else {
                            # Auto-select first one
                            $selected = $foundPythons[0]
                            $pythonDir = Split-Path -Parent $selected.Path
                            $pathEntries = $env:PATH -split [System.IO.Path]::PathSeparator
                            if ($pathEntries -notcontains $pythonDir) {
                                $env:PATH = "$pythonDir$([System.IO.Path]::PathSeparator)$env:PATH"
                            }
                            $changes += "Auto-selected: $($selected.Path)"
                            $success = $true
                            $message = "Configured Python: $($selected.Path)"
                        }
                    }
                    
                    Write-HealHistoryEntry -Operation "Repair" -IssueType 'InvalidPythonPath' -Status $(if ($success) { "Success" } else { "Failed" }) `
                        -Details ($changes -join "; ") -ProjectRoot $ProjectRoot -WhatIf:$WhatIf
                }

    return @{
        Success = $success
        IssueType = 'InvalidPythonPath'
        Message = $message
        Changes = $changes
    }
}

