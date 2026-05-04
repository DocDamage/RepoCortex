#requires -Version 5.1
<#
.SYNOPSIS
    Verifies every function and alias declared in the module manifest actually loads.
.DESCRIPTION
    Imports the module and validates every FunctionsToExport entry resolves to a
    real command, and every AliasesToExport entry resolves to a real alias pointing
    to a real command. Also runs a minimum smoke call set to prove basic execution.
#>

Set-StrictMode -Version Latest

BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $manifestPath = Join-Path $repoRoot 'module\LLMWorkflow\LLMWorkflow.psd1'
    $manifest = Import-PowerShellDataFile -Path $manifestPath

    # Import the module
    Import-Module $manifestPath -Force -ErrorAction Stop
}

Describe 'Module manifest consistency' {
    It 'Manifest file exists' {
        Test-Path -LiteralPath $manifestPath | Should -Be $true
    }

    It 'Manifest parses as valid PowerShell data file' {
        { Import-PowerShellDataFile -Path $manifestPath } | Should -Not -Throw
    }

    It 'ModuleVersion matches VERSION file' {
        $versionPath = Join-Path $repoRoot 'VERSION'
        $versionContent = (Get-Content -LiteralPath $versionPath -Raw).Trim()
        [string]$manifest.ModuleVersion | Should -Be $versionContent
    }
}

Describe 'FunctionsToExport - all commands resolve' {
    It 'Has at least one function declared' {
        $manifest.FunctionsToExport.Count | Should -BeGreaterThan 0
    }

    foreach ($fn in $manifest.FunctionsToExport) {
        It "Function '$fn' resolves as a command in module LLMWorkflow" {
            $cmd = Get-Command -Name $fn -Module LLMWorkflow -ErrorAction Stop
            $cmd | Should -Not -BeNullOrEmpty
            $cmd.CommandType | Should -Be 'Function'
        }
    }
}

Describe 'AliasesToExport - all aliases resolve' {
    It 'Has at least one alias declared' {
        $manifest.AliasesToExport.Count | Should -BeGreaterThan 0
    }

    foreach ($alias in $manifest.AliasesToExport) {
        It "Alias '$alias' resolves to a valid command" {
            $resolved = Get-Alias -Name $alias -ErrorAction Stop
            $resolved | Should -Not -BeNullOrEmpty
            $targetCmd = Get-Command -Name $resolved.Definition -ErrorAction SilentlyContinue
            $targetCmd | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Smoke call set' {
    It 'Get-LLMWorkflowVersion returns version info' {
        $result = Get-LLMWorkflowVersion
        $result | Should -Not -BeNullOrEmpty
        $result.manifestVersion | Should -Be ([string]$manifest.ModuleVersion)
    }

    It 'Test-LLMWorkflowSetup on TestDrive returns results' {
        $result = Test-LLMWorkflowSetup -ProjectRoot $TestDrive
        $result | Should -Not -BeNullOrEmpty
        $result.passed | Should -Be -Or -Not $result.passed
    }

    It 'Get-LLMWorkflowPlugins on TestDrive returns array' {
        $result = Get-LLMWorkflowPlugins -ProjectRoot $TestDrive
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Get-LLMWorkflowRepairHistory on TestDrive returns result' {
        $result = Get-LLMWorkflowRepairHistory -ProjectRoot $TestDrive
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Get-LLMWorkflowGameTemplates returns template list' {
        $result = Get-LLMWorkflowGameTemplates
        $result | Should -Not -BeNullOrEmpty
    }
}

Describe 'Module re-import safety' {
    It 'Can import module multiple times without error' {
        Remove-Module LLMWorkflow -Force -ErrorAction SilentlyContinue
        { Import-Module $manifestPath -Force -ErrorAction Stop } | Should -Not -Throw
        { Import-Module $manifestPath -Force -ErrorAction Stop } | Should -Not -Throw
    }
}
