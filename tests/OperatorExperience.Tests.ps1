#requires -Version 5.1
<#
.SYNOPSIS
    Tests the post-v1 Repo Cortex operator experience commands.
#>

Set-StrictMode -Version Latest

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:ManifestPath = Join-Path $script:RepoRoot 'module\LLMWorkflow\LLMWorkflow.psd1'
    Import-Module $script:ManifestPath -Force -ErrorAction Stop
}

Describe 'Operator next-action command' {
    It 'ranks failed release certification as the next action' {
        $projectRoot = Join-Path $TestDrive 'next-action'
        New-Item -ItemType Directory -Path $projectRoot -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $projectRoot 'VERSION') -Value '1.0.0' -Encoding UTF8
        $reportDir = Join-Path $projectRoot 'certification-reports'
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
        @{
            OverallStatus = 'FAIL'
            CategoryResults = @(
                @{ Category = 'Policy'; Status = 'FAIL' }
            )
        } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $reportDir 'certification-report-2026-05-05T00-00-00Z.json') -Encoding UTF8

        $result = Get-LLMWorkflowNextAction -ProjectRoot $projectRoot

        $result.ActionId | Should -Be 'fix-release-certification'
        $result.Priority | Should -Be 1
        $result.Evidence | Should -Match 'Policy'
    }

    It 'understands strict certification reports that use OverallPassed and Categories' {
        $projectRoot = Join-Path $TestDrive 'next-action-strict'
        New-Item -ItemType Directory -Path $projectRoot -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $projectRoot 'VERSION') -Value '1.0.0' -Encoding UTF8
        $reportDir = Join-Path $projectRoot 'certification-reports'
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
        @{
            OverallPassed = $false
            Categories = @{
                DocumentationTruth = $true
                Security = $false
            }
        } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $reportDir 'certification-report-2026-05-05T01-00-00Z.json') -Encoding UTF8

        $result = Get-LLMWorkflowNextAction -ProjectRoot $projectRoot

        $result.ActionId | Should -Be 'fix-release-certification'
        $result.Evidence | Should -Match 'Security'
    }
}

Describe 'Evidence explorer report' {
    It 'exports normalized answer evidence to JSON and HTML' {
        $projectRoot = Join-Path $TestDrive 'evidence'
        New-Item -ItemType Directory -Path $projectRoot -Force | Out-Null
        $jsonPath = Join-Path $projectRoot 'answer-evidence.json'
        $htmlPath = Join-Path $projectRoot 'answer-evidence.html'
        $trace = [pscustomobject]@{
            query = 'Which pack answered this?'
            route = [pscustomobject]@{ selectedPack = 'godot-engine'; reason = 'engine query' }
            evidence = @(
                [pscustomobject]@{ sourcePath = 'docs/godot.md'; confidence = 0.91; excerpt = 'Signals connect gameplay systems.' }
            )
            confidence = 0.84
            caveats = @('One source only')
            policy = [pscustomobject]@{ decision = 'allow'; explanation = 'Public docs evidence' }
        }

        $result = Export-LLMWorkflowEvidenceReport -AnswerTrace $trace -ExportPath $jsonPath -HtmlPath $htmlPath
        $saved = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
        $html = Get-Content -LiteralPath $htmlPath -Raw

        $result.EvidenceCount | Should -Be 1
        $saved.route.selectedPack | Should -Be 'godot-engine'
        $saved.policy.decision | Should -Be 'allow'
        $html | Should -Match 'Answer Evidence Explorer'
    }
}

Describe 'Pack authoring scaffold' {
    It 'creates manifest, registry, and golden task stub files' {
        $projectRoot = Join-Path $TestDrive 'pack-scaffold'
        New-Item -ItemType Directory -Path $projectRoot -Force | Out-Null

        $result = New-LLMWorkflowPackScaffold -ProjectRoot $projectRoot -PackId 'demo-pack' -DisplayName 'Demo Pack' -Description 'A demo extension pack'

        $manifestPath = Join-Path $projectRoot 'packs\manifests\demo-pack.json'
        $registryPath = Join-Path $projectRoot 'packs\registries\demo-pack.sources.json'
        $goldenPath = Join-Path $projectRoot 'tests\golden\DemoPackGoldenTasks.ps1'

        $result.CreatedFiles | Should -Contain $manifestPath
        Test-Path -LiteralPath $manifestPath | Should -Be $true
        Test-Path -LiteralPath $registryPath | Should -Be $true
        Test-Path -LiteralPath $goldenPath | Should -Be $true
        (Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json).id | Should -Be 'demo-pack'
    }
}

