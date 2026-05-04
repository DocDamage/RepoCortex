Set-StrictMode -Version Latest

function Test-LLMWorkflowIssue {
    <#
    .SYNOPSIS
        Detects specific issues in the LLM Workflow environment.
    .DESCRIPTION
        Tests for a specific issue type and returns detailed information about the problem.
    .PARAMETER IssueType
        The type of issue to test for.
    .PARAMETER ProjectRoot
        Path to the project root.
    .EXAMPLE
        Test-LLMWorkflowIssue -IssueType MissingEnvFile
        Tests if the .env file is missing.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory=$true)]
        [IssueType]$IssueType,
        
        [string]$ProjectRoot = "."
    )
    
    $projectPath = Resolve-HealLiteralPath -LiteralPath $ProjectRoot -Context 'Issue detection project-root resolution'
    if (-not $projectPath) {
        return @{
            Detected = $true
            Category = [IssueCategory]::CRITICAL
            Message = "Project root does not exist: $ProjectRoot"
            Details = @{}
            CanFix = $false
        }
    }
    
    switch ($IssueType) {
        "MissingEnvFile" {
            $envPath = Join-Path $projectPath ".env"
            $exists = Test-Path -LiteralPath $envPath
            return @{
                Detected = -not $exists
                Category = [IssueCategory]::WARNING
                Message = if ($exists) { ".env file exists" } else { "Missing .env file" }
                Details = @{ Path = $envPath }
                CanFix = $true
                FixDescription = "Create .env file from template"
            }
        }
        
        "InvalidPythonPath" {
            $python = Test-IsPythonAvailable
            $detected = $null -eq $python
            return @{
                Detected = $detected
                Category = [IssueCategory]::CRITICAL
                Message = if ($detected) { "Python not found on PATH" } else { "Python available: $($python.Path)" }
                Details = $python
                CanFix = $detected
                FixDescription = "Search for and configure Python installation"
            }
        }
        
        "MissingChromaDB" {
            $python = Test-IsPythonAvailable
            if (-not $python) {
                return @{
                    Detected = $false
                    Category = [IssueCategory]::INFO
                    Message = "Cannot check ChromaDB - Python not available"
                    Details = @{}
                    CanFix = $false
                }
            }
            $hasChroma = Test-PythonModule -ModuleName "chromadb" -PythonCommand $python.Command
            return @{
                Detected = -not $hasChroma
                Category = [IssueCategory]::WARNING
                Message = if ($hasChroma) { "ChromaDB module available" } else { "ChromaDB module not installed" }
                Details = @{ PythonCommand = $python.Command }
                CanFix = (-not $hasChroma)
                FixDescription = "Install ChromaDB via pip"
            }
        }
        
        "MissingPalaceDirectory" {
            $palacePath = Join-Path $HOME ".mempalace" "palace"
            $envPath = [Environment]::GetEnvironmentVariable("MEMPALACE_PALACE_PATH")
            if ($envPath) {
                $palacePath = $envPath
            }
            $expandedPath = $palacePath.Replace("~", $HOME)
            $exists = Test-Path -LiteralPath $expandedPath
            return @{
                Detected = -not $exists
                Category = [IssueCategory]::WARNING
                Message = if ($exists) { "Palace directory exists" } else { "Missing palace directory: $palacePath" }
                Details = @{ Path = $palacePath; ExpandedPath = $expandedPath }
                CanFix = (-not $exists)
                FixDescription = "Create palace directory with default collection"
            }
        }
        
        "CorruptedSyncState" {
            $statePath = Join-Path $projectPath ".memorybridge" "sync-state.json"
            if (-not (Test-Path -LiteralPath $statePath)) {
                return @{
                    Detected = $false
                    Category = [IssueCategory]::INFO
                    Message = "No sync state file exists (will be created on first sync)"
                    Details = @{ Path = $statePath }
                    CanFix = $false
                }
            }
            try {
                $content = Get-Content -LiteralPath $statePath -Raw -ErrorAction Stop
                $null = $content | ConvertFrom-Json -ErrorAction Stop
                return @{
                    Detected = $false
                    Category = [IssueCategory]::INFO
                    Message = "Sync state file is valid"
                    Details = @{ Path = $statePath }
                    CanFix = $false
                }
            } catch {
                return @{
                    Detected = $true
                    Category = [IssueCategory]::WARNING
                    Message = "Corrupted sync-state.json detected"
                    Details = @{ Path = $statePath; Error = $_.Exception.Message }
                    CanFix = $true
                    FixDescription = "Backup and recreate sync state"
                }
            }
        }
        
        "TemplateDrift" {
            $toolkitSource = Join-Path $PSScriptRoot "templates" "tools"
            if (-not (Test-Path -LiteralPath $toolkitSource)) {
                return @{
                    Detected = $false
                    Category = [IssueCategory]::INFO
                    Message = "Cannot check template drift - template source not found"
                    Details = @{}
                    CanFix = $false
                }
            }
            
            $tools = @("codemunch", "contextlattice", "memorybridge")
            $drifted = @()
            foreach ($tool in $tools) {
                $sourceDir = Join-Path $toolkitSource $tool
                $projectDir = Join-Path (Join-Path $projectPath "tools") $tool
                if ((Test-Path -LiteralPath $sourceDir) -and -not (Test-Path -LiteralPath $projectDir)) {
                    $drifted += $tool
                }
            }
            return @{
                Detected = $drifted.Count -gt 0
                Category = [IssueCategory]::INFO
                Message = if ($drifted.Count -gt 0) { "Template drift detected for: $($drifted -join ', ')" } else { "All templates synchronized" }
                Details = @{ DriftedTools = $drifted }
                CanFix = $drifted.Count -gt 0
                FixDescription = "Re-sync templates from module"
            }
        }
        
        "MissingContextLatticeApiKey" {
            $key = [Environment]::GetEnvironmentVariable("CONTEXTLATTICE_ORCHESTRATOR_API_KEY")
            $envFile = Join-Path $projectPath ".env"
            $hasKeyInEnv = $false
            if (Test-Path -LiteralPath $envFile) {
                $envContent = Get-Content -LiteralPath $envFile -Raw
                $hasKeyInEnv = $envContent -match "CONTEXTLATTICE_ORCHESTRATOR_API_KEY\s*="
            }
            $hasKeyInScriptScope = $null -ne $script:LLMWorkflowContextLatticeApiKey
            $detected = [string]::IsNullOrWhiteSpace($key) -and -not $hasKeyInEnv -and -not $hasKeyInScriptScope
            return @{
                Detected = $detected
                Category = [IssueCategory]::CRITICAL
                Message = if ($detected) { "ContextLattice API key not configured" } else { "ContextLattice API key is set" }
                Details = @{ 
                    InEnvironment = -not [string]::IsNullOrWhiteSpace($key)
                    InEnvFile = $hasKeyInEnv
                    InScriptScope = $hasKeyInScriptScope
                }
                CanFix = $detected
                FixDescription = "Prompt for API key with masking"
            }
        }
        
        "MissingContextLatticeUrl" {
            $url = [Environment]::GetEnvironmentVariable("CONTEXTLATTICE_ORCHESTRATOR_URL")
            $envFile = Join-Path $projectPath ".env"
            $hasUrlInEnv = $false
            if (Test-Path -LiteralPath $envFile) {
                $envContent = Get-Content -LiteralPath $envFile -Raw
                $hasUrlInEnv = $envContent -match "CONTEXTLATTICE_ORCHESTRATOR_URL\s*="
            }
            $detected = [string]::IsNullOrWhiteSpace($url) -and -not $hasUrlInEnv
            return @{
                Detected = $detected
                Category = [IssueCategory]::WARNING
                Message = if ($detected) { "ContextLattice URL not configured (will use default)" } else { "ContextLattice URL: $url" }
                Details = @{ CurrentValue = $url; InEnvFile = $hasUrlInEnv }
                CanFix = $detected
                FixDescription = "Set default ContextLattice URL"
            }
        }
        
        "MissingBridgeConfig" {
            $configPath = Join-Path $projectPath ".memorybridge" "bridge.config.json"
            $exists = Test-Path -LiteralPath $configPath
            return @{
                Detected = -not $exists
                Category = [IssueCategory]::WARNING
                Message = if ($exists) { "Bridge config exists" } else { "Missing bridge.config.json" }
                Details = @{ Path = $configPath }
                CanFix = (-not $exists)
                FixDescription = "Create default bridge.config.json"
            }
        }
        
        "CorruptedBridgeConfig" {
            $configPath = Join-Path $projectPath ".memorybridge" "bridge.config.json"
            if (-not (Test-Path -LiteralPath $configPath)) {
                return @{
                    Detected = $false
                    Category = [IssueCategory]::INFO
                    Message = "No bridge config to validate"
                    Details = @{}
                    CanFix = $false
                }
            }
            try {
                $content = Get-Content -LiteralPath $configPath -Raw
                $null = $content | ConvertFrom-Json -ErrorAction Stop
                return @{
                    Detected = $false
                    Category = [IssueCategory]::INFO
                    Message = "Bridge config is valid JSON"
                    Details = @{ Path = $configPath }
                    CanFix = $false
                }
            } catch {
                return @{
                    Detected = $true
                    Category = [IssueCategory]::CRITICAL
                    Message = "Bridge config is corrupted (invalid JSON)"
                    Details = @{ Path = $configPath; Error = $_.Exception.Message }
                    CanFix = $true
                    FixDescription = "Backup and recreate bridge config"
                }
            }
        }
        
        default {
            return @{
                Detected = $false
                Category = [IssueCategory]::INFO
                Message = "Unknown issue type: $IssueType"
                Details = @{}
                CanFix = $false
            }
        }
    }
}
