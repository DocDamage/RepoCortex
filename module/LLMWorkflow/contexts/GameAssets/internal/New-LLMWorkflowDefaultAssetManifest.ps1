Set-StrictMode -Version Latest

function New-LLMWorkflowDefaultAssetManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectName
    )

    $today = Get-Date -Format "yyyy-MM-dd"
    return [ordered]@{
        project = $ProjectName
        version = "1.1.0"
        created = $today
        lastUpdated = $today
        assetCount = 0
        totalSize = "0 B"
        categories = New-LLMWorkflowDefaultAssetCategories
        licenseSummary = New-LLMWorkflowDefaultLicenseSummary
        templates = New-LLMWorkflowDefaultAssetTemplates
        exampleAssets = @(
            [ordered]@{
                id = "spritesheets-001"
                name = "Player Walk Atlas"
                fileName = "player_walk.png"
                path = "assets/spritesheets/player_walk.png"
                category = "spritesheets"
                assetKind = "spritesheet"
                engineFamily = "cross-engine"
                format = "png"
                dimensions = "512x256"
                fileSize = "48 KB"
                fileSizeBytes = 49152
                tags = @("character", "player", "walk-cycle")
                status = "wip"
                priority = "p0"
                assignedTo = "artist1"
                createdDate = $today
                modifiedDate = $today
                source = "original"
                sourceUrl = ""
                license = "original"
                licenseUrl = ""
                author = "Team"
                notes = "8-direction sprite sheet for shared engine import."
            },
            [ordered]@{
                id = "rpgmaker-001"
                name = "Battle Core Plugin"
                fileName = "BattleCore.js"
                path = "assets/engines/rpgmaker/js/plugins/BattleCore.js"
                category = "rpgmaker"
                assetKind = "plugin"
                engineFamily = "rpgmaker"
                format = "js"
                fileSize = "18 KB"
                fileSizeBytes = 18432
                tags = @("rpgmaker", "plugin", "battle")
                status = "review"
                priority = "p1"
                assignedTo = ""
                createdDate = $today
                modifiedDate = $today
                source = "custom"
                sourceUrl = ""
                license = "proprietary"
                licenseUrl = ""
                author = ""
                notes = "Tracks imported RPG Maker plugins separately from shared code assets."
            },
            [ordered]@{
                id = "unreal-001"
                name = "Hero Material Instance"
                fileName = "MI_Hero.uasset"
                path = "assets/engines/unreal/Characters/Hero/MI_Hero.uasset"
                category = "unreal"
                assetKind = "uasset"
                engineFamily = "unreal"
                format = "uasset"
                fileSize = "256 KB"
                fileSizeBytes = 262144
                tags = @("unreal", "material", "character")
                status = "done"
                priority = "p1"
                assignedTo = ""
                createdDate = $today
                modifiedDate = $today
                source = "fab"
                sourceUrl = ""
                license = "proprietary"
                licenseUrl = ""
                author = ""
                notes = "Example Unreal content inventory entry."
            }
        )
    }
}
