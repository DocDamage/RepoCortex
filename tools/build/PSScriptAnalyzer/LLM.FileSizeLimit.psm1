function Measure-LLMFileSizeLimit {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.Language.ScriptBlockAst]$ScriptBlockAst
    )

    $results = @()
    $path = $ScriptBlockAst.Extent.File
    if (-not $path) { return $results }

    $lines = (Get-Content -LiteralPath $path | Measure-Object).Count
    if ($lines -gt 300) {
        $results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
            Message  = "File has $lines lines (max 300). Decompose into smaller modules."
            Extent   = $ScriptBlockAst.Extent
            RuleName = 'LLM.FileSizeLimit'
            Severity = 'Error'
            RuleSuppressionID = 'LLMFileSizeLimit'
        }
    }
    elseif ($lines -gt 200) {
        $results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
            Message  = "File has $lines lines (warning at 200, error at 300). Consider decomposition."
            Extent   = $ScriptBlockAst.Extent
            RuleName = 'LLM.FileSizeLimit'
            Severity = 'Warning'
            RuleSuppressionID = 'LLMFileSizeLimit'
        }
    }

    return $results
}
