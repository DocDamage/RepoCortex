function Measure-LLMNoProcessEnvSecrets {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.Language.ScriptBlockAst]$ScriptBlockAst
    )

    $results = @()
    $calls = $ScriptBlockAst.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.CommandAst] -and
        $node.GetCommandName() -match 'SetEnvironmentVariable'
    }, $true)

    foreach ($cmd in $calls) {
        $extentText = $cmd.Extent.Text
        if ($extentText -match 'Process' -and
            $extentText -match '(API_KEY|SECRET|TOKEN|PWD|PASS)') {
            $results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                Message  = "Writing secrets to process-scoped environment variables exposes them to child processes. Use Get-LLMSecret or SecretManagement instead."
                Extent   = $cmd.Extent
                RuleName = 'LLM.NoProcessEnvSecrets'
                Severity = 'Error'
                RuleSuppressionID = 'LLMNoProcessEnvSecrets'
            }
        }
    }

    return $results
}
