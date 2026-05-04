Set-StrictMode -Version Latest

function Test-IsPythonAvailable {
    <#
    .SYNOPSIS
        Tests if Python is available and returns details.
    #>
    [CmdletBinding()]
    param()
    
    $pythonCmds = @("python", "python3", "py")
    $foundPython = $null
    
    foreach ($cmd in $pythonCmds) {
        $foundPath = Get-HealCommandPath -CommandName $cmd -Context 'Python command availability probe'
        if (-not [string]::IsNullOrWhiteSpace($foundPath)) {
            try {
                $version = & $cmd --version 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $foundPython = @{
                        Command = $cmd
                        Path = $foundPath
                        Version = $version
                    }
                    break
                }
            } catch {
                continue
            }
        }
    }
    
    return $foundPython
}

function Find-PythonInstallation {
    <#
    .SYNOPSIS
        Searches for Python installations in common locations.
    #>
    [CmdletBinding()]
    param()
    
    $possiblePaths = @()
    
    # Common Windows Python locations
    $isWindowsPlatform = ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows) -or ($PSVersionTable.PSVersion.Major -lt 6 -and $env:OS -eq 'Windows_NT')
    if ($isWindowsPlatform) {
        $systemDrive = if ($env:SystemDrive) { $env:SystemDrive } else { 'C:' }
        # Search common install roots via environment variables and wildcards
        $searchRoots = @(
            (Join-Path $env:ProgramFiles 'Python*'),
            (Join-Path ${env:ProgramFiles(x86)} 'Python*'),
            (Join-Path $systemDrive 'Python*')
        ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

        foreach ($rootPattern in $searchRoots) {
            $roots = Get-HealChildItems -Path $rootPattern -ItemType Directory -Context 'Python root directory scan'
            foreach ($pythonRoot in $roots) {
                $versions = Get-HealChildItems -Path $pythonRoot.FullName -ItemType Directory -Context 'Python version directory scan' |
                    Where-Object { $_.Name -match '^\d+' } |
                    Sort-Object Name -Descending
                foreach ($ver in $versions) {
                    $pythonExe = Join-Path $ver.FullName 'python.exe'
                    if (Test-Path $pythonExe) {
                        $possiblePaths += $pythonExe
                    }
                }
                # Also check root-level python.exe
                $rootPython = Join-Path $pythonRoot.FullName 'python.exe'
                if (Test-Path $rootPython) {
                    $possiblePaths += $rootPython
                }
            }
        }
        
        # Microsoft Store Python
        $storePath = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\python.exe'
        if (Test-Path $storePath) {
            $possiblePaths += $storePath
        }
        
        # Py launcher (use WINDIR/SystemRoot instead of hardcoded C:\Windows)
        $windowsDir = if ($env:SystemRoot) { $env:SystemRoot } elseif ($env:WINDIR) { $env:WINDIR } else { Join-Path $systemDrive 'Windows' }
        $pyPath = Join-Path $windowsDir 'py.exe'
        if (Test-Path $pyPath) {
            $possiblePaths += $pyPath
        }
    } else {
        # Linux/Mac common locations using wildcards for portability
        $unixSearchPaths = @('/usr/bin/python*', '/usr/local/bin/python*', '/opt/python*/bin/python*', "$HOME/.local/bin/python*")
        foreach ($pattern in $unixSearchPaths) {
            $matches = Get-HealChildItems -Path $pattern -ItemType File -Context 'Unix python path scan'
            foreach ($match in $matches) {
                $possiblePaths += $match.FullName
            }
        }
    }
    
    # Test each found Python
    $validPythons = @()
    foreach ($path in $possiblePaths) {
        try {
            $version = & $path --version 2>&1
            if ($LASTEXITCODE -eq 0) {
                $validPythons += @{
                    Path = $path
                    Version = $version
                }
            }
        } catch {
            continue
        }
    }
    
    return $validPythons
}

function Test-PythonModule {
    <#
    .SYNOPSIS
        Tests if a specific Python module is available.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ModuleName,
        
        [string]$PythonCommand = "python"
    )
    
    try {
        $probe = "import importlib.util; print(bool(importlib.util.find_spec(r'$ModuleName')))"
        $result = & $PythonCommand -c $probe 2>&1
        return ($result -eq "True")
    } catch {
        return $false
    }
}


