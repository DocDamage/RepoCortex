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
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:manifestPath = Join-Path $script:repoRoot 'module\LLMWorkflow\LLMWorkflow.psd1'
    $script:manifest = Import-PowerShellDataFile -Path $script:manifestPath

    # Import the module
    Import-Module $script:manifestPath -Force -ErrorAction Stop
}

Describe 'Module manifest consistency' {
    It 'Manifest file exists' {
        Test-Path -LiteralPath $script:manifestPath | Should -Be $true
    }

    It 'Manifest parses as valid PowerShell data file' {
        { Import-PowerShellDataFile -Path $script:manifestPath } | Should -Not -Throw
    }

    It 'ModuleVersion matches VERSION file' {
        $versionPath = Join-Path $script:repoRoot 'VERSION'
        $versionContent = (Get-Content -LiteralPath $versionPath -Raw).Trim()
        [string]$script:manifest.ModuleVersion | Should -Be $versionContent
    }
}

Describe 'FunctionsToExport - all commands resolve' {
    It 'Has at least one function declared' {
        $script:manifest.FunctionsToExport.Count | Should -BeGreaterThan 0
    }

    It 'Every declared function resolves as a command in module LLMWorkflow' {
        foreach ($fn in $script:manifest.FunctionsToExport) {
            $cmd = Get-Command -Name $fn -Module LLMWorkflow -ErrorAction Stop
            $cmd | Should -Not -BeNullOrEmpty
            $cmd.CommandType | Should -Be 'Function'
        }
    }
}

Describe 'AliasesToExport - all aliases resolve' {
    It 'Has at least one alias declared' {
        $script:manifest.AliasesToExport.Count | Should -BeGreaterThan 0
    }

    It 'Every declared alias resolves to a valid command' {
        foreach ($alias in $script:manifest.AliasesToExport) {
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
        $result.manifestVersion | Should -Be ([string]$script:manifest.ModuleVersion)
    }

    It 'Test-LLMWorkflowSetup on TestDrive returns results' {
        { Test-LLMWorkflowSetup -ProjectRoot $TestDrive } | Should -Not -Throw
    }

    It 'Get-LLMWorkflowPlugins on TestDrive returns array' {
        { Get-LLMWorkflowPlugins -ProjectRoot $TestDrive } | Should -Not -Throw
    }

    It 'Get-LLMWorkflowRepairHistory on TestDrive returns result' {
        { Get-LLMWorkflowRepairHistory -ProjectRoot $TestDrive } | Should -Not -Throw
    }

    It 'Get-LLMWorkflowGameTemplates returns template list' {
        $result = Get-LLMWorkflowGameTemplates
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Get-LLMWorkflowNextAction returns an operator action on TestDrive' {
        Set-Content -LiteralPath (Join-Path $TestDrive 'VERSION') -Value '1.0.0' -Encoding UTF8
        $result = Get-LLMWorkflowNextAction -ProjectRoot $TestDrive
        $result.ActionId | Should -Not -BeNullOrEmpty
    }

    It 'Update-LLMWorkflowProject can generate a migration plan on TestDrive' {
        $result = Update-LLMWorkflowProject -ProjectRoot $TestDrive -Plan
        $result.Mode | Should -Be 'Plan'
    }
}

Describe 'Module re-import safety' {
    It 'Can import module multiple times without error' {
        Remove-Module LLMWorkflow -Force -ErrorAction SilentlyContinue
        { Import-Module $script:manifestPath -Force -ErrorAction Stop } | Should -Not -Throw
        { Import-Module $script:manifestPath -Force -ErrorAction Stop } | Should -Not -Throw
    }
}
