Set-StrictMode -Version Latest

function Invoke-LLMWorkflowGameUp {
    <#
    .SYNOPSIS
        Game team workflow bootstrap with preset support.
    .DESCRIPTION
        Extended version of Invoke-LLMWorkflowUp with game-specific features.
        Automatically detects game projects and applies appropriate settings.
    .PARAMETER ProjectRoot
        Path to the project root.
    .PARAMETER GameTeam
        Activate game team preset.
    .PARAMETER Template
        Game template to use.
    .PARAMETER Engine
        Game engine being used.
    .PARAMETER JamMode
        Enable jam mode (fast iteration, ContinueOnError).
    .PARAMETER All other parameters from Invoke-LLMWorkflowUp
    .EXAMPLE
        Invoke-LLMWorkflowGameUp -GameTeam -Template "2d-platformer"
        Sets up a game project with 2D platformer template.
    .EXAMPLE
        llmup -GameTeam -JamMode
        Quick jam setup with defaults.
    #>
    [OutputType([void])]
    [CmdletBinding()]
    param(
        [string]$ProjectRoot = ".",
        [switch]$GameTeam,
        [string]$Template = "",
        [string]$Engine = "",
        [switch]$JamMode,
        [switch]$SkipDependencyInstall,
        [switch]$SkipContextVerify,
        [switch]$SkipBridgeDryRun,
        [switch]$SmokeTestContext,
        [switch]$RequireSearchHit,
        [switch]$ContinueOnError,
        [switch]$ShowTiming,
        [switch]$Offline,
        [switch]$AsJson
    )
    
    $projectPath = Resolve-Path -LiteralPath $ProjectRoot
    
    # Check for existing game preset
    $gamePresetPath = Join-Path (Join-Path $projectPath '.llm-workflow') 'game-preset.json'
    $isGameProject = Test-Path -LiteralPath $gamePresetPath
    
    # Auto-detect game mode
    if ($isGameProject -and -not $GameTeam) {
        Write-Host "[gameteam] Detected game project, enabling game team mode" -ForegroundColor Cyan
        $GameTeam = $true
    }
    
    # Apply jam mode defaults
    if ($JamMode) {
        Write-Host "[gameteam] Jam Mode: enabling ContinueOnError and fast checks" -ForegroundColor Yellow
        $ContinueOnError = $true
    }
    
    # If GameTeam flag is set, ensure game structure exists
    if ($GameTeam) {
        if (-not $isGameProject) {
            Write-Host "[gameteam] Initializing game project structure..." -ForegroundColor Cyan
            New-LLMWorkflowGamePreset -ProjectRoot $projectPath -Template $Template -Engine $Engine -JamMode:$JamMode
        } else {
            Write-Host "[gameteam] Game project already initialized" -ForegroundColor Gray
        }
    }
    
    # Call base workflow up with appropriate parameters
    $invokeArgs = @{
        ProjectRoot = $ProjectRoot
    }
    
    if ($SkipDependencyInstall) { $invokeArgs["SkipDependencyInstall"] = $true }
    if ($SkipContextVerify -or $JamMode) { $invokeArgs["SkipContextVerify"] = $true }
    if ($SkipBridgeDryRun -or $JamMode) { $invokeArgs["SkipBridgeDryRun"] = $true }
    if ($SmokeTestContext) { $invokeArgs["SmokeTestContext"] = $true }
    if ($RequireSearchHit) { $invokeArgs["RequireSearchHit"] = $true }
    if ($ContinueOnError -or $JamMode) { $invokeArgs["ContinueOnError"] = $true }
    if ($ShowTiming) { $invokeArgs["ShowTiming"] = $true }
    if ($Offline) { $invokeArgs["Offline"] = $true }
    if ($AsJson) { $invokeArgs["AsJson"] = $true }
    
    # Call the base Invoke-LLMWorkflowUp
    Invoke-LLMWorkflowUp @invokeArgs
    
    # Game-specific post-setup
    if ($GameTeam) {
        Write-Host "[gameteam] Game setup complete" -ForegroundColor Green
        Write-Host "[gameteam] Templates available: GDD.md, TASKS.md, ASSET_MANIFEST.json" -ForegroundColor Gray
    }
}
