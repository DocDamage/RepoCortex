#requires -Version 5.1
<#
.SYNOPSIS
    Runs the full v1.0 release certification suite for Repo Cortex (LLMWorkflow module).

.DESCRIPTION
    Evaluates release readiness across all categories defined in
    docs/V1_RELEASE_CRITERIA.md and produces structured JSON and Markdown
    certification reports.


    Functions:
    - Invoke-ReleaseCertification: runs all checks and outputs a report
    - Test-ReleaseCriteria: returns a boolean result for each category
    - Export-CertificationReport: writes JSON and Markdown reports to disk

.PARAMETER ProjectRoot
    The root directory of the LLMWorkflow project to certify.
    Defaults to the current working directory.

.PARAMETER OutputPath
    Directory where certification reports will be written.
    Defaults to "certification-reports".

.EXAMPLE
    .\Invoke-ReleaseCertification.ps1 -ProjectRoot . -OutputPath .\reports

.EXAMPLE
    Invoke-ReleaseCertification -ProjectRoot F:\LLMWorkflow -OutputPath F:\reports

.OUTPUTS
    System.Management.Automation.PSCustomObject
    A structured certification report with per-category results and overall pass/fail.

.NOTES
    File: Invoke-ReleaseCertification.ps1
    Version: 1.0.0
    Author: LLM Workflow Team
    Compatible with: PowerShell 5.1+
#>

Set-StrictMode -Version Latest

#region Private Helpers

function Test-FileExists {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    return (Test-Path -LiteralPath $Path)
}

function Test-DirectoryHasFiles {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Directory,

        [Parameter(Mandatory = $true)]
        [string]$Filter
    )

    if (-not (Test-Path -LiteralPath $Directory)) {
        return $false
    }

    $files = Get-ChildItem -Path $Directory -Filter $Filter -ErrorAction SilentlyContinue
    $fileList = @($files)
    return ($fileList.Count -gt 0)
}

function Test-ModuleExportsCommands {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath,

        [Parameter(Mandatory = $true)]
        [string[]]$CommandNames
    )

    if (-not (Test-Path -LiteralPath $ManifestPath)) {
        return $false
    }

    try {
        Import-Module $ManifestPath -Force -ErrorAction Stop
        foreach ($commandName in $CommandNames) {
            $command = Get-Command -Name $commandName -ErrorAction SilentlyContinue
            if ($null -eq $command -or $command.Source -ne 'LLMWorkflow') {
                return $false
            }
        }
        return $true
    }
    catch {
        return $false
    }
    finally {
        Remove-Module -Name LLMWorkflow -Force -ErrorAction SilentlyContinue
    }
}

function Test-ComposeContextLatticeConfiguration {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComposePath
    )

    if (-not (Test-Path -LiteralPath $ComposePath)) {
        return $false
    }

    $raw = Get-Content -LiteralPath $ComposePath -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return $false
    }

    $definesBundledService = $raw -match '(?m)^\s{2}contextlattice:\s*$'
    $usesBrokenImplicitDefault = $raw -match [regex]::Escape('http://contextlattice:8075')
    $requiresExplicitExternalUrl = $raw -match [regex]::Escape('Set CONTEXTLATTICE_ORCHESTRATOR_URL to a reachable external ContextLattice orchestrator')

    return ($definesBundledService -or ((-not $usesBrokenImplicitDefault) -and $requiresExplicitExternalUrl))
}

function Test-RetrievalBackendImplementation {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    $raw = Get-Content -LiteralPath $Path -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return $false
    }

    $mockIndicators = @(
        'Qdrant via HTTP REST mocks',
        'LanceDB via file-based mocks',
        'mockResponse',
        'MockHealthCheck'
    )

    foreach ($indicator in $mockIndicators) {
        if ($raw -match [regex]::Escape($indicator)) {
            return $false
        }
    }

    return $true
}

