#requires -Version 5.1
Set-StrictMode -Version Latest

function Get-PredefinedGodotTasks {
    [CmdletBinding()]
    [OutputType([array])]
    param()

    return @(
            # Task 1: GDScript Class Generation
            (New-GoldenTask `
                -TaskId "gt-godot-001" `
                -Name "GDScript class generation" `
                -Description "Generate a GDScript class with proper structure" `
                -PackId "godot" `
                -Category "codegen" `
                -Difficulty "easy" `
                -Query "Generate a GDScript class called 'PlayerController' that extends CharacterBody2D with a speed property and _physics_process method" `
                -ExpectedResult @{
                    extendsCharacterBody2D = $true
                    hasClassName = "PlayerController"
                    hasSpeedProperty = $true
                    hasPhysicsProcess = $true
                    usesGDScriptSyntax = $true
                } `
                -RequiredEvidence @(
                    @{ source = "godot-api"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("hasClassName", "hasSpeedProperty", "hasPhysicsProcess")
                    forbiddenPatterns = @("public class", "def ")
                    minConfidence = 0.8
                } `
                -Tags @("codegen", "gdscript", "class", "node")
            ),

            # Task 2: Signal Connection Setup
            (New-GoldenTask `
                -TaskId "gt-godot-002" `
                -Name "Signal connection setup" `
                -Description "Demonstrate proper Godot signal connection patterns" `
                -PackId "godot" `
                -Category "codegen" `
                -Difficulty "medium" `
                -Query "Show three ways to connect a button's pressed signal to a callback function in GDScript, including the @onready pattern" `
                -ExpectedResult @{
                    showsConnectMethod = $true
                    showsEditorConnection = $true
                    showsOnreadyPattern = $true
                    includesSignalCallback = $true
                } `
                -RequiredEvidence @(
                    @{ source = "godot-signals"; type = "signal-pattern" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("showsConnectMethod", "showsOnreadyPattern")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("codegen", "signals", "connection", "gdscript")
            ),

            # Task 3: Autoload Setup
            (New-GoldenTask `
                -TaskId "gt-godot-003" `
                -Name "Autoload (Singleton) setup" `
                -Description "Explain and demonstrate Godot autoload/singleton pattern" `
                -PackId "godot" `
                -Category "codegen" `
                -Difficulty "easy" `
                -Query "Create a GameManager autoload script in GDScript that tracks player score and lives, and show how to access it from another scene" `
                -ExpectedResult @{
                    createsGameManager = $true
                    tracksScoreAndLives = $true
                    showsAutoloadAccess = $true
                    usesGlobalReference = $true
                } `
                -RequiredEvidence @(
                    @{ source = "godot-autoload"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("createsGameManager", "tracksScoreAndLives", "showsAutoloadAccess")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("codegen", "autoload", "singleton", "global", "gdscript")
            ),

            # Task 4: Scene Inheritance Pattern
            (New-GoldenTask `
                -TaskId "gt-godot-004" `
                -Name "Scene inheritance pattern" `
                -Description "Demonstrate scene inheritance and instance overrides" `
                -PackId "godot" `
                -Category "codegen" `
                -Difficulty "medium" `
                -Query "Explain scene inheritance in Godot with an example: create a base enemy scene and show how to inherit from it to create a specific enemy type." `
                -ExpectedResult @{
                    explainsSceneInheritance = $true
                    showsBaseScene = $true
                    showsInheritedScene = $true
                    explainsEditableChildren = $true
                    mentionsInstanceOverrides = $true
                } `
                -RequiredEvidence @(
                    @{ source = "godot-scenes"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("explainsSceneInheritance", "showsBaseScene", "showsInheritedScene")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("codegen", "scene", "inheritance", "instancing")
            ),

            # Task 5: Resource Preloading
            (New-GoldenTask `
                -TaskId "gt-godot-005" `
                -Name "Resource preloading" `
                -Description "Demonstrate proper resource loading and preloading patterns" `
                -PackId "godot" `
                -Category "codegen" `
                -Difficulty "easy" `
                -Query "Show the difference between preload(), load(), and ResourceLoader in GDScript with examples of when to use each." `
                -ExpectedResult @{
                    explainsPreload = $true
                    explainsLoad = $true
                    explainsResourceLoader = $true
                    providesUseCases = $true
                    mentionsEditorVsRuntime = $true
                } `
                -RequiredEvidence @(
                    @{ source = "godot-resources"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("explainsPreload", "explainsLoad", "providesUseCases")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("codegen", "resources", "preload", "loading")
            ),

            # Task 6: Custom Node Creation
            (New-GoldenTask `
                -TaskId "gt-godot-006" `
                -Name "Custom node creation" `
                -Description "Create a custom node with custom drawing and gizmos" `
                -PackId "godot" `
                -Category "codegen" `
                -Difficulty "medium" `
                -Query "Create a custom Node2D that draws a health bar above the node using _draw(). Include a @tool script for editor visualization." `
                -ExpectedResult @{
                    extendsNode2D = $true
                    implementsDraw = $true
                    usesToolAnnotation = $true
                    drawsHealthBar = $true
                    handlesEditorPreview = $true
                } `
                -RequiredEvidence @(
                    @{ source = "godot-custom-drawing"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("extendsNode2D", "implementsDraw", "drawsHealthBar")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("codegen", "custom-node", "drawing", "tool")
            ),

            # Task 7: Editor Plugin Development
            (New-GoldenTask `
                -TaskId "gt-godot-007" `
                -Name "Editor plugin development" `
                -Description "Create a simple editor plugin with dock panel" `
                -PackId "godot" `
                -Category "codegen" `
                -Difficulty "hard" `
                -Query "Create a complete Godot editor plugin in GDScript that adds a dock panel with a button. Include the plugin.cfg, plugin.gd, and the dock scene." `
                -ExpectedResult @{
                    hasPluginCfg = $true
                    extendsEditorPlugin = $true
                    hasEnterMethod = $true
                    hasExitMethod = $true
                    addsDockPanel = $true
                    handlesHasMainScreen = $true
                } `
                -RequiredEvidence @(
                    @{ source = "godot-editor-plugin"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("extendsEditorPlugin", "hasEnterMethod", "addsDockPanel")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("codegen", "editor", "plugin", "dock")
            ),

            # Task 8: Shader Material Setup
            (New-GoldenTask `
                -TaskId "gt-godot-008" `
                -Name "Shader material setup" `
                -Description "Create a custom shader with uniforms and visual effects" `
                -PackId "godot" `
                -Category "codegen" `
                -Difficulty "medium" `
                -Query "Write a Godot shader that creates a pulsing glow effect using TIME uniform. The shader should have a color uniform and work with CanvasItem." `
                -ExpectedResult @{
                    shaderTypeCanvasItem = $true
                    usesTimeUniform = $true
                    hasColorUniform = $true
                    createsPulsingEffect = $true
                    usesProperSyntax = $true
                } `
                -RequiredEvidence @(
                    @{ source = "godot-shaders"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("shaderTypeCanvasItem", "usesTimeUniform", "createsPulsingEffect")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("codegen", "shader", "visual", "gdshader")
            ),

            # Task 9: Input Action Mapping
            (New-GoldenTask `
                -TaskId "gt-godot-009" `
                -Name "Input action mapping" `
                -Description "Handle input actions with InputMap and remapping" `
                -PackId "godot" `
                -Category "codegen" `
                -Difficulty "medium" `
                -Query "Show how to check for input actions in _process(), and how to programmatically add a new action with keyboard and joypad mappings." `
                -ExpectedResult @{
                    usesIsActionPressed = $true
                    usesInputMapAddAction = $true
                    addsKeyboardEvent = $true
                    addsJoypadEvent = $true
                    explainsInputMapAPI = $true
                } `
                -RequiredEvidence @(
                    @{ source = "godot-input"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("usesIsActionPressed", "usesInputMapAddAction")
                    forbiddenPatterns = @("Input.is_key_pressed")
                    minConfidence = 0.8
                } `
                -Tags @("codegen", "input", "inputmap", "controls")
            ),

            # Task 10: Multiplayer Networking Pattern
            (New-GoldenTask `
                -TaskId "gt-godot-010" `
                -Name "Multiplayer networking pattern" `
                -Description "Implement basic multiplayer with MultiplayerAPI and RPCs" `
                -PackId "godot" `
                -Category "codegen" `
                -Difficulty "hard" `
                -Query "Create a simple multiplayer script using Godot's MultiplayerAPI with @rpc annotation. Include server creation and client connection code." `
                -ExpectedResult @{
                    usesRPCAnnotation = $true
                    usesMultiplayerAPI = $true
                    createsServer = $true
                    connectsClient = $true
                    handlesMultiplayerAuthority = $true
                } `
                -RequiredEvidence @(
                    @{ source = "godot-multiplayer"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("usesRPCAnnotation", "usesMultiplayerAPI")
                    forbiddenPatterns = @("NetworkedMultiplayerENet")
                    minConfidence = 0.75
                } `
                -Tags @("codegen", "multiplayer", "networking", "rpc")
            )
    )
}
