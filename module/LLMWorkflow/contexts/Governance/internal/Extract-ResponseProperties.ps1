#requires -Version 5.1
Set-StrictMode -Version Latest

function Extract-ResponseProperties {
    param(
        [hashtable]$Response,
        [hashtable]$Task
    )

    $properties = @{}
    $content = $Response.content

    switch ($Task.category) {
        'codegen' {
            $properties['hasJSDocHeader'] = $content -match '/\*\*[\s\S]*?\*/'
            $properties['hasPluginCommandRegistration'] = $content -match 'PluginManager\.(registerCommand|commands)'

            $taskExp = $Task.expectedResult
            $properties['containsCommand'] = if ($taskExp.ContainsKey('containsCommand') -and $taskExp.containsCommand) { $content -match [regex]::Escape($taskExp.containsCommand) } else { $false }
            $properties['containsParameter'] = if ($taskExp.ContainsKey('containsParameter') -and $taskExp.containsParameter) { $content -match [regex]::Escape($taskExp.containsParameter) } else { $false }

            $properties['usesGDScriptSyntax'] = $content -match '(extends\s+\w+|func\s+\w+|var\s+\w+|@onready|@export)'
            $properties['hasBlIdname'] = $content -match "bl_idname\s*=\s*['`"']"
            $properties['hasBlLabel'] = $content -match "bl_label\s*=\s*['`"']"
            $properties['hasExecuteMethod'] = $content -match 'def\s+execute\s*\('
            $properties['includesRegistration'] = $content -match '(bpy\.utils\.register_class|register\s*\()'
            $properties['hasClassName'] = if ($taskExp.ContainsKey('hasClassName') -and $taskExp.hasClassName) {
                $content -match "class_name\s+$($taskExp.hasClassName)"
            } else { $false }
            $properties['extendsCharacterBody2D'] = $content -match 'extends\s+CharacterBody2D'
            $properties['hasSpeedProperty'] = $content -match '(export|@export).*speed|var\s+speed'
            $properties['hasPhysicsProcess'] = $content -match '_physics_process'
            $properties['createsGameManager'] = $content -match 'class.*GameManager|GameManager'
            $properties['showsConnectMethod'] = $content -match '\.connect\s*\('
            $properties['showsOnreadyPattern'] = $content -match '@onready'
            $properties['extendsNode2D'] = $content -match 'extends\s+Node2D'
            $properties['implementsDraw'] = $content -match '_draw\s*\('
            $properties['usesToolAnnotation'] = $content -match '@tool'
            $properties['extendsEditorPlugin'] = $content -match 'extends\s+EditorPlugin'
            $properties['hasEnterMethod'] = $content -match '_enter_tree'
            $properties['addsDockPanel'] = $content -match 'add_control_to_dock|make_visible'
            $properties['shaderTypeCanvasItem'] = $content -match 'shader_type\s+canvas_item'
            $properties['usesTimeUniform'] = $content -match 'uniform.*TIME|TIME'
            $properties['extendsPropertyGroup'] = $content -match 'extends\s+PropertyGroup'
            $properties['extendsPanel'] = $content -match 'extends\s+Panel'
            $properties['includesDrawMethod'] = $content -match 'def\s+draw\s*\('
            $properties['extendsOperator'] = $content -match 'extends\s+Operator'
            $properties['enablesUseNodes'] = $content -match 'use_nodes\s*=\s*True'
            $properties['createsPrincipledBSDF'] = $content -match 'Principled BSDF|ShaderNodeBsdfPrincipled'
            $properties['linksNodes'] = $content -match 'links\.new'
        }
        'diagnosis' {
            $properties['analyzesConflict'] = $content -match '(conflict|overlap|incompatible|compatible)'
            $properties['citesMethods'] = $content -match '(\.\w+\s*\(|function\s+\w+|def\s+\w+)'
            $properties['providesResolution'] = $content -match '(solution|workaround|fix|recommend|place.*above|place.*below)'
            $properties['mentionsLoadOrder'] = $content -match '(load.*order|order.*load|placement)'
        }
        'extraction' {
            $properties['extractsNotetags'] = $content -match '(notetag|meta|@type)'
            $properties['categorizesByType'] = $content -match '(actor|item|skill|class|weapon|armor|enemy|state)'
            $properties['providesExamples'] = $content -match '(example|e\.g\.|for instance|such as)'
            $pattern = [regex]::Escape('^ <') + '|' + '<.*?>' + '|' + '\w' + '|' + '\d' + '|' + '\[.+?\]'
            $properties['hasValidRegexPatterns'] = $content -match $pattern
        }
        'analysis' {
            $properties['identifiesMethodChain'] = $content -match '(prototype\.|__proto__|method.*chain|call.*chain)'
            $properties['explainsPatchMechanism'] = $content -match '(alias|override|wrap|patch|replace)'
            $properties['mentionsAliasPattern'] = $content -match '(alias|_alias|_\w+_\w+_alias)'
            $properties['showsOriginalVsPatched'] = $content -match '(original|before|after|vs|versus|compared)'
            $properties['identifiesAliases'] = $content -match '(alias|command.*alias|registerCommand)'
            $properties['explainsRegisterCommand'] = $content -match 'registerCommand|PluginManager'
            $properties['explainsSceneInheritance'] = $content -match '(inheritance|inherited scene|scene.*inherit)'
            $properties['showsBaseScene'] = $content -match 'base.*scene|parent.*scene'
            $properties['showsInheritedScene'] = $content -match 'inherited.*scene|child.*scene'
        }
        default {
            foreach ($key in $Task.expectedResult.Keys) {
                $properties[$key] = $content -match [regex]::Escape($key)
            }
        }
    }

    if ($Task.expectedResult) {
        foreach ($key in $Task.expectedResult.Keys) {
            if (-not $properties.ContainsKey($key)) {
                $expectedVal = $Task.expectedResult[$key]
                if ($expectedVal -is [string]) {
                    $properties[$key] = $content -match [regex]::Escape($expectedVal)
                } else {
                    $properties[$key] = $content -match [regex]::Escape($key)
                }
            }
        }
    }

    return $properties
}
