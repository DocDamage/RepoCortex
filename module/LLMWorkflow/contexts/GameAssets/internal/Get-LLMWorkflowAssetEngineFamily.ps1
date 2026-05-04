Set-StrictMode -Version Latest

function Get-LLMWorkflowAssetEngineFamily {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Category
    )

    switch ($Category) {
        "rpgmaker" { return "rpgmaker" }
        "unreal" { return "unreal" }
        "epic" { return "epic" }
        "plugins" { return "plugin" }
        default { return "cross-engine" }
    }
}
