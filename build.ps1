#Requires -Modules @{ModuleName='InvokeBuild'; ModuleVersion='5.0.0'}
param([switch]$CI)

$script:LLMBuildScript = Join-Path $PSScriptRoot 'tools\build\Invoke-LLMBuild.ps1'

function Invoke-RepoLLMBuild {
    param([string[]]$Arguments)
    if (-not (Test-Path -LiteralPath $script:LLMBuildScript)) {
        throw "Missing build script: $script:LLMBuildScript"
    }
    & $script:LLMBuildScript @Arguments
}

# Synopsis: Run all PSScriptAnalyzer custom rules
task Lint {
    $rules = Get-ChildItem -Path tools/build/PSScriptAnalyzer -Filter '*.psm1' -ErrorAction Ignore
    $analyzerParams = @{
        Path = 'module/LLMWorkflow'
        Recurse = $true
        Severity = @('Error','Warning')
    }
    if ($rules) {
        $analyzerParams['CustomRulePath'] = $rules.FullName
    }
    $results = Invoke-ScriptAnalyzer @analyzerParams
    if ($results | Where-Object Severity -eq 'Error') {
        $results | Where-Object Severity -eq 'Error' | Format-Table -AutoSize | Out-String | Write-Output
        throw "PSScriptAnalyzer found errors that must be fixed"
    }
    if ($results | Where-Object Severity -eq 'Warning') {
        $results | Where-Object Severity -eq 'Warning' | Format-Table -AutoSize | Out-String | Write-Output
    }
    Write-Output "PSScriptAnalyzer linting complete."
}

# Synopsis: Run affected-context tests via Invoke-LLMBuild
task Test {
    Invoke-RepoLLMBuild -Arguments @('-Test', "-CI:$CI")
}

# Synopsis: Validate documentation truth and release-facing encoding
task Docs {
    Invoke-RepoLLMBuild -Arguments @('-Docs')
}

# Synopsis: Run boundary and size checks
task Check {
    Invoke-RepoLLMBuild -Arguments @('-WhatIf')
}

# Synopsis: Full build pipeline
task . Lint, Test, Docs