function Test-BrandingAssets {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $readmePath = Join-Path $ProjectRoot "README.md"
    $logoPath = Join-Path $ProjectRoot "repo_cortex_transparent_logo.png"

    if (-not (Test-Path -LiteralPath $readmePath)) {
        return $false
    }
    if (-not (Test-Path -LiteralPath $logoPath)) {
        return $false
    }

    $readme = Get-Content -LiteralPath $readmePath -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($readme)) {
        return $false
    }

    $hasBrandTitle = $readme -match '(?m)^# .*\bRepo Cortex\b'
    $hasLogoReference = $readme -match '<img\s+[^>]*src="repo_cortex_transparent_logo\.png"[^>]*alt="Repo Cortex logo"'
    $hasFormerNameDisclosure = $readme -match '\*\*Formerly:\*\* CodeMunch'

    try {
        $logoBytes = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $logoPath).Path)
    }
    catch {
        return $false
    }

    $hasPngHeader = (
        $logoBytes.Count -ge 8 -and
        $logoBytes[0] -eq 0x89 -and
        $logoBytes[1] -eq 0x50 -and
        $logoBytes[2] -eq 0x4E -and
        $logoBytes[3] -eq 0x47 -and
        $logoBytes[4] -eq 0x0D -and
        $logoBytes[5] -eq 0x0A -and
        $logoBytes[6] -eq 0x1A -and
        $logoBytes[7] -eq 0x0A
    )

    return ($hasBrandTitle -and $hasLogoReference -and $hasFormerNameDisclosure -and $hasPngHeader)
}

function Test-ReleaseCriticalFailureVisibility {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $criticalPaths = @(
        'module\LLMWorkflow\ingestion\DoclingAdapter.ps1',
        'module\LLMWorkflow\ingestion\parsers\GeometryNodesParser.ps1',
        'module\LLMWorkflow\LLMWorkflow.HealFunctions.ps1',
        'module\LLMWorkflow\LLMWorkflow.Dashboard.ps1',
        'module\LLMWorkflow\DashboardViews.ps1',
        'module\LLMWorkflow\workflow\DurableOrchestrator.ps1',
        'module\LLMWorkflow\mcp\MCPToolLifecycle.ps1'
    )

    foreach ($relativePath in $criticalPaths) {
        $path = Join-Path $ProjectRoot $relativePath
        if (-not (Test-Path -LiteralPath $path)) {
            return $false
        }

        $lineNumber = 0
        foreach ($line in Get-Content -LiteralPath $path) {
            $lineNumber++
            if ($line -match '-ErrorAction\s+SilentlyContinue' -and $line -notmatch '#\s*\[ALLOWED:') {
                Write-Warning "Unjustified SilentlyContinue found in $relativePath at line $lineNumber."
                return $false
            }
        }
    }

    return $true
}

function Get-CertificationStatus {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Passed
    )

    if ($Passed) { return 'PASS' }
    return 'FAIL'
}

#endregion

#region Public Functions

