#Requires -Modules @{ModuleName='InvokeBuild'; ModuleVersion='5.0.0'}
param([switch]$CI)

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
    & tools/build/Invoke-LLMBuild.ps1 -Test -CI:$CI
}

# Synopsis: Generate documentation from comment-based help
task Docs {
    & tools/build/Invoke-LLMBuild.ps1 -Docs
}

# Synopsis: Run boundary and size checks
task Check {
    & tools/build/Invoke-LLMBuild.ps1 -WhatIf
}

# Synopsis: Full build pipeline
task . Lint, Test, Docs
