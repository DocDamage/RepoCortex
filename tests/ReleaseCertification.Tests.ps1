#requires -Version 5.1
<#
.SYNOPSIS
    Release certification tests for Repo Cortex (LLMWorkflow) v1.0 readiness.


.DESCRIPTION
    Pester v5 test suite that certifies release readiness by verifying the
    existence of required files, modules, scripts, and documentation.

    Tests are organized by the categories defined in
    docs/V1_RELEASE_CRITERIA.md and docs/RELEASE_CERTIFICATION_CHECKLIST.md.

.NOTES
    File: ReleaseCertification.Tests.ps1
    Version: 1.0.0
    Author: LLM Workflow Team
    Requires: Pester 5.0+
#>

BeforeAll {
    $script:ProjectRoot = Join-Path (Join-Path $PSScriptRoot "..") ""
    $script:ModuleRoot = Join-Path $script:ProjectRoot "module\LLMWorkflow"
    $script:DocsRoot = Join-Path $script:ProjectRoot "docs"
    $script:ScriptsRoot = Join-Path $script:ProjectRoot "scripts"
    $script:PolicyRoot = Join-Path $script:ProjectRoot "policy"
    $script:CiRoot = Join-Path $script:ProjectRoot "tools\ci"
    . (Join-Path $script:ScriptsRoot "Invoke-ReleaseCertification.ps1")
}

Describe "Documentation Truth" {
    It "VERSION file exists and is not empty" {
        $versionPath = Join-Path $script:ProjectRoot "VERSION"
        Test-Path -LiteralPath $versionPath | Should -Be $true
        $content = Get-Content -LiteralPath $versionPath -Raw
        $content | Should -Not -BeNullOrEmpty
        $content.Trim() | Should -Not -Be ''
    }

    It "RELEASE_STATE.md exists in releases subdirectory" {
        $path = Join-Path $script:DocsRoot "releases\RELEASE_STATE.md"
        Test-Path -LiteralPath $path | Should -Be $true
    }

    It "DOCS_TRUTH_MATRIX.md exists in reference subdirectory" {
        $path = Join-Path $script:DocsRoot "reference\DOCS_TRUTH_MATRIX.md"
        Test-Path -LiteralPath $path | Should -Be $true
    }

    It "All required documentation files exist in appropriate subdirectories" {
        # Maps doc files to their subdirectory under docs/
        $requiredDocMap = @{
            'V1_RELEASE_CRITERIA.md' = 'releases'
            'RELEASE_CERTIFICATION_CHECKLIST.md' = 'releases'
            'RELEASE_STATE.md' = 'releases'
            'DOCS_TRUTH_MATRIX.md' = 'reference'
            'DOCUMENT_INGESTION_MODEL.md' = 'architecture'
            'GAME_ASSET_INGESTION_MODEL.md' = 'architecture'
            'SECURITY_BASELINE.md' = 'architecture'
            'SUPPLY_CHAIN_POLICY.md' = 'reference'
            'POLICY_RUNTIME_MODEL.md' = 'architecture'
            'OBSERVABILITY_ARCHITECTURE.md' = 'architecture'
            'EVALUATION_OPERATIONS.md' = 'operations'
            'SELF_HEALING.md' = 'operations'
        }

        foreach ($entry in $requiredDocMap.GetEnumerator()) {
            $doc = $entry.Key
            $subdir = $entry.Value
            $path = Join-Path $script:DocsRoot ($subdir + '\' + $doc)
            Test-Path -LiteralPath $path | Should -Be $true -Because "'$doc' should exist in docs/$subdir/"
        }
    }
}

Describe "Branding" {
    It "README uses Repo Cortex as the product brand and displays the logo" {
        $readmePath = Join-Path $script:ProjectRoot "README.md"
        $readme = Get-Content -LiteralPath $readmePath -Raw

        $readme | Should -Match '(?m)^# .*\bRepo Cortex\b'
        $readme | Should -Match '<img\s+[^>]*src="repo_cortex_transparent_logo\.png"[^>]*alt="Repo Cortex logo"'
        $readme | Should -Match '\*\*Formerly:\*\* CodeMunch'
    }

    It "root logo asset exists and is a PNG" {
        $logoPath = Join-Path $script:ProjectRoot "repo_cortex_transparent_logo.png"
        Test-Path -LiteralPath $logoPath | Should -Be $true

        $logoBytes = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $logoPath).Path)
        $pngHeader = $logoBytes[0..7]
        $pngHeader | Should -Be @(0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A)
    }

    It "release certification includes the branding gate" {
        Test-BrandingAssets -ProjectRoot $script:ProjectRoot | Should -Be $true
    }

    It "dashboard UI uses the Repo Cortex brand shell" {
        $constantsPath = Join-Path $script:ModuleRoot "contexts\Telemetry\internal\_Constants.ps1"
        $htmlPath = Join-Path $script:ModuleRoot "contexts\Telemetry\internal\HtmlConverters.ps1"
        $constants = Get-Content -LiteralPath $constantsPath -Raw
        $html = Get-Content -LiteralPath $htmlPath -Raw

        $constants | Should -Match "\`$script:ProductBrandName\s*=\s*'Repo Cortex'"
        $html | Should -Match 'brand-header'
        $html | Should -Match 'brand-mark'
        $html | Should -Match 'ProductBrandName'
    }

    It "module and container metadata point at the RepoCortex GitHub repository" {
        $manifestPath = Join-Path $script:ModuleRoot "LLMWorkflow.psd1"
        $modulePath = Join-Path $script:ModuleRoot "LLMWorkflow.psm1"
        $dockerfilePath = Join-Path $script:ProjectRoot "Dockerfile"

        $manifest = Get-Content -LiteralPath $manifestPath -Raw
        $module = Get-Content -LiteralPath $modulePath -Raw
        $dockerfile = Get-Content -LiteralPath $dockerfilePath -Raw

        $manifest | Should -Match 'https://github\.com/DocDamage/RepoCortex'
        $module | Should -Match 'DocDamage/RepoCortex'
        $dockerfile | Should -Match 'https://github\.com/DocDamage/RepoCortex'
        $manifest | Should -Not -Match 'CodeMunch-ContextLattice-MemPalace---All-in-one'
        $module | Should -Not -Match 'CodeMunch-ContextLattice-MemPalace---All-in-one'
        $dockerfile | Should -Not -Match 'CodeMunch-ContextLattice-MemPalace---All-in-one'
    }

    It "documentation uses Repo Cortex as the current product name" {
        $docRoots = @(
            $script:DocsRoot,
            (Join-Path $script:ProjectRoot "tools"),
            (Join-Path $script:ModuleRoot "templates")
        )
        $docFiles = foreach ($root in $docRoots) {
            Get-ChildItem -LiteralPath $root -Recurse -File -Include *.md -ErrorAction SilentlyContinue
        }

        $disallowedProductPhrases = @(
            'LLM Workflow Toolkit',
            'LLM Workflow Platform',
            'LLM Workflow platform',
            'LLM Workflow system',
            'LLM Workflow runtime',
            'LLM Workflow Dashboard',
            'LLM Workflow Team',
            'LLMWorkflow platform',
            'LLMWorkflow canonical document set',
            'CodeMunch Pro',
            'CodeMunch-ContextLattice',
            'RepoCortext'
        )

        foreach ($file in $docFiles) {
            $content = Get-Content -LiteralPath $file.FullName -Raw
            foreach ($phrase in $disallowedProductPhrases) {
                $content | Should -Not -Match ([regex]::Escape($phrase)) -Because "$($file.FullName) should use Repo Cortex as the current product name"
            }
        }
    }
}