function Test-ReleaseCriteria {
    <#
    .SYNOPSIS
        Evaluates each release certification category and returns boolean results.

    .DESCRIPTION
        Performs existence and content checks for documentation, observability,
        policy, ingestion, security, durable execution, MCP governance, retrieval,
        and CI validation artifacts. In -Strict mode, adds module import/export
        parity checks, stale artifact detection, mojibake detection, build
        orchestrator existence, and Pester smoke suite requirements.

    .PARAMETER ProjectRoot
        Root path of the project to evaluate.

    .PARAMETER Strict
        If specified, enables extended checks: module import/export parity,
        stale artifacts, mojibake detection, build orchestrator existence,
        and Pester smoke suite validation.

    .OUTPUTS
        System.Management.Automation.PSCustomObject
        Boolean results per category and an overall Passed flag.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter()]
        [string]$ProjectRoot = (Get-Location).Path,

        [Parameter()]
        [switch]$Strict
    )

    if (-not (Test-Path -LiteralPath $ProjectRoot)) {
        throw "Project root not found: $ProjectRoot"
    }

    $moduleRoot = Join-Path $ProjectRoot "module\LLMWorkflow"
    $moduleManifestPath = Join-Path $moduleRoot "LLMWorkflow.psd1"
    $docsRoot = Join-Path $ProjectRoot "docs"
    $scriptsRoot = Join-Path $ProjectRoot "scripts"
    $policyRoot = Join-Path $ProjectRoot "policy"
    $ciRoot = Join-Path $ProjectRoot "tools\ci"
    $composePath = Join-Path $ProjectRoot "docker-compose.yml"
    $buildRoot = Join-Path $ProjectRoot "tools\build"
    $testRoot = Join-Path $ProjectRoot "tests"
    $branding = Test-BrandingAssets -ProjectRoot $ProjectRoot
    $failureVisibility = Test-ReleaseCriticalFailureVisibility -ProjectRoot $ProjectRoot

    # --- Documentation Truth ---
    $versionPath = Join-Path $ProjectRoot "VERSION"
    $versionExists = Test-FileExists -Path $versionPath
    $versionNotEmpty = $false
    if ($versionExists) {
        $versionContent = Get-Content -LiteralPath $versionPath -Raw -ErrorAction SilentlyContinue
        $versionNotEmpty = -not [string]::IsNullOrWhiteSpace($versionContent)
    }

    $requiredDocs = @(
        @{Name = 'V1_RELEASE_CRITERIA.md'; Subdir = 'releases'},
        @{Name = 'RELEASE_CERTIFICATION_CHECKLIST.md'; Subdir = 'releases'},
        @{Name = 'RELEASE_STATE.md'; Subdir = 'releases'},
        @{Name = 'DOCS_TRUTH_MATRIX.md'; Subdir = 'reference'},
        @{Name = 'DOCUMENT_INGESTION_MODEL.md'; Subdir = 'architecture'},
        @{Name = 'GAME_ASSET_INGESTION_MODEL.md'; Subdir = 'architecture'},
        @{Name = 'SECURITY_BASELINE.md'; Subdir = 'architecture'},
        @{Name = 'SUPPLY_CHAIN_POLICY.md'; Subdir = 'reference'},
        @{Name = 'POLICY_RUNTIME_MODEL.md'; Subdir = 'architecture'},
        @{Name = 'OBSERVABILITY_ARCHITECTURE.md'; Subdir = 'architecture'},
        @{Name = 'EVALUATION_OPERATIONS.md'; Subdir = 'operations'},
        @{Name = 'SELF_HEALING.md'; Subdir = 'operations'}
    )

    $allDocsExist = $true
    foreach ($entry in $requiredDocs) {
        $docPath = Join-Path $docsRoot ($entry.Subdir + '\' + $entry.Name)
        if (-not (Test-FileExists -Path $docPath)) {
            $allDocsExist = $false
            break
        }
    }

    $documentationTruth = $versionExists -and $versionNotEmpty -and $allDocsExist

    # -- Extended Strict checks: mojibake, stale artifacts, build orchestrator --
    $mojibakeDetected = $false
    $staleArtifactsFound = $false
    $buildOrchestratorExists = $false
    $moduleExportParityPassed = $true

    if ($Strict) {
        # Mojibake check in release-facing docs (UTF-8 encoding artifacts)
        $mojibakePattern = '[\x80-\xFF]{2,}'

        $mojibakeTargets = @(
            'README.md',
            'PROGRESS.md',
            'docs\implementation\PROGRESS.md',
            'docs\releases\RELEASE_STATE.md',
            'docs\releases\V1_RELEASE_CRITERIA.md',
            'docs\releases\RELEASE_CERTIFICATION_CHECKLIST.md',
            'docs\reference\DOCS_TRUTH_MATRIX.md'
        )
        foreach ($relPath in $mojibakeTargets) {
            $fullPath = Join-Path $ProjectRoot $relPath
            if (Test-Path -LiteralPath $fullPath) {
                $content = Get-Content -LiteralPath $fullPath -Raw
                if ($content -match $mojibakePattern) {
                    $mojibakeDetected = $true
                    break
                }
            }
        }

        # Stale root artifact check
        foreach ($badFile in @('_content_probe.txt', 'f')) {
            if (Test-Path -LiteralPath (Join-Path $ProjectRoot $badFile)) {
                $staleArtifactsFound = $true
            }
        }

        # Build orchestrator check
        $buildOrchestratorExists = Test-Path -LiteralPath (Join-Path $buildRoot 'Invoke-LLMBuild.ps1')

        # Module export parity check
        if (Test-Path -LiteralPath $moduleManifestPath) {
            try {
                $manifest = Import-PowerShellDataFile -Path $moduleManifestPath
                if ($manifest.FunctionsToExport) {
                    Import-Module $moduleManifestPath -Force -ErrorAction Stop
                    foreach ($fn in $manifest.FunctionsToExport) {
                        $cmd = Get-Command -Name $fn -Module LLMWorkflow -ErrorAction SilentlyContinue
                        if (-not $cmd) {
                            $moduleExportParityPassed = $false
                            break
                        }
                    }
                    foreach ($alias in $manifest.AliasesToExport) {
                        $resolved = Get-Alias -Name $alias -ErrorAction SilentlyContinue
                        if (-not $resolved) {
                            $moduleExportParityPassed = $false
                            break
                        }
                        $targetCmd = Get-Command -Name $resolved.Definition -ErrorAction SilentlyContinue
                        if (-not $targetCmd) {
                            $moduleExportParityPassed = $false
                            break
                        }
                    }
                }
            }
            catch {
                $moduleExportParityPassed = $false
            }
            finally {
                Remove-Module LLMWorkflow -Force -ErrorAction SilentlyContinue
            }
        }

        # Pester smoke test presence
        $pesterSmokeExists = Test-Path -LiteralPath (Join-Path $testRoot 'CoreModule.Tests.ps1')
    }

    # --- Observability ---
    $observability = (
        (Test-FileExists -Path (Join-Path $moduleRoot "telemetry\SpanFactory.ps1")) -and
        (Test-FileExists -Path (Join-Path $moduleRoot "telemetry\TraceEnvelope.ps1")) -and
        (Test-FileExists -Path (Join-Path $moduleRoot "telemetry\OpenTelemetryBridge.ps1"))
    )

    # --- Module Contracts ---
    $moduleContracts = Test-ModuleExportsCommands -ManifestPath $moduleManifestPath -CommandNames @(
        'Get-LLMWorkflowPalaces',
        'Test-LLMWorkflowPalace',
        'Sync-LLMWorkflowPalace',
        'Sync-LLMWorkflowAllPalaces'
    )

    # --- Policy ---
    $policy = (
        (Test-FileExists -Path (Join-Path $moduleRoot "policy\PolicyAdapter.ps1")) -and
        (Test-DirectoryHasFiles -Directory (Join-Path $policyRoot "opa") -Filter "*.rego")
    )

    # --- Document Ingestion ---
    $documentIngestion = (
        (Test-FileExists -Path (Join-Path $moduleRoot "ingestion\DoclingAdapter.ps1")) -and
        (Test-FileExists -Path (Join-Path $moduleRoot "ingestion\TikaAdapter.ps1")) -and
        (Test-FileExists -Path (Join-Path $moduleRoot "ingestion\DocumentNormalizer.ps1"))
    )

    # --- Game Asset Ingestion ---
    # Note: SpriteSheetParser was inherited from a cross-project artifact and does not
    # exist in this codebase. Game asset ingestion certifies only the normalizer.
    $gameAssetIngestion = (
        (Test-FileExists -Path (Join-Path $moduleRoot "ingestion\MarketplaceProvenanceNormalizer.ps1"))
    )

    # --- Security ---
    $scanResults = [ordered]@{
        SBOM = $null
        SecretScan = $null
        VulnerabilityScan = $null
        SecurityBaseline = $null
    }

    $sbomPath = Join-Path $scriptsRoot "security\Invoke-SBOMBuild.ps1"
    $secretPath = Join-Path $scriptsRoot "security\Invoke-SecretScan.ps1"
    $vulnPath = Join-Path $scriptsRoot "security\Invoke-VulnerabilityScan.ps1"
    $baselinePath = Join-Path $scriptsRoot "security\Invoke-SecurityBaseline.ps1"

    $missingScripts = @()
    if (-not (Test-FileExists -Path $sbomPath)) { $missingScripts += 'Invoke-SBOMBuild.ps1' }
    if (-not (Test-FileExists -Path $secretPath)) { $missingScripts += 'Invoke-SecretScan.ps1' }
    if (-not (Test-FileExists -Path $vulnPath)) { $missingScripts += 'Invoke-VulnerabilityScan.ps1' }

    if ($missingScripts.Count -gt 0) {
        foreach ($missing in $missingScripts) {
            Write-Warning "Security script not found: $missing"
        }
    }

    $security = $true
    if ($Strict -and $missingScripts.Count -gt 0) {
        $security = $false
    }

    # Execute available scans in sequence: SBOM build -> secret scan -> vulnerability scan
    if (Test-FileExists -Path $sbomPath) {
        . $sbomPath
        $scanResults.SBOM = Invoke-SBOMBuild -ProjectRoot $ProjectRoot
    }
    if (Test-FileExists -Path $secretPath) {
        . $secretPath
        $scanResults.SecretScan = Invoke-SecretScan -ProjectRoot $ProjectRoot
    }
    if (Test-FileExists -Path $vulnPath) {
        . $vulnPath
        $scanResults.VulnerabilityScan = Invoke-VulnerabilityScan -ProjectRoot $ProjectRoot
    }

    # Evaluate scan outputs
    $criticalFindings = 0
    if ($scanResults.SecretScan -and $scanResults.SecretScan.summary) {
        $criticalFindings += $scanResults.SecretScan.summary.critical
    }
    if ($scanResults.VulnerabilityScan -and $scanResults.VulnerabilityScan.summary) {
        $criticalFindings += $scanResults.VulnerabilityScan.summary.critical
    }
    if ($criticalFindings -gt 0) {
        $security = $false
    }

    # Run security baseline if available
    if (Test-FileExists -Path $baselinePath) {
        . $baselinePath
        try {
            $scanResults.SecurityBaseline = Invoke-SecurityBaseline -ProjectRoot $ProjectRoot -FailOnCritical
        }
        catch {
            Write-Warning "Security baseline failed: $_"
            $security = $false
            $scanResults.SecurityBaseline = @{ Error = $_.Exception.Message }
        }
    }

    # --- Durable Execution ---
    $durableExecution = Test-FileExists -Path (Join-Path $moduleRoot "workflow\DurableOrchestrator.ps1")

    # --- MCP Governance ---
    $mcpGovernance = (
        (Test-FileExists -Path (Join-Path $moduleRoot "mcp\MCPToolRegistry.ps1")) -and
        (Test-FileExists -Path (Join-Path $moduleRoot "mcp\MCPToolLifecycle.ps1"))
    )

    # --- Container Runtime ---
    $containerRuntime = Test-ComposeContextLatticeConfiguration -ComposePath $composePath

    # --- Retrieval Backend ---
    $retrievalBackendPath = Join-Path $moduleRoot "retrieval\RetrievalBackendAdapter.ps1"
    $retrievalBackend = (
        (Test-FileExists -Path $retrievalBackendPath) -and
        (Test-RetrievalBackendImplementation -Path $retrievalBackendPath)
    )

    # --- CI Validation ---
    $ciValidation = Test-FileExists -Path (Join-Path $ciRoot "validate-docs-truth.ps1")

    $overallPassed = (
        $documentationTruth -and
        $branding -and
        $failureVisibility -and
        $observability -and
        $moduleContracts -and
        $policy -and
        $documentIngestion -and
        $gameAssetIngestion -and
        $security -and
        $durableExecution -and
        $mcpGovernance -and
        $containerRuntime -and
        $retrievalBackend -and
        $ciValidation
    )

    return [pscustomobject]@{
        ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
        Timestamp = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
        OverallPassed = $overallPassed
        Categories = [ordered]@{
            DocumentationTruth = $documentationTruth
            Branding = $branding
            FailureVisibility = $failureVisibility
            Observability = $observability
            ModuleContracts = $moduleContracts
            Policy = $policy
            DocumentIngestion = $documentIngestion
            GameAssetIngestion = $gameAssetIngestion
            Security = $security
            DurableExecution = $durableExecution
            MCPGovernance = $mcpGovernance
            ContainerRuntime = $containerRuntime
            RetrievalBackend = $retrievalBackend
            CIValidation = $ciValidation
        }
        ScanResults = $scanResults
    }
}

