Set-StrictMode -Version Latest

function Invoke-DashboardCheck {
    [CmdletBinding()]
    param(
        [string]$ProjectRoot,
        [string]$Provider,
        [switch]$CheckContext,
        [int]$TimeoutSec,
        [scriptblock]$OnCheckComplete
    )
    
    $checks = New-Object System.Collections.Generic.List[object]
    $totalChecks = 9
    if ($CheckContext) { $totalChecks += 2 }
    $currentCheck = 0
    
    $projectPath = (Resolve-Path -LiteralPath $ProjectRoot).Path
    $script:DashboardEnvSecrets = @{}
    $envFileSecrets = Import-EnvFile -Path (Join-Path $projectPath ".env")
    foreach ($kvp in $envFileSecrets.GetEnumerator()) { $script:DashboardEnvSecrets[$kvp.Key] = $kvp.Value }
    $orchSecrets = Import-EnvFile -Path (Join-Path $projectPath ".contextlattice" "orchestrator.env")
    foreach ($kvp in $orchSecrets.GetEnumerator()) { $script:DashboardEnvSecrets[$kvp.Key] = $kvp.Value }
    
    # Check 1: Python command
    $currentCheck++
    & $OnCheckComplete $currentCheck $totalChecks "python_command" "PENDING" "Checking..."
    $pythonCmd = Get-DashboardCommand -Name "python"
    $checks.Add([pscustomobject]@{
        Name = "python_command"
        Ok = ($null -ne $pythonCmd)
        Detail = if ($pythonCmd) { "Found: $($pythonCmd.Source)" } else { "Install Python and add python to PATH." }
        LatencyMs = $null
    })
    $pythonCommandStatus = "FAIL"
    if ($pythonCmd) { $pythonCommandStatus = "OK" }
    & $OnCheckComplete $currentCheck $totalChecks "python_command" $pythonCommandStatus $checks[-1].Detail
    
    # Check 2: Python version
    $currentCheck++
    & $OnCheckComplete $currentCheck $totalChecks "python_version" "PENDING" "Checking..."
    $pythonVersion = if ($pythonCmd) { Get-PythonVersion } else { $null }
    $minPython = "3.10.0"
    $pythonVersionOk = Test-VersionMeetsMinimum -Version $pythonVersion -Minimum $minPython
    if ($pythonVersion) {
        $checks.Add([pscustomobject]@{ Name = "python_version"; Ok = $pythonVersionOk; Detail = if ($pythonVersionOk) { $pythonVersion } else { "Found $pythonVersion, need >= $minPython" }; LatencyMs = $null })
    } else {
        $checks.Add([pscustomobject]@{ Name = "python_version"; Ok = $false; Detail = "Not installed"; LatencyMs = $null })
    }
    $pythonVersionStatus = "FAIL"
    if ($pythonVersionOk) {
        $pythonVersionStatus = "OK"
    } elseif ($pythonVersion) {
        $pythonVersionStatus = "WARN"
    }
    & $OnCheckComplete $currentCheck $totalChecks "python_version" $pythonVersionStatus $checks[-1].Detail
    
    # Check 3: CodeMunch runtime
    $currentCheck++
    & $OnCheckComplete $currentCheck $totalChecks "codemunch_runtime" "PENDING" "Checking..."
    $codemunchCmd = Get-DashboardCommand -Name "codemunch-pro"
    $codemunchImport = if ($pythonCmd) { Test-PythonImport -ImportName "codemunch_pro" } else { $false }
    $codemunchOk = ($null -ne $codemunchCmd) -or $codemunchImport
    $checks.Add([pscustomobject]@{
        Name = "codemunch_runtime"
        Ok = $codemunchOk
        Detail = if ($codemunchCmd) { "command: $($codemunchCmd.Source)" } elseif ($codemunchImport) { "python module codemunch_pro is importable" } else { "Install with: python -m pip install --upgrade codemunch-pro" }
        LatencyMs = $null
    })
    $codemunchRuntimeStatus = "FAIL"
    if ($codemunchOk) { $codemunchRuntimeStatus = "OK" }
    & $OnCheckComplete $currentCheck $totalChecks "codemunch_runtime" $codemunchRuntimeStatus $checks[-1].Detail
    
    # Check 4: CodeMunch version
    $currentCheck++
    & $OnCheckComplete $currentCheck $totalChecks "codemunch_version" "PENDING" "Checking..."
    $codemunchVersion = if ($codemunchImport) { Get-PythonPackageVersion -ImportName "codemunch_pro" } else { $null }
    $minCodemunch = "1.0.0"
    $codemunchVersionOk = Test-VersionMeetsMinimum -Version $codemunchVersion -Minimum $minCodemunch
    if ($codemunchVersion) {
        $checks.Add([pscustomobject]@{ Name = "codemunch_version"; Ok = $codemunchVersionOk; Detail = if ($codemunchVersionOk) { $codemunchVersion } else { "Found $codemunchVersion, need >= $minCodemunch" }; LatencyMs = $null })
    } else {
        $checks.Add([pscustomobject]@{ Name = "codemunch_version"; Ok = $false; Detail = "Not installed"; LatencyMs = $null })
    }
    $codemunchVersionStatus = "FAIL"
    if ($codemunchVersionOk) {
        $codemunchVersionStatus = "OK"
    } elseif ($codemunchVersion) {
        $codemunchVersionStatus = "WARN"
    }
    & $OnCheckComplete $currentCheck $totalChecks "codemunch_version" $codemunchVersionStatus $checks[-1].Detail
    
    # Check 5: ChromaDB module
    $currentCheck++
    & $OnCheckComplete $currentCheck $totalChecks "chromadb_module" "PENDING" "Checking..."
    $chromadbImport = if ($pythonCmd) { Test-PythonImport -ImportName "chromadb" } else { $false }
    $checks.Add([pscustomobject]@{ Name = "chromadb_module"; Ok = $chromadbImport; Detail = if ($chromadbImport) { "chromadb import ok" } else { "Install with: python -m pip install --upgrade chromadb" }; LatencyMs = $null })
    $chromadbModuleStatus = "FAIL"
    if ($chromadbImport) { $chromadbModuleStatus = "OK" }
    & $OnCheckComplete $currentCheck $totalChecks "chromadb_module" $chromadbModuleStatus $checks[-1].Detail
    
    # Check 6: ChromaDB version
    $currentCheck++
    & $OnCheckComplete $currentCheck $totalChecks "chromadb_version" "PENDING" "Checking..."
    $chromadbVersion = if ($chromadbImport) { Get-PythonPackageVersion -ImportName "chromadb" } else { $null }
    $minChromadb = "0.5.0"
    $chromadbVersionOk = Test-VersionMeetsMinimum -Version $chromadbVersion -Minimum $minChromadb
    if ($chromadbVersion) {
        $checks.Add([pscustomobject]@{ Name = "chromadb_version"; Ok = $chromadbVersionOk; Detail = if ($chromadbVersionOk) { $chromadbVersion } else { "Found $chromadbVersion, need >= $minChromadb" }; LatencyMs = $null })
    } else {
        $checks.Add([pscustomobject]@{ Name = "chromadb_version"; Ok = $false; Detail = "Not installed"; LatencyMs = $null })
    }
    $chromadbVersionStatus = "FAIL"
    if ($chromadbVersionOk) {
        $chromadbVersionStatus = "OK"
    } elseif ($chromadbVersion) {
        $chromadbVersionStatus = "WARN"
    }
    & $OnCheckComplete $currentCheck $totalChecks "chromadb_version" $chromadbVersionStatus $checks[-1].Detail
    
    # Check 7: Provider credentials
    $currentCheck++
    & $OnCheckComplete $currentCheck $totalChecks "provider_credentials" "PENDING" "Checking..."
    $providerResolved = Resolve-ProviderProfile -RequestedProvider $Provider
    if ($null -eq $providerResolved) {
        $checks.Add([pscustomobject]@{ Name = "provider_credentials"; Ok = $false; Detail = "No provider key found. Set OPENAI_API_KEY, KIMI_API_KEY, GEMINI_API_KEY, or GLM_API_KEY in .env"; LatencyMs = $null })
    } else {
        $baseSource = if ([string]::IsNullOrWhiteSpace($providerResolved.BaseUrlVar)) { "default" } else { $providerResolved.BaseUrlVar }
        $checks.Add([pscustomobject]@{ Name = "provider_credentials"; Ok = $providerResolved.ApiKeySet; Detail = "provider=$($providerResolved.Profile.Name), apiKeyVar=$($providerResolved.ApiKeyVar), baseUrlSource=$baseSource"; LatencyMs = $null })
    }
    $providerCredentialsStatus = "FAIL"
    if ($providerResolved -and $providerResolved.ApiKeySet) { $providerCredentialsStatus = "OK" }
    & $OnCheckComplete $currentCheck $totalChecks "provider_credentials" $providerCredentialsStatus $checks[-1].Detail
    
    # Check 8: ContextLattice env
    $currentCheck++
    & $OnCheckComplete $currentCheck $totalChecks "contextlattice_env" "PENDING" "Checking..."
    $ctxUrl = $env:CONTEXTLATTICE_ORCHESTRATOR_URL
    $ctxKey = if ($script:DashboardEnvSecrets.ContainsKey('CONTEXTLATTICE_ORCHESTRATOR_API_KEY')) { $script:DashboardEnvSecrets['CONTEXTLATTICE_ORCHESTRATOR_API_KEY'] } else { $null }
    $ctxKeySet = -not [string]::IsNullOrWhiteSpace($ctxKey)
    $ctxEnvOk = (-not [string]::IsNullOrWhiteSpace($ctxUrl)) -and $ctxKeySet
    $checks.Add([pscustomobject]@{ Name = "contextlattice_env"; Ok = $ctxEnvOk; Detail = if ($ctxEnvOk) { "url=$ctxUrl, apiKey=present" } else { "Need CONTEXTLATTICE_ORCHESTRATOR_URL and CONTEXTLATTICE_ORCHESTRATOR_API_KEY" }; LatencyMs = $null })
    $contextEnvStatus = "WARN"
    if ($ctxEnvOk) { $contextEnvStatus = "OK" }
    & $OnCheckComplete $currentCheck $totalChecks "contextlattice_env" $contextEnvStatus $checks[-1].Detail
    
    # Check 9: Provider key validation
    $currentCheck++
    & $OnCheckComplete $currentCheck $totalChecks "provider_key_valid" "PENDING" "Checking..."
    $keyValid = $false
    $keyLatency = 0
    if ($null -ne $providerResolved -and $providerResolved.ApiKeySet) {
        $apiKeyObj = Get-FirstEnvValue -Names $providerResolved.Profile.ApiKeyVars
        $apiKey = $apiKeyObj.Value
        $keyStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $keyValid = Test-ProviderKey -ProviderName $providerResolved.Profile.Name -ApiKey $apiKey -BaseUrl $providerResolved.BaseUrl -TimeoutSec $TimeoutSec
        $keyStopwatch.Stop()
        $keyLatency = $keyStopwatch.ElapsedMilliseconds
    }
    $providerNameForDetail = if ($providerResolved) { $providerResolved.Profile.Name } else { "unknown" }
    $checks.Add([pscustomobject]@{ Name = "provider_key_valid"; Ok = $keyValid; Detail = if ($keyValid) { "Key validated for $providerNameForDetail" } else { "Key validation failed for $providerNameForDetail" }; LatencyMs = $keyLatency })
    $providerKeyStatus = "FAIL"
    if ($keyValid) { $providerKeyStatus = "OK" }
    & $OnCheckComplete $currentCheck $totalChecks "provider_key_valid" $providerKeyStatus $checks[-1].Detail $keyLatency
    
    # Context checks
    if ($CheckContext) {
        if ((-not [string]::IsNullOrWhiteSpace($ctxUrl)) -and $ctxKeySet) {
            $base = $ctxUrl.TrimEnd('/')
            
            # Check 10: ContextLattice health
            $currentCheck++
            & $OnCheckComplete $currentCheck $totalChecks "contextlattice_health" "PENDING" "Checking..."
            $healthStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $healthOk = $false
            $healthDetail = ""
            try {
                $health = Invoke-RestMethod -Method Get -Uri "$base/health" -TimeoutSec $TimeoutSec
                $healthStopwatch.Stop()
                $healthOk = ($health.ok -eq $true)
                $healthDetail = "$($ctxUrl)/health ok=$($health.ok)"
            } catch {
                $healthStopwatch.Stop()
                $healthOk = $false
                $healthDetail = $_.Exception.Message
            }
            $healthLatency = $healthStopwatch.ElapsedMilliseconds
            $checks.Add([pscustomobject]@{ Name = "contextlattice_health"; Ok = $healthOk; Detail = $healthDetail; LatencyMs = $healthLatency })
            $contextHealthStatus = "FAIL"
            if ($healthOk) { $contextHealthStatus = "OK" }
            & $OnCheckComplete $currentCheck $totalChecks "contextlattice_health" $contextHealthStatus $healthDetail $healthLatency
            
            # Check 11: ContextLattice status
            $currentCheck++
            & $OnCheckComplete $currentCheck $totalChecks "contextlattice_status" "PENDING" "Checking..."
            $statusStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $statusOk = $false
            $statusDetail = ""
            try {
                $ctxApiKey = if ($script:DashboardEnvSecrets.ContainsKey('CONTEXTLATTICE_ORCHESTRATOR_API_KEY')) { $script:DashboardEnvSecrets['CONTEXTLATTICE_ORCHESTRATOR_API_KEY'] } else { $null }
                $headers = @{ "x-api-key" = $ctxApiKey }
                $status = Invoke-RestMethod -Method Get -Uri "$base/status" -Headers $headers -TimeoutSec $TimeoutSec
                $statusStopwatch.Stop()
                $statusOk = $true
                $statusDetail = "service=contextlattice"
            } catch {
                $statusStopwatch.Stop()
                $statusOk = $false
                $statusDetail = $_.Exception.Message
            }
            $statusLatency = $statusStopwatch.ElapsedMilliseconds
            $checks.Add([pscustomobject]@{ Name = "contextlattice_status"; Ok = $statusOk; Detail = $statusDetail; LatencyMs = $statusLatency })
            $contextStatusStatus = "FAIL"
            if ($statusOk) { $contextStatusStatus = "OK" }
            & $OnCheckComplete $currentCheck $totalChecks "contextlattice_status" $contextStatusStatus $statusDetail $statusLatency
        } else {
            $currentCheck++
            & $OnCheckComplete $currentCheck $totalChecks "contextlattice_health" "WARN" "Missing context env vars; cannot run connectivity test."
            $checks.Add([pscustomobject]@{ Name = "contextlattice_health"; Ok = $false; Detail = "Missing context env vars; cannot run connectivity test."; LatencyMs = $null })
            
            $currentCheck++
            & $OnCheckComplete $currentCheck $totalChecks "contextlattice_status" "WARN" "Missing context env vars; cannot run connectivity test."
            $checks.Add([pscustomobject]@{ Name = "contextlattice_status"; Ok = $false; Detail = "Missing context env vars; cannot run connectivity test."; LatencyMs = $null })
        }
    }
    
    return @{
        Checks = $checks.ToArray()
        ProjectPath = $projectPath
        ProviderResolved = $providerResolved
    }
}

#endregion

#region Main Execution

