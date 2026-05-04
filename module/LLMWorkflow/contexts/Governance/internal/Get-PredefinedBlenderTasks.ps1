#requires -Version 5.1
Set-StrictMode -Version Latest

function Get-PredefinedBlenderTasks {
    [CmdletBinding()]
    [OutputType([array])]
    param()

    return @(
            # Task 1: Operator Registration
            (New-GoldenTask `
                -TaskId "gt-blender-001" `
                -Name "Operator registration" `
                -Description "Create a Blender operator with proper registration" `
                -PackId "blender" `
                -Category "codegen" `
                -Difficulty "easy" `
                -Query "Create a Blender Python operator that scales selected objects by a factor property, with proper bl_idname, bl_label, and registration" `
                -ExpectedResult @{
                    hasBlIdname = $true
                    hasBlLabel = $true
                    hasExecuteMethod = $true
                    hasScaleFactorProperty = $true
                    includesRegistration = $true
                } `
                -RequiredEvidence @(
                    @{ source = "blender-api"; type = "bpy-pattern" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("hasBlIdname", "hasExecuteMethod", "includesRegistration")
                    forbiddenPatterns = @("class.*\\(.*Operator\\):", "^def.*execute")
                    minConfidence = 0.8
                } `
                -Tags @("codegen", "operator", "addon", "python")
            ),

            # Task 2: Geometry Nodes Setup
            (New-GoldenTask `
                -TaskId "gt-blender-002" `
                -Name "Geometry nodes code generation" `
                -Description "Generate geometry nodes setup using Python API" `
                -PackId "blender" `
                -Category "codegen" `
                -Difficulty "medium" `
                -Query "Write Python code to create a geometry nodes modifier that adds a subdivision surface followed by a set position node with random offset" `
                -ExpectedResult @{
                    createsModifier = $true
                    addsSubdivisionNode = $true
                    addsSetPositionNode = $true
                    usesNodesNew = $true
                    linksNodes = $true
                } `
                -RequiredEvidence @(
                    @{ source = "blender-geometry-nodes"; type = "bpy-pattern" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("createsModifier", "addsSubdivisionNode", "usesNodesNew")
                    forbiddenPatterns = @()
                    minConfidence = 0.75
                } `
                -Tags @("codegen", "geometry-nodes", "modifier", "procedural")
            ),

            # Task 3: Addon Manifest
            (New-GoldenTask `
                -TaskId "gt-blender-003" `
                -Name "Addon manifest creation" `
                -Description "Create a complete Blender addon manifest with bl_info" `
                -PackId "blender" `
                -Category "codegen" `
                -Difficulty "easy" `
                -Query "Create a complete Blender addon __init__.py with bl_info dictionary, including name, author, version, blender version, location, description, and category" `
                -ExpectedResult @{
                    hasBlInfo = $true
                    hasNameField = $true
                    hasAuthorField = $true
                    hasVersionTuple = $true
                    hasBlenderVersion = $true
                    hasCategory = $true
                    hasRegistrationFunctions = $true
                } `
                -RequiredEvidence @(
                    @{ source = "blender-addon"; type = "bpy-pattern" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("hasBlInfo", "hasVersionTuple", "hasRegistrationFunctions")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("codegen", "addon", "manifest", "bl_info")
            ),

            # Task 4: Panel Layout Design
            (New-GoldenTask `
                -TaskId "gt-blender-004" `
                -Name "Panel layout design" `
                -Description "Create a custom panel with organized UI layout" `
                -PackId "blender" `
                -Category "codegen" `
                -Difficulty "medium" `
                -Query "Create a Blender panel with a box layout containing properties, a row with aligned buttons, and a column with an enum dropdown. Include proper bl_space_type and bl_region_type." `
                -ExpectedResult @{
                    extendsPanel = $true
                    hasBoxLayout = $true
                    hasRowLayout = $true
                    hasColumnLayout = $true
                    usesProperSpaceType = $true
                    includesDrawMethod = $true
                } `
                -RequiredEvidence @(
                    @{ source = "blender-ui"; type = "bpy-pattern" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("extendsPanel", "includesDrawMethod", "usesProperSpaceType")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("codegen", "panel", "ui", "layout")
            ),

            # Task 5: Property Group Definition
            (New-GoldenTask `
                -TaskId "gt-blender-005" `
                -Name "Property group definition" `
                -Description "Define custom property types with PropertyGroup" `
                -PackId "blender" `
                -Category "codegen" `
                -Difficulty "medium" `
                -Query "Create a PropertyGroup with StringProperty, IntProperty, FloatProperty, BoolProperty, EnumProperty, and PointerProperty. Show how to register it to Scene." `
                -ExpectedResult @{
                    extendsPropertyGroup = $true
                    hasStringProperty = $true
                    hasFloatProperty = $true
                    hasEnumProperty = $true
                    registersToScene = $true
                } `
                -RequiredEvidence @(
                    @{ source = "blender-properties"; type = "bpy-pattern" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("extendsPropertyGroup", "registersToScene")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("codegen", "properties", "property-group", "types")
            ),

            # Task 6: Material Node Setup
            (New-GoldenTask `
                -TaskId "gt-blender-006" `
                -Name "Material node setup" `
                -Description "Create material with nodes using Python API" `
                -PackId "blender" `
                -Category "codegen" `
                -Difficulty "medium" `
                -Query "Write Python code to create a Principled BSDF material, add a noise texture to the base color, and link the nodes properly. Use material.use_nodes = True." `
                -ExpectedResult @{
                    enablesUseNodes = $true
                    createsPrincipledBSDF = $true
                    addsNoiseTexture = $true
                    linksNodes = $true
                    setsOutput = $true
                } `
                -RequiredEvidence @(
                    @{ source = "blender-materials"; type = "bpy-pattern" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("enablesUseNodes", "createsPrincipledBSDF", "linksNodes")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("codegen", "materials", "nodes", "shading")
            ),

            # Task 7: Rigging Automation
            (New-GoldenTask `
                -TaskId "gt-blender-007" `
                -Name "Rigging automation" `
                -Description "Automate bone creation and constraints" `
                -PackId "blender" `
                -Category "codegen" `
                -Difficulty "hard" `
                -Query "Write a Python script that creates an armature with three connected bones (hip, knee, ankle), adds an Inverse Kinematics constraint to the ankle, and sets up proper parenting." `
                -ExpectedResult @{
                    createsArmature = $true
                    editsBones = $true
                    createsConnectedChain = $true
                    addsIKConstraint = $true
                    setsBoneHierarchy = $true
                } `
                -RequiredEvidence @(
                    @{ source = "blender-armature"; type = "bpy-pattern" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("createsArmature", "editsBones", "addsIKConstraint")
                    forbiddenPatterns = @()
                    minConfidence = 0.75
                } `
                -Tags @("codegen", "rigging", "armature", "constraints")
            ),

            # Task 8: Render Pipeline Configuration
            (New-GoldenTask `
                -TaskId "gt-blender-008" `
                -Name "Render pipeline configuration" `
                -Description "Configure render settings programmatically" `
                -PackId "blender" `
                -Category "codegen" `
                -Difficulty "medium" `
                -Query "Set up Blender render settings using Python: enable cycles, set samples to 128, set resolution to 1920x1080 at 100%, enable denoising, and set output format to PNG." `
                -ExpectedResult @{
                    setsEngineCycles = $true
                    setsSamples = $true
                    setsResolution = $true
                    enablesDenoising = $true
                    setsOutputFormat = $true
                } `
                -RequiredEvidence @(
                    @{ source = "blender-render"; type = "bpy-pattern" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("setsEngineCycles", "setsSamples", "setsResolution")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("codegen", "render", "cycles", "settings")
            ),

            # Task 9: Import/Export Operator
            (New-GoldenTask `
                -TaskId "gt-blender-009" `
                -Name "Import/export operator" `
                -Description "Create custom import/export operator with file selector" `
                -PackId "blender" `
                -Category "codegen" `
                -Difficulty "hard" `
                -Query "Create a Blender operator that exports selected mesh objects to a custom JSON format. Include a file selector with .json filter and iterate through mesh data." `
                -ExpectedResult @{
                    extendsOperator = $true
                    hasFilepathProperty = $true
                    usesFilterGlob = $true
                    iteratesSelected = $true
                    exportsMeshData = $true
                } `
                -RequiredEvidence @(
                    @{ source = "blender-io"; type = "bpy-pattern" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("extendsOperator", "hasFilepathProperty", "exportsMeshData")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("codegen", "import-export", "file-io", "mesh")
            ),

            # Task 10: Custom Keymap Binding
            (New-GoldenTask `
                -TaskId "gt-blender-010" `
                -Name "Custom keymap binding" `
                -Description "Add custom hotkeys and keymap entries" `
                -PackId "blender" `
                -Category "codegen" `
                -Difficulty "medium" `
                -Query "Show how to add a custom keymap entry in Blender Python that calls an operator when pressing Ctrl+Shift+T in the 3D viewport. Include addon registration code." `
                -ExpectedResult @{
                    accessesKeymaps = $true
                    addsKeymapItem = $true
                    setsKeyConfig = $true
                    usesCorrectModifier = $true
                    registersWithAddon = $true
                } `
                -RequiredEvidence @(
                    @{ source = "blender-keymap"; type = "bpy-pattern" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("accessesKeymaps", "addsKeymapItem", "registersWithAddon")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("codegen", "keymap", "hotkey", "shortcut")
            )
    )
}