Describe "Failure Visibility" {
    It "release-critical files do not use unjustified SilentlyContinue" {
        Test-ReleaseCriticalFailureVisibility -ProjectRoot $script:ProjectRoot | Should -Be $true
    }
}

Describe "Observability" {
    It "SpanFactory.ps1 exists" {
        $path = Join-Path $script:ModuleRoot "telemetry\SpanFactory.ps1"
        Test-Path -LiteralPath $path | Should -Be $true
    }

    It "TraceEnvelope.ps1 exists" {
        $path = Join-Path $script:ModuleRoot "telemetry\TraceEnvelope.ps1"
        Test-Path -LiteralPath $path | Should -Be $true
    }

    It "OpenTelemetryBridge.ps1 exists" {
        $path = Join-Path $script:ModuleRoot "telemetry\OpenTelemetryBridge.ps1"
        Test-Path -LiteralPath $path | Should -Be $true
    }
}

Describe "Module Contracts" {
    It "documented palace commands are exported from the module" {
        $manifestPath = Join-Path $script:ModuleRoot "LLMWorkflow.psd1"
        Test-ModuleExportsCommands -ManifestPath $manifestPath -CommandNames @(
            'Get-LLMWorkflowPalaces',
            'Test-LLMWorkflowPalace',
            'Sync-LLMWorkflowPalace',
            'Sync-LLMWorkflowAllPalaces'
        ) | Should -Be $true
    }
}

