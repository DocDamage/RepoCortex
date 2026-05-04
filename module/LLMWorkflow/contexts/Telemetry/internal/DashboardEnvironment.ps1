Set-StrictMode -Version Latest

function Import-EnvFile {
    [CmdletBinding()]
    param([string]$Path)
    
    $secrets = @{}
    if (-not (Test-Path -LiteralPath $Path)) { return $secrets }
    
    # Sensitive key patterns that should NOT be set as process-scoped env vars
    # to prevent credential leakage to child processes.
    $sensitiveKeyPatterns = @('KEY', 'SECRET', 'TOKEN', 'PASSWORD', 'API_KEY')
    
    foreach ($rawLine in (Get-Content -LiteralPath $Path)) {
        $line = $rawLine.Trim()
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line.StartsWith("#")) { continue }
        if ($line -match "^(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$") {
            $name = $matches[1]
            $value = $matches[2]
            if ($value.Length -ge 2) {
                if (($value.StartsWith("'") -and $value.EndsWith("'")) -or ($value.StartsWith('"') -and $value.EndsWith('"'))) {
                    $value = $value.Substring(1, $value.Length - 2)
                }
            }
            # Check if this is a sensitive variable - skip process-scoped setting
            $isSensitive = $false
            foreach ($pattern in $sensitiveKeyPatterns) {
                if ($name -match $pattern) {
                    $isSensitive = $true
                    break
                }
            }
            if ($isSensitive) {
                $secrets[$name] = $value
                Write-Verbose "Skipping process-scoped env var for sensitive key: $name"
                continue
            }
            [System.Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }
    return $secrets
}

function Get-FirstEnvValue {
    [CmdletBinding()]
    param([string[]]$Names)
    
    foreach ($name in $Names) {
        $value = [System.Environment]::GetEnvironmentVariable($name, "Process")
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return @{ Name = $name; Value = $value }
        }
        if ($script:DashboardEnvSecrets -and $script:DashboardEnvSecrets.ContainsKey($name)) {
            return @{ Name = $name; Value = $script:DashboardEnvSecrets[$name] }
        }
    }
    return @{ Name = ""; Value = "" }
}

#endregion

#region Main Dashboard Logic

