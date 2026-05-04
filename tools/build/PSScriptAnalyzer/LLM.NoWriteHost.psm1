function Measure-LLMNoWriteHost {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.Language.ScriptBlockAst]$ScriptBlockAst
    )

    $results = @()
    $path = $ScriptBlockAst.Extent.File
    if (-not $path) { return $results }

    # Only check top-level script blocks to avoid duplicate reports
    if ($ScriptBlockAst.Parent -ne $null) { return $results }

    # Allow Write-Host in console UI rendering helpers and interactive setup functions
    $normalizedPath = $path -replace '\\', '/'
    if ($normalizedPath -match '/contexts/[^/]+/internal/') { return $results }
    if ($normalizedPath -match '/api/Show-') { return $results }
    if ($normalizedPath -match '/api/Invoke-LLMWorkflowGameUp\.ps1$') { return $results }
    if ($normalizedPath -match '/api/Export-LLMWorkflowAssetManifest\.ps1$') { return $results }
    if ($normalizedPath -match '/api/New-LLMWorkflowGamePreset\.ps1$') { return $results }
    if ($normalizedPath -match '/api/Export-DashboardHTML\.ps1$') { return $results }
    if ($normalizedPath -match '/api/Invoke-LLMWorkflowHeal\.ps1$') { return $results }

    $commands = $ScriptBlockAst.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.CommandAst] -and
        $node.GetCommandName() -eq 'Write-Host'
    }, $true)

    foreach ($cmd in $commands) {
        $results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
            Message  = "Write-Host breaks pipeline composability. Use Write-Information or return structured output."
            Extent   = $cmd.Extent
            RuleName = 'LLM.NoWriteHost'
            Severity = 'Error'
            RuleSuppressionID = 'LLMNoWriteHost'
        }
    }

    return $results
}
