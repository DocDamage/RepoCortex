#requires -Version 5.1
Set-StrictMode -Version Latest

function Test-GoldenTaskResult {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Task,

        [Parameter(Mandatory = $true)]
        [hashtable]$ActualResult,

        [Parameter(Mandatory = $false)]
        [string]$AnswerText = ""
    )

    begin {
        Write-Verbose "Validating golden task result: $($Task.taskId)"
        $validationErrors = @()
        $evidenceFound = @()
        $forbiddenFound = @()
    }

    process {
        # 1. Property-based validation
        $propertyValidation = Test-PropertyBasedExpectation `
            -Expected $Task.expectedResult `
            -Actual $ActualResult

        # 2. Required evidence checking
        $evidenceErrors = @()
        foreach ($evidence in $Task.requiredEvidence) {
            $evidenceFoundFlag = $false
            
            if ($AnswerText) {
                switch ($evidence.type) {
                    'plugin-pattern' {
                        # Look for plugin-related patterns
                        if ($AnswerText -match 'PluginManager\.(register|commands)') {
                            $evidenceFoundFlag = $true
                        }
                    }
                    'source-reference' {
                        # Look for source file references
                        if ($AnswerText -match '\.js|\.gd|\.py') {
                            $evidenceFoundFlag = $true
                        }
                    }
                    'method-citation' {
                        # Look for method citations
                        if ($AnswerText -match '\.[a-zA-Z_]+\s*\(|function\s+\w+|def\s+\w+') {
                            $evidenceFoundFlag = $true
                        }
                    }
                    'notetag' {
                        # Look for notetag patterns
                        if ($AnswerText -match '<[A-Za-z_]+[\w\s]*>') {
                            $evidenceFoundFlag = $true
                        }
                    }
                    'signal-pattern' {
                        # Look for Godot signal patterns
                        if ($AnswerText -match '(signal\s+\w+|emit_signal|connect\s*\()') {
                            $evidenceFoundFlag = $true
                        }
                    }
                    'bpy-pattern' {
                        # Look for Blender bpy patterns
                        if ($AnswerText -match '(bpy\.(ops|context|data)|bl_idname|bl_label)') {
                            $evidenceFoundFlag = $true
                        }
                    }
                    default {
                        # Generic pattern matching
                        if ($evidence -is [hashtable]) {
                            if ($evidence.ContainsKey('pattern') -and $AnswerText -match $evidence.pattern) {
                                $evidenceFoundFlag = $true
                            }
                        }
                        elseif ($evidence.PSObject.Properties['pattern'] -and $AnswerText -match $evidence.pattern) {
                            # Fallback for PSCustomObject or other objects
                            $evidenceFoundFlag = $true
                        }
                    }
                }
            }

            if ($evidenceFoundFlag) {
                $evidenceFound += $evidence
            }
            else {
                $evidenceErrors += "Missing evidence: $($evidence.source) [$($evidence.type)]"
            }
        }

        # 3. Forbidden pattern detection
        $forbiddenPatterns = $Task.validationRules.forbiddenPatterns
        if ($forbiddenPatterns -and $AnswerText) {
            foreach ($pattern in $forbiddenPatterns) {
                if ($AnswerText -match $pattern) {
                    $forbiddenFound += $pattern
                    $validationErrors += "Forbidden pattern detected: $pattern"
                }
            }
        }

        # 4. Evidence requirement validation
        $evidenceSatisfied = $Task.requiredEvidence.Count -eq 0 -or $evidenceErrors.Count -eq 0
        if (-not $evidenceSatisfied) {
            $validationErrors += $evidenceErrors
        }

        # Add property validation errors
        foreach ($failedProp in $propertyValidation.FailedProperties) {
            $propDetails = $propertyValidation.Details[$failedProp]
            $validationErrors += "Property validation failed for '$failedProp': Expected $($propDetails.Expected), got $($propDetails.Actual)"
        }

        # 5. Calculate overall result
        $minConfidence = $Task.validationRules.minConfidence
        $confidenceSufficient = $propertyValidation.Confidence -ge $minConfidence

        $overallSuccess = $propertyValidation.Success -and 
                         $evidenceSatisfied -and 
                         $forbiddenFound.Count -eq 0 -and
                         $confidenceSufficient

        # 6. Build result object
        $result = @{
            TaskId = $Task.taskId
            TaskName = $Task.name
            Success = $overallSuccess
            Confidence = $propertyValidation.Confidence
            MinConfidenceRequired = $minConfidence
            ConfidenceSufficient = $confidenceSufficient
            PropertyValidation = $propertyValidation
            Evidence = @{
                Required = $Task.requiredEvidence
                Found = $evidenceFound
                MissingCount = $Task.requiredEvidence.Count - $evidenceFound.Count
                Satisfied = $evidenceSatisfied
            }
            ForbiddenPatterns = @{
                Patterns = $forbiddenPatterns
                Found = $forbiddenFound
                Violations = $forbiddenFound.Count
            }
            Errors = $validationErrors
            ValidatedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        }

        Write-Verbose "Validation complete for '$($Task.taskId)': Success=$overallSuccess, Confidence=$($propertyValidation.Confidence)"
        return $result
    }
}
