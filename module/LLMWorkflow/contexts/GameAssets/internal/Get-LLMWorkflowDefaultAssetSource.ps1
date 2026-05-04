Set-StrictMode -Version Latest

function Get-LLMWorkflowDefaultAssetSource {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Category
    )

    switch ($Category) {
        "epic" { return "fab" }
        "unreal" { return "unreal" }
        "rpgmaker" { return "rpgmaker" }
        "plugins" { return "custom" }
        default { return "unknown" }
    }
}
