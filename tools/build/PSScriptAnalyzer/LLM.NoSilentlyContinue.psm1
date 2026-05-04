function Measure-LLMNoSilentlyContinue {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.Language.ScriptBlockAst]$ScriptBlockAst
    )

    $results = @()
    $commands = $ScriptBlockAst.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.CommandAst]
    }, $true)

    foreach ($cmd in $commands) {
        foreach ($param in $cmd.CommandElements) {
            if ($param -is [System.Management.Automation.Language.CommandParameterAst] -and
                $param.ParameterName -eq 'ErrorAction' -and
                $param.Argument -and
                $param.Argument.Value -eq 'SilentlyContinue') {

                # Check if line has ALLOWED comment
                $line = $param.Extent.StartLineNumber
                $text = $ScriptBlockAst.Extent.Text
                $lines = $text -split "`r?`n"
                $lineText = if ($line -le $lines.Count) { $lines[$line - 1] } else { '' }
                if ($lineText -notmatch '#\s*\[ALLOWED:') {
                    $results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                        Message  = "-ErrorAction SilentlyContinue hides failures. Use 'Stop' with try/catch, or add '# [ALLOWED: <justification>]' comment."
                        Extent   = $param.Extent
                        RuleName = 'LLM.NoSilentlyContinue'
                        Severity = 'Error'
                        RuleSuppressionID = 'LLMNoSilentlyContinue'
                    }
                }
            }
        }
    }

    return $results
}
