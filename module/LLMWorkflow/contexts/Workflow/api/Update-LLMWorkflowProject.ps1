Set-StrictMode -Version Latest

function Update-LLMWorkflowProject {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param(
        [Parameter()]
        [string]$ProjectRoot = '.',

        [Parameter()]
        [switch]$Plan
    )

    $resolvedRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
    $actions = @()

    $readmePath = Join-Path $resolvedRoot 'README.md'
    if (Test-Path -LiteralPath $readmePath) {
        $readme = Get-Content -LiteralPath $readmePath -Raw
        if ($readme -match 'CodeMunch-ContextLattice-MemPalace---All-in-one') {
            $actions += [pscustomobject][ordered]@{
                ActionId = 'rename-readme-brand'
                Path = $readmePath
                Description = 'Replace legacy repository title with Repo Cortex branding.'
                Mutates = $true
            }
        }
    }

    foreach ($dirName in @('.codemunch', '.contextlattice', '.memorybridge')) {
        $dirPath = Join-Path $resolvedRoot $dirName
        if (Test-Path -LiteralPath $dirPath) {
            $actions += [pscustomobject][ordered]@{
                ActionId = "verify-$($dirName.TrimStart('.'))-config"
                Path = $dirPath
                Description = "Verify $dirName config against current Repo Cortex templates."
                Mutates = $false
            }
        }
    }

    $ledgerPath = Join-Path $resolvedRoot '.llm-workflow\security-exceptions.json'
    if (-not (Test-Path -LiteralPath $ledgerPath)) {
        $actions += [pscustomobject][ordered]@{
            ActionId = 'create-security-exception-ledger'
            Path = $ledgerPath
            Description = 'Create a structured security exception ledger for reviewed scanner findings.'
            Mutates = $true
        }
    }

    if (-not $Plan) {
        foreach ($action in $actions) {
            if ($action.ActionId -eq 'rename-readme-brand' -and $PSCmdlet.ShouldProcess($action.Path, $action.Description)) {
                $content = Get-Content -LiteralPath $action.Path -Raw
                $content = $content -replace 'CodeMunch-ContextLattice-MemPalace---All-in-one', 'Repo Cortex'
                Set-Content -LiteralPath $action.Path -Value $content -Encoding UTF8
            }
            elseif ($action.ActionId -eq 'create-security-exception-ledger' -and $PSCmdlet.ShouldProcess($action.Path, $action.Description)) {
                $dir = Split-Path -Parent $action.Path
                if (-not (Test-Path -LiteralPath $dir)) {
                    New-Item -ItemType Directory -Path $dir -Force | Out-Null
                }
                [ordered]@{ schemaVersion = 1; exceptions = @() } |
                    ConvertTo-Json -Depth 4 |
                    Set-Content -LiteralPath $action.Path -Encoding UTF8
            }
        }
    }

    return [pscustomobject][ordered]@{
        Mode = $(if ($Plan) { 'Plan' } else { 'Apply' })
        ProjectRoot = $resolvedRoot
        Actions = @($actions)
    }
}
