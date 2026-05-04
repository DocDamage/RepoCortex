Set-StrictMode -Version Latest

function Test-PythonImport {
    [CmdletBinding()]
    param([string]$ImportName)
    
    $probe = "import importlib.util; print(bool(importlib.util.find_spec(r'$ImportName')))"
    $resultRaw = & python -c $probe 2>$null
    $result = if ($null -eq $resultRaw) { "" } else { ($resultRaw | Out-String).Trim() }
    return ($LASTEXITCODE -eq 0 -and $result -eq "True")
}

function Get-PythonPackageVersion {
    [CmdletBinding()]
    param([string]$ImportName)
    
    try {
        $probe = "import $ImportName; print(getattr($ImportName, '__version__', 'unknown'))"
        $resultRaw = & python -c $probe 2>$null
        if ($LASTEXITCODE -eq 0 -and $null -ne $resultRaw) {
            return ($resultRaw | Out-String).Trim()
        }
    } catch {
        return $null
    }
    return $null
}

function Get-PythonVersion {
    try {
        $resultRaw = & python --version 2>&1
        if ($LASTEXITCODE -eq 0 -and $null -ne $resultRaw) {
            $versionLine = ($resultRaw | Out-String).Trim()
            if ($versionLine -match "Python\s+(\d+\.\d+\.\d+)") {
                return $matches[1]
            } elseif ($versionLine -match "Python\s+(\d+\.\d+)") {
                return $matches[1] + ".0"
            }
        }
    } catch {
        return $null
    }
    return $null
}

function Test-VersionMeetsMinimum {
    [CmdletBinding()]
    param([string]$Version, [string]$Minimum)
    
    if ([string]::IsNullOrWhiteSpace($Version) -or $Version -eq "unknown") { return $false }
    try {
        $v = [version]$Version
        $min = [version]$Minimum
        return ($v -ge $min)
    } catch {
        return $false
    }
}