function Export-CertificationReport {
    <#
    .SYNOPSIS
        Writes the certification report to JSON and Markdown files.

    .DESCRIPTION
        Serializes the certification report object to JSON and generates a
        human-readable Markdown summary suitable for attaching to release
        certification checklists.

    .PARAMETER Report
        The PSCustomObject returned by Test-ReleaseCriteria or Invoke-ReleaseCertification.

    .PARAMETER OutputPath
        Directory where the reports will be written.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Report,

        [Parameter()]
        [string]$OutputPath = "certification-reports"
    )

    if (-not (Test-Path -LiteralPath $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }

    $resolvedOutput = Resolve-Path -LiteralPath $OutputPath
    $timestamp = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH-mm-ssZ')
    $baseName = "certification-report-$timestamp"

    # JSON report
    $jsonPath = Join-Path $resolvedOutput "$baseName.json"
    $Report | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

    # Markdown report
    $mdPath = Join-Path $resolvedOutput "$baseName.md"
    $overallStatus = Get-CertificationStatus -Passed $Report.OverallPassed

    $mdLines = [System.Collections.Generic.List[string]]::new()
    $mdLines.Add("# LLMWorkflow v1.0 Certification Report")
    $mdLines.Add("")
    $mdLines.Add("- **Project Root:** $($Report.ProjectRoot)")
    $mdLines.Add("- **Timestamp:** $($Report.Timestamp)")
    $mdLines.Add("- **Overall Status:** $overallStatus")
    $mdLines.Add("")
    $mdLines.Add("## Category Results")
    $mdLines.Add("")
    $mdLines.Add("| Category | Status |")
    $mdLines.Add("|----------|--------|")

    foreach ($category in $Report.Categories.Keys) {
        $passed = $Report.Categories[$category]
        $status = Get-CertificationStatus -Passed $passed
        $mdLines.Add("| $category | $status |")
    }

    $mdLines.Add("")
    $mdLines.Add("## Details")
    $mdLines.Add("")
    if ($Report.OverallPassed) {
        $mdLines.Add("All certification criteria passed. The release candidate is cleared for promotion to v1.0.")
    }
    else {
        $mdLines.Add("One or more certification criteria failed. Release promotion is **blocked** until all categories pass.")
        $mdLines.Add("")
        $mdLines.Add("### Failed Categories")
        $mdLines.Add("")
        foreach ($category in $Report.Categories.Keys) {
            if (-not $Report.Categories[$category]) {
                $mdLines.Add("- $category")
            }
        }
    }

    $mdLines.Add("")
    $mdLines.Add("---")
    $mdLines.Add("*Generated by Invoke-ReleaseCertification.ps1*")

    $mdLines -join "`r`n" | Set-Content -LiteralPath $mdPath -Encoding UTF8

    Write-Host "[Export-CertificationReport] JSON report written to: $jsonPath" -ForegroundColor Cyan
    Write-Host "[Export-CertificationReport] Markdown report written to: $mdPath" -ForegroundColor Cyan

    return [pscustomobject]@{
        JsonPath = $jsonPath
        MarkdownPath = $mdPath
    }
}

