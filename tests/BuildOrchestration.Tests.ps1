#requires -Version 5.1
<#
.SYNOPSIS
    Verifies that expected build scripts and CI infrastructure exist.
.DESCRIPTION
    Validates that the build orchestrator, CI validators, and other
    release-critical tooling are present before attempting to run them.
#>

Set-StrictMode -Version Latest

BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}

Describe 'Build orchestrator' {
    It 'Invoke-LLMBuild.ps1 exists in tools/build/' {
        $path = Join-Path $repoRoot 'tools\build\Invoke-LLMBuild.ps1'
        Test-Path -LiteralPath $path | Should -Be $true
    }

    It 'PSScriptAnalyzer rules directory exists' {
        $path = Join-Path $repoRoot 'tools\build\PSScriptAnalyzer'
        Test-Path -LiteralPath $path | Should -Be $true
    }
}

Describe 'CI validators' {
    It 'invoke-pester-safe.ps1 exists' {
        $path = Join-Path $repoRoot 'tools\ci\invoke-pester-safe.ps1'
        Test-Path -LiteralPath $path | Should -Be $true
    }

    It 'validate-docs-truth.ps1 exists' {
        $path = Join-Path $repoRoot 'tools\ci\validate-docs-truth.ps1'
        Test-Path -LiteralPath $path | Should -Be $true
    }

    It 'check-template-drift.ps1 exists' {
        $path = Join-Path $repoRoot 'tools\ci\check-template-drift.ps1'
        Test-Path -LiteralPath $path | Should -Be $true
    }

    It 'validate-compatibility-lock.ps1 exists' {
        $path = Join-Path $repoRoot 'tools\ci\validate-compatibility-lock.ps1'
        Test-Path -LiteralPath $path | Should -Be $true
    }
}

Describe 'Security scripts' {
    It 'Invoke-SBOMBuild.ps1 exists' {
        $path = Join-Path $repoRoot 'scripts\security\Invoke-SBOMBuild.ps1'
        Test-Path -LiteralPath $path | Should -Be $true
    }

    It 'Invoke-SecretScan.ps1 exists' {
        $path = Join-Path $repoRoot 'scripts\security\Invoke-SecretScan.ps1'
        Test-Path -LiteralPath $path | Should -Be $true
    }

    It 'Invoke-VulnerabilityScan.ps1 exists' {
        $path = Join-Path $repoRoot 'scripts\security\Invoke-VulnerabilityScan.ps1'
        Test-Path -LiteralPath $path | Should -Be $true
    }

    It 'Invoke-SecurityBaseline.ps1 exists' {
        $path = Join-Path $repoRoot 'scripts\security\Invoke-SecurityBaseline.ps1'
        Test-Path -LiteralPath $path | Should -Be $true
    }
}

Describe 'Release tooling' {
    It 'bump-module-version.ps1 exists' {
        $path = Join-Path $repoRoot 'tools\release\bump-module-version.ps1'
        Test-Path -LiteralPath $path | Should -Be $true
    }

    It 'create-release-tag.ps1 exists' {
        $path = Join-Path $repoRoot 'tools\release\create-release-tag.ps1'
        Test-Path -LiteralPath $path | Should -Be $true
    }

    It 'test-release-prereqs.ps1 exists' {
        $path = Join-Path $repoRoot 'tools\release\test-release-prereqs.ps1'
        Test-Path -LiteralPath $path | Should -Be $true
    }
}

Describe 'No stale root artifacts' {
    It '_content_probe.txt is not present at repo root' {
        $path = Join-Path $repoRoot '_content_probe.txt'
        Test-Path -LiteralPath $path | Should -Be $false
    }

    It 'root file f is not present at repo root' {
        $path = Join-Path $repoRoot 'f'
        Test-Path -LiteralPath $path | Should -Be $false
    }
}
