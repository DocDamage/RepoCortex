Set-StrictMode -Version Latest

function New-LLMWorkflowGamePreset {
    <#
    .SYNOPSIS
        Creates a game project structure with GDD, asset management, and task board.
    .DESCRIPTION
        Sets up a complete game development workflow with docs, assets, and templates.
        Optimized for rapid prototyping and game jam workflows.
    .PARAMETER ProjectRoot
        Path to the project root. Defaults to current directory.
    .PARAMETER ProjectName
        Name of the game project.
    .PARAMETER Template
        Game template to use (2d-platformer, topdown-rpg, puzzle, etc.).
    .PARAMETER Engine
        Game engine being used (Unity, Godot, Unreal, etc.).
    .PARAMETER JamMode
        Enable jam mode for fast iteration (sets ContinueOnError, lightweight artifacts).
    .PARAMETER SkipAssetFolders
        Skip creating asset subfolders (sfx, music, art).
    .EXAMPLE
        New-LLMWorkflowGamePreset -ProjectName "MyPlatformer" -Template "2d-platformer" -Engine "Godot"
        Creates a new 2D platformer project using Godot.
    .EXAMPLE
        New-LLMWorkflowGamePreset -JamMode
        Sets up a jam-optimized project in current directory.
    #>
    [OutputType([pscustomobject])]
    [CmdletBinding()]
    param(
        [string]$ProjectRoot = ".",
        [string]$ProjectName = "",
        [ValidateSet("2d-platformer", "topdown-rpg", "puzzle", "fps-prototype", "visual-novel", "roguelike", "card-game", "endless-runner", "")]
        [string]$Template = "",
        [string]$Engine = "",
        [switch]$JamMode,
        [switch]$SkipAssetFolders
    )
    
    $ErrorActionPreference = "Stop"
    
    # Resolve or create project path
    if (Test-Path -LiteralPath $ProjectRoot) {
        $projectPath = (Resolve-Path -LiteralPath $ProjectRoot).Path
    } else {
        New-Item -ItemType Directory -Path $ProjectRoot -Force | Out-Null
        $projectPath = (Resolve-Path -LiteralPath $ProjectRoot).Path
    }
    
    # Determine project name
    if ([string]::IsNullOrWhiteSpace($ProjectName)) {
        $ProjectName = Split-Path -Leaf $projectPath
    }
    
    Write-Host "[gameteam] Creating game project: $ProjectName" -ForegroundColor Cyan
    
    # Load preset data
    $preset = Get-GamePresetData
    
    # Create folder structure from preset data so templates and implementation stay aligned
    $folders = @()
    if ($preset.folderStructure) {
        foreach ($folder in $preset.folderStructure) {
            $normalizedFolder = ([string]$folder).TrimEnd("/", "\")
            if ([string]::IsNullOrWhiteSpace($normalizedFolder)) {
                continue
            }

            if ($SkipAssetFolders -and $normalizedFolder -like "assets/*" -and $normalizedFolder -ne "assets") {
                continue
            }

            if ($folders -notcontains $normalizedFolder) {
                $folders += $normalizedFolder
            }
        }
    }

    if ($folders.Count -eq 0) {
        $folders = @("docs", "assets", ".llm-workflow")
    }
    
    foreach ($folder in $folders) {
        $folderPath = Join-Path $projectPath $folder
        if (-not (Test-Path -LiteralPath $folderPath)) {
            New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
            Write-Host "[gameteam] Created: $folder/" -ForegroundColor Gray
        } else {
            Write-Host "[gameteam] Exists: $folder/" -ForegroundColor DarkGray
        }
    }
    
    # Copy template files
    $templateFiles = @(
        @{ Source = "GDD.md"; Dest = (Join-Path 'docs' 'GDD.md') },
        @{ Source = "TASKS.md"; Dest = (Join-Path 'docs' 'TASKS.md') },
        @{ Source = "ASSET_MANIFEST.json"; Dest = (Join-Path 'assets' 'ASSET_MANIFEST.json') }
    )
    
    $createdFiles = @()
    foreach ($tf in $templateFiles) {
        $sourcePath = Join-Path $GameTemplateRoot $tf.Source
        $destPath = Join-Path $projectPath $tf.Dest
        
        if (-not (Test-Path -LiteralPath $sourcePath)) {
            Write-Warning "[gameteam] Template not found: $($tf.Source)"
            continue
        }
        
        if (Test-Path -LiteralPath $destPath) {
            Write-Host "[gameteam] Exists: $($tf.Dest)" -ForegroundColor DarkGray
        } else {
            Copy-Item -LiteralPath $sourcePath -Destination $destPath -Force
            Write-Host "[gameteam] Created: $($tf.Dest)" -ForegroundColor Gray
            $createdFiles += $tf.Dest
        }
    }
    
    # Create game-preset.json config
    $configPath = Join-Path (Join-Path $projectPath '.llm-workflow') 'game-preset.json'
    $config = @{
        projectName = $ProjectName
        created = (Get-Date -Format "yyyy-MM-dd")
        template = $Template
        engine = $Engine
        jamMode = $JamMode.IsPresent
        version = "1.0.0"
    }
    $config.provenance = [ordered]@{
        createdBy = 'LLMWorkflow.GameFunctions'
        createdAt = [DateTime]::UtcNow.ToString('o')
    }
    
    if (Test-Path -LiteralPath $configPath) {
        Write-Host "[gameteam] Exists: .llm-workflow/game-preset.json" -ForegroundColor DarkGray
    } else {
        $config | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $configPath -Encoding UTF8
        Write-Host "[gameteam] Created: .llm-workflow/game-preset.json" -ForegroundColor Gray
        $createdFiles += Join-Path '.llm-workflow' 'game-preset.json'
    }
    
    # Apply template-specific defaults if specified
    if (-not [string]::IsNullOrWhiteSpace($Template)) {
        $templateData = $preset.gameTemplates | Where-Object { $_.id -eq $Template } | Select-Object -First 1
        if ($templateData) {
            Write-Host "[gameteam] Template: $($templateData.name)" -ForegroundColor Cyan
            if ([string]::IsNullOrWhiteSpace($Engine) -and $templateData.defaultEngine) {
                $Engine = ($templateData.defaultEngine -split "\|")[0]
                Write-Host "[gameteam] Suggested engine: $Engine" -ForegroundColor Gray
            }
        }
    }
    
    # Jam mode settings
    if ($JamMode) {
        Write-Host "[gameteam] Jam Mode enabled - fast iteration settings applied" -ForegroundColor Yellow
    }
    
    # Return summary
    return [pscustomobject]@{
        ProjectName = $ProjectName
        ProjectRoot = $projectPath
        Template = $Template
        Engine = $Engine
        JamMode = $JamMode.IsPresent
        CreatedFolders = $folders
        CreatedFiles = $createdFiles
        Provenance = $config.provenance
        Success = $true
    }
}