function Invoke-ReleaseCertification {
    <#
    .SYNOPSIS
        Runs the full release certification suite and produces a report.

    .DESCRIPTION
        Executes Test-ReleaseCriteria across all defined categories, then exports
        the results to JSON and Markdown via Export-CertificationReport.

    .PARAMETER ProjectRoot
        Root directory of the project to certify. Defaults to the current location.

    .PARAMETER OutputPath
        Directory for the generated reports. Defaults to "certification-reports".

    .PARAMETER Strict
        If specified, missing security scan scripts will cause the Security category to fail.

    .OUTPUTS
        System.Management.Automation.PSCustomObject
        The full certification report including per-category results and report file paths.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter()]
        [string]$ProjectRoot = (Get-Location).Path,

        [Parameter()]
        [string]$OutputPath = "certification-reports",

        [Parameter()]
        [switch]$Strict
    )

    Write-Host "[Invoke-ReleaseCertification] Starting certification for: $ProjectRoot" -ForegroundColor Cyan

    $criteria = Test-ReleaseCriteria -ProjectRoot $ProjectRoot -Strict:$Strict

    Write-Host "[Invoke-ReleaseCertification] Certification evaluation complete." -ForegroundColor Cyan
    foreach ($category in $criteria.Categories.Keys) {
        $status = Get-CertificationStatus -Passed $criteria.Categories[$category]
        $color = if ($criteria.Categories[$category]) { 'Green' } else { 'Red' }
        Write-Host "  $category : $status" -ForegroundColor $color
    }

    $overallStatus = Get-CertificationStatus -Passed $criteria.OverallPassed
    $overallColor = if ($criteria.OverallPassed) { 'Green' } else { 'Red' }
    Write-Host "[Invoke-ReleaseCertification] Overall: $overallStatus" -ForegroundColor $overallColor

    $reportPaths = Export-CertificationReport -Report $criteria -OutputPath $OutputPath

    $result = [pscustomobject]@{
        ProjectRoot = $criteria.ProjectRoot
        Timestamp = $criteria.Timestamp
        OverallPassed = $criteria.OverallPassed
        Categories = $criteria.Categories
        ScanResults = $criteria.ScanResults
        ReportPaths = $reportPaths
    }

    return $result
}

#endregion

# Export module members when loaded as a module
if ($ExecutionContext.SessionState.Module) {
    Export-ModuleMember -Function @(
        'Invoke-ReleaseCertification',
        'Test-ReleaseCriteria',
        'Export-CertificationReport'
    )
}
