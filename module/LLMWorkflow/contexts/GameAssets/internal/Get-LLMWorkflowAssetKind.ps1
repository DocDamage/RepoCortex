Set-StrictMode -Version Latest

function Get-LLMWorkflowAssetKind {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Category,

        [Parameter(Mandatory = $true)]
        [string]$RelativePath,

        [Parameter(Mandatory = $true)]
        [string]$Extension
    )

    $path = $RelativePath.ToLowerInvariant().Replace('\', '/')

    switch ($Category) {
        "spritesheets" {
            if ($Extension -in @(".ase", ".aseprite")) { return "aseprite" }
            if ($path -match "(atlas|spriteatlas)") { return "atlas" }
            return "spritesheet"
        }
        "tilemaps" {
            if ($Extension -eq ".tsx" -or $path -match "tileset") { return "tileset" }
            if ($path -match "autotile") { return "autotile" }
            return "tilemap"
        }
        "sfx" { return "sfx" }
        "music" { return "music" }
        "plugins" {
            if ($Extension -eq ".uplugin") { return "unreal-plugin" }
            if ($Extension -eq ".js") { return "runtime-plugin" }
            if ($path -match "/editor/") { return "editor-plugin" }
            return "plugin"
        }
        "rpgmaker" {
            if ($Extension -eq ".js" -or $path -match "/js/plugins/") { return "plugin" }
            if ($path -match "(tileset|tilemap)") { return "tileset" }
            if ($path -match "(characters|battlers|faces|parallaxes)") { return "sprite" }
            if ($Extension -in @(".ogg", ".m4a", ".wav")) { return "audio" }
            return "rpgmaker-asset"
        }
        "unreal" {
            if ($Extension -eq ".uproject") { return "project" }
            if ($Extension -eq ".uplugin") { return "plugin" }
            if ($Extension -eq ".umap") { return "map" }
            if ($Extension -eq ".uasset") { return "uasset" }
            if ($Extension -in @(".fbx", ".obj")) { return "mesh" }
            return "unreal-asset"
        }
        "epic" {
            if ($path -match "megascans") { return "megascans" }
            if ($Extension -eq ".uplugin") { return "plugin" }
            if ($Extension -in @(".zip", ".7z", ".rar")) { return "marketplace-pack" }
            return "marketplace-asset"
        }
        "art" {
            if ($Extension -in @(".fbx", ".obj", ".gltf", ".glb", ".blend")) { return "model" }
            if ($path -match "(ui|hud)") { return "ui" }
            if ($path -match "sprite") { return "sprite" }
            return "texture"
        }
        "shared" {
            if ($Extension -in @(".zip", ".7z", ".rar", ".pak")) { return "archive" }
            if ($Extension -in @(".json", ".csv")) { return "manifest" }
            return "bundle"
        }
        default { return "asset" }
    }
}
