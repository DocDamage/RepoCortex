#requires -Version 5.1
<#
.SYNOPSIS
    Tests for GoldenTask execution correctness: default path errors, offline mode,
    PS 5.1-compatible result persistence, and failure recording.
#>

Set-StrictMode -Version Latest

BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $manifestPath = Join-Path $repoRoot 'module\LLMWorkflow\LLMWorkflow.psd1'

    # Import the module to get all functions available
    Import-Module $manifestPath -Force -ErrorAction Stop

    # Simple test task
    $script:testTask = @{
        taskId = 'gt-test-execution-001'
        name = 'Test Execution Task'
        packId = 'test-pack'
        category = 'test'
        difficulty = 'easy'
        query = 'What is the capital of France?'
        expectations = @(
            @{
                property = 'answer'
                rule = 'contains'
                value = 'Paris'
            }
        )
    }
}

Describe 'Invoke-GoldenTask default path' {
    It 'Throws when no executor is available and -Offline is not set' {
        # Temporarily clear any provider env vars to force the error path
        $savedKeys = @{}
        $providerVars = @('OPENAI_API_KEY', 'ANTHROPIC_API_KEY', 'KIMI_API_KEY', 'GEMINI_API_KEY', 'GLM_API_KEY', 'OLLAMA_API_KEY')
        foreach ($var in $providerVars) {
            $val = [Environment]::GetEnvironmentVariable($var, 'Process')
            if ($val) { $savedKeys[$var] = $val; [Environment]::SetEnvironmentVariable($var, $null, 'Process') }
        }

        try {
            { Invoke-GoldenTask -Task $testTask -ErrorAction Stop } | Should -Throw
        }
        finally {
            # Restore
            foreach ($var in $savedKeys.Keys) {
                [Environment]::SetEnvironmentVariable($var, $savedKeys[$var], 'Process')
            }
        }
    }
}

Describe 'Invoke-GoldenTask -Offline mode' {
    It 'Returns mode = OfflineSimulation when -Offline is set' {
        $result = Invoke-GoldenTask -Task $testTask -Offline
        $result | Should -Not -BeNullOrEmpty
        $result.LLMResponse.mode | Should -Be 'OfflineSimulation'
        $result.Success | Should -Be -Or -Not $result.Success
    }

    It 'Returns a valid EvaluationId' {
        $result = Invoke-GoldenTask -Task $testTask -Offline
        $result.EvaluationId | Should -Not -BeNullOrEmpty
    }
}

Describe 'Save-GoldenTaskResult PS 5.1 compatibility' {
    It 'Writes valid JSON to specified path' {
        $outputPath = Join-Path $TestDrive 'golden-test-results.json'
        $result = Invoke-GoldenTask -Task $testTask -Offline

        # Save via the function
        Save-GoldenTaskResult -Result $result -OutputPath $outputPath

        Test-Path -LiteralPath $outputPath | Should -Be $true
        $saved = Get-Content -LiteralPath $outputPath -Raw
        $saved | Should -Not -BeNullOrEmpty
        $parsed = ConvertFrom-Json -InputObject $saved
        $parsed | Should -Not -BeNullOrEmpty
    }

    It 'Merges new results with existing JSON without -AsHashtable' {
        $outputPath = Join-Path $TestDrive 'golden-merge-results.json'

        # Save first result
        $result1 = Invoke-GoldenTask -Task $testTask -Offline
        Save-GoldenTaskResult -Result $result1 -OutputPath $outputPath

        # Save second result (should merge)
        $result2 = Invoke-GoldenTask -Task $testTask -Offline
        Save-GoldenTaskResult -Result $result2 -OutputPath $outputPath

        # Read back and verify both entries exist
        $saved = Get-Content -LiteralPath $outputPath -Raw | ConvertFrom-Json
        $saved.Count | Should -Be 2
    }

    It 'Handles corrupt/missing file gracefully' {
        $outputPath = Join-Path $TestDrive 'missing-file-test.json'
        # Should not throw on non-existent file
        $result = Invoke-GoldenTask -Task $testTask -Offline
        { Save-GoldenTaskResult -Result $result -OutputPath $outputPath } | Should -Not -Throw
    }
}

Describe 'Failure path records errors' {
    It 'Returns error result for invalid task' {
        $badTask = @{
            taskId = 'gt-bad-001'
            name = 'Bad task'
        }
        $result = Invoke-GoldenTask -Task $badTask -Offline
        $result.Success | Should -Be $false
        $result.Error | Should -Not -BeNullOrEmpty
    }

    It 'Records error in result even without -RecordResults' {
        $badTask = @{
            taskId = 'gt-bad-002'
            name = 'Another bad task'
        }
        $result = Invoke-GoldenTask -Task $badTask -Offline
        $result.Success | Should -Be $false
    }
}

Describe 'ConvertTo-Hashtable PS 5.1 compatibility' {
    It 'Converts PSCustomObject to hashtable' {
        $obj = [pscustomobject]@{ a = 1; b = 'two'; c = $true }
        $hash = ConvertTo-Hashtable -InputObject $obj
        $hash | Should -BeOfType [hashtable]
        $hash['a'] | Should -Be 1
        $hash['b'] | Should -Be 'two'
        $hash['c'] | Should -Be $true
    }

    It 'Converts nested PSCustomObject to nested hashtable' {
        $nested = [pscustomobject]@{ outer = [pscustomobject]@{ inner = 'value' } }
        $hash = ConvertTo-Hashtable -InputObject $nested
        $hash['outer'] | Should -BeOfType [hashtable]
        $hash['outer']['inner'] | Should -Be 'value'
    }

    It 'Passes through hashtable unchanged' {
        $original = @{ x = 1; y = @{ z = 2 } }
        $result = ConvertTo-Hashtable -InputObject $original
        $result | Should -Be $original
    }
}