Describe 'Corpus regression harness' {
    It 'summarizes corpus cases and writes a regression report' {
        $projectRoot = Join-Path $TestDrive 'corpus'
        $caseRoot = Join-Path $projectRoot 'corpus'
        New-Item -ItemType Directory -Path $caseRoot -Force | Out-Null
        @{
            id = 'case-1'
            packId = 'godot-engine'
            query = 'How do signals work?'
            expectedEvidence = @('signals')
            actualEvidence = @('signals', 'nodes')
        } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $caseRoot 'case-1.case.json') -Encoding UTF8
        $reportPath = Join-Path $projectRoot 'corpus-report.json'

        $result = Invoke-LLMWorkflowCorpusRegression -CorpusRoot $caseRoot -ReportPath $reportPath

        $result.TotalCases | Should -Be 1
        $result.Passed | Should -Be 1
        Test-Path -LiteralPath $reportPath | Should -Be $true
    }
}

Describe 'Security exception ledger' {
    It 'flags expired exceptions' {
        $projectRoot = Join-Path $TestDrive 'security-exceptions'
        $ledgerDir = Join-Path $projectRoot '.llm-workflow'
        New-Item -ItemType Directory -Path $ledgerDir -Force | Out-Null
        @{
            schemaVersion = 1
            exceptions = @(
                @{
                    id = 'SEC-001'
                    owner = 'Security Owner'
                    reason = 'Fixture scanner finding'
                    expiresOn = '2000-01-01'
                    scanner = 'fixture'
                    fingerprint = 'abc123'
                }
            )
        } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $ledgerDir 'security-exceptions.json') -Encoding UTF8

        $result = Test-LLMWorkflowSecurityExceptions -ProjectRoot $projectRoot

        $result.HasExpired | Should -Be $true
        $result.ExpiredCount | Should -Be 1
        $result.Exceptions[0].Status | Should -Be 'Expired'
    }
}

Describe 'Local web cockpit' {
    It 'exports an HTML cockpit with release evidence and next action' {
        $projectRoot = Join-Path $TestDrive 'cockpit'
        New-Item -ItemType Directory -Path $projectRoot -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $projectRoot 'VERSION') -Value '1.0.0' -Encoding UTF8
        $reportDir = Join-Path $projectRoot 'certification-reports'
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
        @{ OverallStatus = 'PASS'; CategoryResults = @() } |
            ConvertTo-Json -Depth 5 |
            Set-Content -LiteralPath (Join-Path $reportDir 'certification-report-2026-05-05T00-00-00Z.json') -Encoding UTF8
        $outputPath = Join-Path $projectRoot 'cockpit.html'

        $result = Export-LLMWorkflowCockpit -ProjectRoot $projectRoot -ExportPath $outputPath
        $html = Get-Content -LiteralPath $outputPath -Raw

        $result.ExportPath | Should -Be $outputPath
        $html | Should -Match 'Repo Cortex Cockpit'
        $html | Should -Match 'Next Action'
        $html | Should -Match 'Release Evidence'
    }

    It 'uses ModernUI assets when the project includes the asset folder' {
        $projectRoot = Join-Path $TestDrive 'modern-ui-cockpit'
        New-Item -ItemType Directory -Path $projectRoot -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $projectRoot 'VERSION') -Value '1.0.0' -Encoding UTF8
        $assetDir = Join-Path $projectRoot 'ModernUI\16x16'
        New-Item -ItemType Directory -Path $assetDir -Force | Out-Null
        $pngBytes = [Convert]::FromBase64String('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=')
        [IO.File]::WriteAllBytes((Join-Path $assetDir 'Modern_UI_Gamepad.png'), $pngBytes)
        [IO.File]::WriteAllBytes((Join-Path $assetDir 'Modern_UI_Style_1.png'), $pngBytes)
        $outputPath = Join-Path $projectRoot 'cockpit.html'

        Export-LLMWorkflowCockpit -ProjectRoot $projectRoot -ExportPath $outputPath
        $html = Get-Content -LiteralPath $outputPath -Raw

        $html | Should -Match 'data-modern-ui="true"'
        $html | Should -Match 'data:image/png;base64,'
        $html | Should -Match 'ModernUI'
    }
}

Describe 'Project migration assistant' {
    It 'reports migration actions in plan mode without mutating files' {
        $projectRoot = Join-Path $TestDrive 'migration'
        New-Item -ItemType Directory -Path $projectRoot -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $projectRoot '.codemunch') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $projectRoot 'README.md') -Value '# CodeMunch-ContextLattice-MemPalace---All-in-one' -Encoding UTF8

        $result = Update-LLMWorkflowProject -ProjectRoot $projectRoot -Plan
        $readme = Get-Content -LiteralPath (Join-Path $projectRoot 'README.md') -Raw

        $result.Mode | Should -Be 'Plan'
        $result.Actions.Count | Should -BeGreaterThan 0
        $readme | Should -Match 'CodeMunch-ContextLattice'
    }
}
