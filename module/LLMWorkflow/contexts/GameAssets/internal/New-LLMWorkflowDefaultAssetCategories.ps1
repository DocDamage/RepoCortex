Set-StrictMode -Version Latest

function New-LLMWorkflowDefaultAssetCategories {
    [CmdletBinding()]
    param()

    return [ordered]@{
        art = [ordered]@{
            description = "Shared visual assets such as textures, models, UI, concept art, and reference images"
            folder = "assets/art"
            assetCount = 0
            assets = @()
        }
        spritesheets = [ordered]@{
            description = "Sprite sheets, atlases, Aseprite files, and frame-based 2D animation sources"
            folder = "assets/spritesheets"
            assetCount = 0
            assets = @()
        }
        tilemaps = [ordered]@{
            description = "Tilemaps, tilesets, autotile definitions, and level-layout source files"
            folder = "assets/tilemaps"
            assetCount = 0
            assets = @()
        }
        sfx = [ordered]@{
            description = "Sound effects and short-form gameplay audio"
            folder = "assets/sfx"
            assetCount = 0
            assets = @()
        }
        music = [ordered]@{
            description = "Music, ambiences, stems, and long-form audio tracks"
            folder = "assets/music"
            assetCount = 0
            assets = @()
        }
        plugins = [ordered]@{
            description = "Engine plugins, editor extensions, runtime modules, and integration scripts"
            folder = "assets/plugins"
            assetCount = 0
            assets = @()
        }
        rpgmaker = [ordered]@{
            description = "RPG Maker project assets such as plugins, character sheets, tilesets, and database-adjacent resources"
            folder = "assets/engines/rpgmaker"
            assetCount = 0
            assets = @()
        }
        unreal = [ordered]@{
            description = "Unreal Engine content including uasset, umap, uproject, imported meshes, and project-side content"
            folder = "assets/engines/unreal"
            assetCount = 0
            assets = @()
        }
        epic = [ordered]@{
            description = "Epic ecosystem assets such as Fab marketplace drops, Megascans, and Epic-distributed samples"
            folder = "assets/engines/epic"
            assetCount = 0
            assets = @()
        }
        shared = [ordered]@{
            description = "Cross-engine packs, archives, manifests, and assets shared across toolchains"
            folder = "assets/shared"
            assetCount = 0
            assets = @()
        }
    }
}
