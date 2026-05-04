function Measure-LLMCmdletBindingRequired {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.Language.ScriptBlockAst]$ScriptBlockAst
    )

    $results = @()
    $functions = $ScriptBlockAst.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
    }, $true)

    foreach ($func in $functions) {
        # Only check exported-looking functions (PascalCase, public verbs)
        if ($func.Name -cmatch '^[A-Z][a-zA-Z0-9-]+$' -and
            $func.Name -notmatch '^[a-z]') {
            $body = $func.Body
            $hasAttr = $false
            foreach ($attr in $body.ParamBlock.Attributes) {
                if ($attr.TypeName.Name -eq 'CmdletBinding') {
                    $hasAttr = $true
                    break
                }
            }
            if (-not $hasAttr) {
                $results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                    Message  = "Public function '$($func.Name)' lacks [CmdletBinding()]. Add it for proper pipeline support."
                    Extent   = $func.Extent
                    RuleName = 'LLM.CmdletBindingRequired'
                    Severity = 'Warning'
                    RuleSuppressionID = 'LLMCmdletBindingRequired'
                }
            }
        }
    }

    return $results
}
