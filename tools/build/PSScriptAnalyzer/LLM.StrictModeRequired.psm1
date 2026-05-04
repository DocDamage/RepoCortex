function Measure-LLMStrictModeRequired {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.Language.ScriptBlockAst]$ScriptBlockAst
    )

    $results = @()
    $path = $ScriptBlockAst.Extent.File
    if (-not $path) { return $results }
    if ($path -match '\.psd1$') { return $results } # Data files are not scripts

    # Only check the top-level script block of each file
    if ($ScriptBlockAst.Parent -ne $null) { return $results }

    $text = ($ScriptBlockAst.Extent.Text -replace '^[\s\uFEFF]+')
    if ($text -notmatch '^Set-StrictMode\s+-Version\s+Latest') {
        $results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
            Message  = "Missing 'Set-StrictMode -Version Latest'. Add it at the top of the file."
            Extent   = $ScriptBlockAst.Extent
            RuleName = 'LLM.StrictModeRequired'
            Severity = 'Error'
            RuleSuppressionID = 'LLMStrictModeRequired'
        }
    }

    return $results
}
