Set-StrictMode -Version Latest

function Get-LLMWorkflowAssetCategory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath,

        [Parameter(Mandatory = $true)]
        [string]$Extension
    )

    $path = $RelativePath.ToLowerInvariant().Replace('\', '/')
    $isImage = $Extension -in @(".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp", ".tga", ".psd")
    $isAudio = $Extension -in @(".wav", ".mp3", ".ogg", ".flac", ".aac", ".m4a")
    $isModel = $Extension -in @(".fbx", ".obj", ".gltf", ".glb", ".blend", ".dae")
    $isPlugin = $Extension -in @(".uplugin", ".gdextension", ".gde", ".dll", ".js", ".py", ".cs")

    if ($path -match "^assets/music/" -or $path -match "/(bgm|music|songs?)/") { return "music" }
    if ($path -match "^assets/sfx/" -or $path -match "/(sfx|se|sounds?)/") { return "sfx" }
    if ($path -match "/(engines/)?epic/" -or $path -match "/fab/" -or $path -match "/megascans/") { return "epic" }
    if ($path -match "/(engines/)?unreal/" -or $Extension -in @(".uasset", ".umap", ".uproject", ".ubulk", ".uexp")) { return "unreal" }
    if ($path -match "/(engines/)?rpgmaker/" -or $path -match "/rmmz/" -or $Extension -in @(".rmmzproject", ".rvdata", ".rvdata2", ".rxdata")) { return "rpgmaker" }
    if ($path -match "/plugins?/" -or $Extension -in @(".uplugin", ".gdextension", ".gde")) { return "plugins" }
    if ($path -match "/shared/") { return "shared" }
    if ($path -match "/spritesheets?/" -or $path -match "(spritesheet|sprite_sheet|sprite-atlas|spriteatlas|atlas)" -or $Extension -in @(".ase", ".aseprite")) { return "spritesheets" }
    if ($path -match "/tilemaps?/" -or $path -match "(tilemap|tileset|autotile)" -or $Extension -in @(".tmx", ".tsx")) { return "tilemaps" }
    if ($path -match "^assets/art/") { return "art" }

    if ($isImage -or $isModel) { return "art" }
    if ($isAudio) { return "sfx" }
    if ($isPlugin) { return "plugins" }
    if ($Extension -in @(".zip", ".7z", ".rar", ".pak", ".csv", ".json")) { return "shared" }

    return "shared"
}
