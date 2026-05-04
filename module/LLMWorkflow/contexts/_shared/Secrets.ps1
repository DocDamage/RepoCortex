Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Secure secret retrieval for LLMWorkflow.
.DESCRIPTION
    Reads secrets from SecretManagement vaults, .env files, or user-scope
    environment variables without polluting the process environment.
    Never writes secrets to process-scoped env vars.
#>

function Get-LLMSecret {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [string]$EnvFilePath,

        [switch]$AsSecureString
    )

    # 1. Try SecretManagement vault if available
    $vaultCmd = Get-Command Get-Secret -ErrorAction Ignore
    if ($vaultCmd) {
        try {
            $vaultValue = Get-Secret -Name $Name -Vault LLMWorkflow -ErrorAction Stop
            if ($vaultValue) {
                if ($AsSecureString) {
                    return $vaultValue
                }
                if ($vaultValue -is [System.Security.SecureString]) {
                    return ConvertFrom-SecureString -SecureString $vaultValue -AsPlainText
                }
                return [string]$vaultValue
            }
        }
        catch {
            Write-Verbose "SecretManagement vault lookup failed for ${Name}: $_"
        }
    }

    # 2. Read from .env file directly (no process pollution)
    if ($EnvFilePath -and (Test-Path -LiteralPath $EnvFilePath)) {
        $envMap = Read-EnvFile -Path $EnvFilePath
        if ($envMap.ContainsKey($Name)) {
            $value = $envMap[$Name]
            if ($AsSecureString) {
                return ConvertTo-SecureString -String $value -AsPlainText -Force
            }
            return $value
        }
    }

    # 3. Fall back to user-scope environment for non-sensitive config only
    # Secrets should NOT be stored in persistent env vars, but we read User scope
    # as a last resort for backward compatibility during transition.
    $userValue = [System.Environment]::GetEnvironmentVariable($Name, 'User')
    if (-not [string]::IsNullOrEmpty($userValue)) {
        Write-Warning "Get-LLMSecret: Reading ${Name} from User-scope environment. Consider migrating to .env file or SecretManagement vault."
        if ($AsSecureString) {
            return ConvertTo-SecureString -String $userValue -AsPlainText -Force
        }
        return $userValue
    }

    # Not found
    return $null
}

function Read-EnvFile {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param([string]$Path)

    $result = @{}
    if (-not (Test-Path -LiteralPath $Path)) {
        return $result
    }

    foreach ($rawLine in (Get-Content -LiteralPath $Path)) {
        $line = $rawLine.Trim()
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) {
            continue
        }
        if ($line -match '^(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$') {
            $name = $matches[1]
            $value = $matches[2]
            if ($value.Length -ge 2) {
                if (($value.StartsWith("'") -and $value.EndsWith("'")) -or
                    ($value.StartsWith('"') -and $value.EndsWith('"'))) {
                    $value = $value.Substring(1, $value.Length - 2)
                }
            }
            $result[$name] = $value
        }
    }

    return $result
}

function Protect-LLMSecret {
    [CmdletBinding()]
    [OutputType([System.Security.SecureString])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$PlainText
    )
    process {
        return ConvertTo-SecureString -String $PlainText -AsPlainText -Force
    }
}