Describe "Policy" {
    It "PolicyAdapter.ps1 exists" {
        $path = Join-Path $script:ModuleRoot "policy\PolicyAdapter.ps1"
        Test-Path -LiteralPath $path | Should -Be $true
    }

    It "At least one OPA rego file exists" {
        $opaPath = Join-Path $script:PolicyRoot "opa"
        if (Test-Path -LiteralPath $opaPath) {
            $regoFiles = Get-ChildItem -Path $opaPath -Filter "*.rego" -ErrorAction SilentlyContinue
            # Guard against PS 5.1 single-item array unwrapping
            $regoList = @($regoFiles)
            $regoList.Count | Should -BeGreaterThan 0
        }
        else {
            throw "OPA policy directory not found: $opaPath"
        }
    }
}

Describe "Document Ingestion" {
    It "DoclingAdapter.ps1 exists" {
        $path = Join-Path $script:ModuleRoot "ingestion\DoclingAdapter.ps1"
        Test-Path -LiteralPath $path | Should -Be $true
    }

    It "TikaAdapter.ps1 exists" {
        $path = Join-Path $script:ModuleRoot "ingestion\TikaAdapter.ps1"
        Test-Path -LiteralPath $path | Should -Be $true
    }

    It "DocumentNormalizer.ps1 exists" {
        $path = Join-Path $script:ModuleRoot "ingestion\DocumentNormalizer.ps1"
        Test-Path -LiteralPath $path | Should -Be $true
    }
}

Describe "Game Asset Ingestion" {
    It "MarketplaceProvenanceNormalizer.ps1 exists" {
        $path = Join-Path $script:ModuleRoot "ingestion\MarketplaceProvenanceNormalizer.ps1"
        Test-Path -LiteralPath $path | Should -Be $true
    }
}

Describe "Security Baseline" {
    It "Invoke-SecurityBaseline.ps1 exists" {
        $path = Join-Path $script:ScriptsRoot "security\Invoke-SecurityBaseline.ps1"
        Test-Path -LiteralPath $path | Should -Be $true
    }

    It "Invoke-SBOMBuild.ps1 exists" {
        $path = Join-Path $script:ScriptsRoot "security\Invoke-SBOMBuild.ps1"
        Test-Path -LiteralPath $path | Should -Be $true
    }

    It "Invoke-SecretScan.ps1 exists" {
        $path = Join-Path $script:ScriptsRoot "security\Invoke-SecretScan.ps1"
        Test-Path -LiteralPath $path | Should -Be $true
    }

    It "Invoke-VulnerabilityScan.ps1 exists" {
        $path = Join-Path $script:ScriptsRoot "security\Invoke-VulnerabilityScan.ps1"
        Test-Path -LiteralPath $path | Should -Be $true
    }
}

Describe "Durable Execution" {
    It "DurableOrchestrator.ps1 exists" {
        $path = Join-Path $script:ModuleRoot "workflow\DurableOrchestrator.ps1"
        Test-Path -LiteralPath $path | Should -Be $true
    }
}

Describe "MCP Governance" {
    It "MCPToolRegistry.ps1 exists" {
        $path = Join-Path $script:ModuleRoot "mcp\MCPToolRegistry.ps1"
        Test-Path -LiteralPath $path | Should -Be $true
    }

    It "MCPToolLifecycle.ps1 exists" {
        $path = Join-Path $script:ModuleRoot "mcp\MCPToolLifecycle.ps1"
        Test-Path -LiteralPath $path | Should -Be $true
    }
}

Describe "Retrieval Backend" {
    It "RetrievalBackendAdapter.ps1 exists" {
        $path = Join-Path $script:ModuleRoot "retrieval\RetrievalBackendAdapter.ps1"
        Test-Path -LiteralPath $path | Should -Be $true
    }

    It "release certification treats the real retrieval backend implementation as ready" {
        $path = Join-Path $script:ModuleRoot "retrieval\RetrievalBackendAdapter.ps1"
        Test-RetrievalBackendImplementation -Path $path | Should -Be $true
    }
}

Describe "Container Runtime" {
    It "docker-compose does not rely on a nonexistent implicit contextlattice service default" {
        $composePath = Join-Path $script:ProjectRoot "docker-compose.yml"
        Test-ComposeContextLatticeConfiguration -ComposePath $composePath | Should -Be $true
    }
}

Describe "CI Validation" {
    It "CI validation script exists" {
        $path = Join-Path $script:CiRoot "validate-docs-truth.ps1"
        Test-Path -LiteralPath $path | Should -Be $true
    }
}
