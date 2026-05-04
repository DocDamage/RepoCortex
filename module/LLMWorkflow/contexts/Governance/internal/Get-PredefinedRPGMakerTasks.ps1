#requires -Version 5.1
Set-StrictMode -Version Latest

function Get-PredefinedRPGMakerTasks {
    [CmdletBinding()]
    [OutputType([array])]
    param()

    return @(
            # Task 1: Plugin Skeleton Generation
            (New-GoldenTask `
                -TaskId "gt-rpgmaker-mz-001" `
                -Name "Plugin skeleton generation" `
                -Description "Generate minimal plugin skeleton with one command and one parameter" `
                -PackId "rpgmaker-mz" `
                -Category "codegen" `
                -Difficulty "easy" `
                -Query "Generate a plugin skeleton with one command called 'HealAll' that takes a 'percent' parameter" `
                -ExpectedResult @{
                    containsCommand = "HealAll"
                    containsParameter = "percent"
                    hasJSDocHeader = $true
                    hasPluginCommandRegistration = $true
                } `
                -RequiredEvidence @(
                    @{ source = "rpgmaker-mz-core"; type = "plugin-pattern" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("containsCommand", "containsParameter")
                    forbiddenPatterns = @("eval\s*\(", "Function\s*\(")
                    minConfidence = 0.8
                } `
                -Tags @("codegen", "plugin", "skeleton", "javascript")
            ),

            # Task 2: Plugin Conflict Diagnosis
            (New-GoldenTask `
                -TaskId "gt-rpgmaker-mz-002" `
                -Name "Plugin conflict diagnosis" `
                -Description "Diagnose whether two plugins conflict and cite touched methods" `
                -PackId "rpgmaker-mz" `
                -Category "diagnosis" `
                -Difficulty "medium" `
                -Query "Analyze whether VisuStella's Battle Core conflicts with Yanfly's Buff States Core. List any method overlaps and potential conflicts." `
                -ExpectedResult @{
                    analyzesConflict = $true
                    citesMethods = $true
                    providesResolution = $true
                    mentionsLoadOrder = $true
                } `
                -RequiredEvidence @(
                    @{ source = "plugin-compatibility"; type = "method-citation" }
                    @{ source = "battle-core"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("analyzesConflict", "citesMethods")
                    forbiddenPatterns = @()
                    minConfidence = 0.75
                } `
                -Tags @("diagnosis", "conflict", "compatibility", "analysis")
            ),

            # Task 3: Notetag Extraction
            (New-GoldenTask `
                -TaskId "gt-rpgmaker-mz-003" `
                -Name "Notetag extraction from source" `
                -Description "Extract all notetags from a source repository" `
                -PackId "rpgmaker-mz" `
                -Category "extraction" `
                -Difficulty "easy" `
                -Query "Extract all notetags used in the rpg_core.js file and categorize them by type (actor, item, skill, etc.)" `
                -ExpectedResult @{
                    extractsNotetags = $true
                    categorizesByType = $true
                    providesExamples = $true
                    hasValidRegexPatterns = $true
                } `
                -RequiredEvidence @(
                    @{ source = "rpg_core.js"; type = "notetag" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("extractsNotetags", "categorizesByType")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("extraction", "notetag", "parsing", "documentation")
            ),

            # Task 4: Engine Surface Patch Analysis
            (New-GoldenTask `
                -TaskId "gt-rpgmaker-mz-004" `
                -Name "Engine surface patch analysis" `
                -Description "Analyze how a project-local plugin patches a specific engine surface" `
                -PackId "rpgmaker-mz" `
                -Category "analysis" `
                -Difficulty "hard" `
                -Query "Explain how a local plugin that overrides Game_Actor.prototype.paramPlus patches the engine's parameter calculation surface. Include the method chain affected." `
                -ExpectedResult @{
                    identifiesMethodChain = $true
                    explainsPatchMechanism = $true
                    mentionsAliasPattern = $true
                    showsOriginalVsPatched = $true
                } `
                -RequiredEvidence @(
                    @{ source = "Game_Actor"; type = "method-citation" }
                    @{ source = "paramPlus"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("identifiesMethodChain", "explainsPatchMechanism", "mentionsAliasPattern")
                    forbiddenPatterns = @()
                    minConfidence = 0.85
                } `
                -Tags @("analysis", "patching", "prototype", "alias", "advanced")
            ),

            # Task 5: Command Alias Detection
            (New-GoldenTask `
                -TaskId "gt-rpgmaker-mz-005" `
                -Name "Command alias detection" `
                -Description "Detect and explain command aliases used in plugin development" `
                -PackId "rpgmaker-mz" `
                -Category "analysis" `
                -Difficulty "medium" `
                -Query "What are the common command aliases used in RPG Maker MZ plugins? Explain how PluginManager.registerCommand relates to alias patterns." `
                -ExpectedResult @{
                    identifiesAliases = $true
                    explainsRegisterCommand = $true
                    providesExamples = $true
                    mentionsArguments = $true
                } `
                -RequiredEvidence @(
                    @{ source = "PluginManager"; type = "method-citation" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("identifiesAliases", "explainsRegisterCommand")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("analysis", "alias", "command", "plugin-manager")
            ),

            # Task 6: Plugin Parameter Validation
            (New-GoldenTask `
                -TaskId "gt-rpgmaker-mz-006" `
                -Name "Plugin parameter validation" `
                -Description "Validate and parse plugin parameters with type checking" `
                -PackId "rpgmaker-mz" `
                -Category "codegen" `
                -Difficulty "medium" `
                -Query "Write code to parse and validate plugin parameters including number, string, boolean, and struct types with proper defaults." `
                -ExpectedResult @{
                    handlesNumberParams = $true
                    handlesBooleanParams = $true
                    handlesStringParams = $true
                    handlesStructParams = $true
                    providesDefaults = $true
                    usesPluginManager = $true
                } `
                -RequiredEvidence @(
                    @{ source = "PluginManager"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("handlesNumberParams", "handlesBooleanParams", "providesDefaults")
                    forbiddenPatterns = @("eval\s*\(")
                    minConfidence = 0.8
                } `
                -Tags @("codegen", "parameters", "validation", "parsing")
            ),

            # Task 7: Event Script Conversion
            (New-GoldenTask `
                -TaskId "gt-rpgmaker-mz-007" `
                -Name "Event script conversion" `
                -Description "Convert event commands to equivalent script calls" `
                -PackId "rpgmaker-mz" `
                -Category "codegen" `
                -Difficulty "medium" `
                -Query "Convert the event command 'Change Gold +100' to its equivalent JavaScript code using `$gameParty.gainGold()" `
                -ExpectedResult @{
                    usesCorrectMethod = $true
                    usesCorrectAmount = $true
                    explainsEventCommand = $true
                    providesAlternative = $true
                } `
                -RequiredEvidence @(
                    @{ source = "Game_Party"; type = "method-citation" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("usesCorrectMethod", "explainsEventCommand")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("codegen", "event", "script-call", "conversion")
            ),

            # Task 8: Animation Sequence Generation
            (New-GoldenTask `
                -TaskId "gt-rpgmaker-mz-008" `
                -Name "Animation sequence generation" `
                -Description "Generate animation sequences using Action Sequence patterns" `
                -PackId "rpgmaker-mz" `
                -Category "codegen" `
                -Difficulty "hard" `
                -Query "Create an action sequence that makes the user step forward, perform an attack animation, shake the screen, and return to base position." `
                -ExpectedResult @{
                    hasStepForward = $true
                    hasAttackMotion = $true
                    hasScreenShake = $true
                    hasReturnMotion = $true
                    usesCorrectSyntax = $true
                } `
                -RequiredEvidence @(
                    @{ source = "action-sequence"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("hasStepForward", "hasAttackMotion", "hasReturnMotion")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("codegen", "animation", "action-sequence", "battle")
            ),

            # Task 9: Save System Customization
            (New-GoldenTask `
                -TaskId "gt-rpgmaker-mz-009" `
                -Name "Save system customization" `
                -Description "Add custom data to the save file system" `
                -PackId "rpgmaker-mz" `
                -Category "codegen" `
                -Difficulty "hard" `
                -Query "Show how to add custom data to save files by extending DataManager and hooking into makeSaveContents and extractSaveContents." `
                -ExpectedResult @{
                    extendsDataManager = $true
                    overridesMakeSaveContents = $true
                    overridesExtractSaveContents = $true
                    preservesExistingData = $true
                    usesAliasPattern = $true
                } `
                -RequiredEvidence @(
                    @{ source = "DataManager"; type = "method-citation" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("extendsDataManager", "overridesMakeSaveContents", "usesAliasPattern")
                    forbiddenPatterns = @("eval\s*\(")
                    minConfidence = 0.85
                } `
                -Tags @("codegen", "save-system", "data-manager", "advanced")
            ),

            # Task 10: Menu Scene Extension
            (New-GoldenTask `
                -TaskId "gt-rpgmaker-mz-010" `
                -Name "Menu scene extension" `
                -Description "Extend the main menu with custom commands" `
                -PackId "rpgmaker-mz" `
                -Category "codegen" `
                -Difficulty "medium" `
                -Query "Add a custom 'Bestiary' command to the main menu that opens a custom scene. Include the Scene_Menu modification." `
                -ExpectedResult @{
                    addsMenuCommand = $true
                    createsCustomScene = $true
                    handlesWindowCommand = $true
                    integratesWithSceneMenu = $true
                } `
                -RequiredEvidence @(
                    @{ source = "Scene_Menu"; type = "source-reference" }
                    @{ source = "Window_MenuCommand"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("addsMenuCommand", "createsCustomScene", "integratesWithSceneMenu")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("codegen", "menu", "scene", "window")
            )
    )
}
