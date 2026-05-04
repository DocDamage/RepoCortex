Set-StrictMode -Version Latest

function Invoke-LLMWorkflowHeal {
    <#
    .SYNOPSIS
        Diagnoses and fixes common LLM Workflow issues automatically.
    .DESCRIPTION
        Performs comprehensive diagnosis of the LLM Workflow environment and 
        offers to automatically fix detected issues. Supports WhatIf mode for
        previewing changes and Force mode for unattended operation.
    .PARAMETER ProjectRoot
        Path to the project root (default: current directory).
    .PARAMETER WhatIf
        Show what would be fixed without making changes.
    .PARAMETER Force
        Auto-apply all fixes without prompting.
    .PARAMETER Interactive
        Show interactive prompts for user input.
    .PARAMETER IncludeInfo
        Include INFO-level issues in diagnosis.
    .PARAMETER OnlyCritical
        Only check and fix CRITICAL issues.
    .PARAMETER IssueTypes
        Specific issue types to check (default: all).
    .EXAMPLE
        Invoke-LLMWorkflowHeal
        Interactive diagnosis with prompts for each fix.
    .EXAMPLE
        llmheal -WhatIf
        Preview what would be fixed without making changes.
    .EXAMPLE
        llmheal -Force
        Auto-apply all fixes without prompting.
    .EXAMPLE
        llmheal -OnlyCritical -Force
        Fix only critical issues automatically.
    .ALIAS
        llmheal
    #>
    [CmdletBinding()]
    param(
        [string]$ProjectRoot = ".",
        [switch]$WhatIf,
        [switch]$Force,
        [switch]$Interactive = $true,
        [switch]$IncludeInfo,
        [switch]$OnlyCritical,
        [IssueType[]]$IssueTypes = @()
    )

    if ($Force) {
        # Force mode is intended for unattended execution; disable interactive prompts.
        $Interactive = $false
    }
    
    # Initialize
    Initialize-HealHistoryStore
    Write-HealLog -Message "Starting heal operation on: $ProjectRoot (WhatIf=$WhatIf, Force=$Force)" -Level "INFO"
    
    $startTime = Get-Date
    $projectPath = Resolve-HealLiteralPath -LiteralPath $ProjectRoot -Context 'Heal invocation project-root resolution'
    
    if (-not $projectPath) {
        Write-Error "Project root does not exist: $ProjectRoot"
        return
    }
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "   LLM Workflow Self-Healing" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Write-Host "Project: $projectPath" -ForegroundColor Gray
    Write-Host "Mode: $(if ($WhatIf) { 'WhatIf (preview only)' } elseif ($Force) { 'Force (auto-apply)' } else { 'Interactive' })" -ForegroundColor Gray
    Write-Host ""
    
    # Determine which issues to check
    $allIssueTypes = @(
        [IssueType]::MissingEnvFile,
        [IssueType]::InvalidPythonPath,
        [IssueType]::MissingChromaDB,
        [IssueType]::MissingPalaceDirectory,
        [IssueType]::CorruptedSyncState,
        [IssueType]::TemplateDrift,
        [IssueType]::MissingContextLatticeApiKey,
        [IssueType]::MissingContextLatticeUrl,
        [IssueType]::MissingBridgeConfig,
        [IssueType]::CorruptedBridgeConfig
    )
    
    if ($IssueTypes.Count -gt 0) {
        $issuesToCheck = $IssueTypes
    } else {
        $issuesToCheck = $allIssueTypes
    }
    
    # Phase 1: Diagnosis
    Write-Host "Phase 1: Diagnosis" -ForegroundColor Yellow
    Write-Host "------------------" -ForegroundColor Yellow
    
    $detectedIssues = @()
    foreach ($issueType in $issuesToCheck) {
        Write-Host "  Checking $($issueType.ToString())... " -NoNewline -ForegroundColor Gray
        $result = Test-LLMWorkflowIssue -IssueType $issueType -ProjectRoot $ProjectRoot
        
        if ($result.Detected) {
            $color = switch ($result.Category) {
                ([IssueCategory]::CRITICAL) { "Red" }
                ([IssueCategory]::WARNING) { "Yellow" }
                ([IssueCategory]::INFO) { "Cyan" }
            }
            $prefix = switch ($result.Category) {
                ([IssueCategory]::CRITICAL) { "[CRITICAL]" }
                ([IssueCategory]::WARNING) { "[WARNING]" }
                ([IssueCategory]::INFO) { "[INFO]" }
            }
            
            if ($result.Category -eq [IssueCategory]::INFO -and -not $IncludeInfo) {
                Write-Host "OK (info skipped)" -ForegroundColor Green
                continue
            }
            
            if ($OnlyCritical -and $result.Category -ne [IssueCategory]::CRITICAL) {
                Write-Host "OK (non-critical skipped)" -ForegroundColor Green
                continue
            }
            
            Write-Host "$prefix $($result.Message)" -ForegroundColor $color
            
            $detectedIssues += [pscustomobject]@{
                IssueType = $issueType
                Category = $result.Category
                Message = $result.Message
                Details = $result.Details
                CanFix = $result.CanFix
                FixDescription = $result.FixDescription
            }
        } else {
            Write-Host "OK" -ForegroundColor Green
        }
    }
    
    Write-Host ""
    
    # Summary of diagnosis
    $criticalCount = @($detectedIssues | Where-Object { $_.Category -eq [IssueCategory]::CRITICAL }).Count
    $warningCount = @($detectedIssues | Where-Object { $_.Category -eq [IssueCategory]::WARNING }).Count
    $infoCount = @($detectedIssues | Where-Object { $_.Category -eq [IssueCategory]::INFO }).Count
    $fixableCount = @($detectedIssues | Where-Object { $_.CanFix }).Count
    
    Write-Host "Diagnosis Summary:" -ForegroundColor Yellow
    Write-Host "  Critical issues: $criticalCount" -ForegroundColor $(if ($criticalCount -gt 0) { "Red" } else { "Green" })
    Write-Host "  Warnings: $warningCount" -ForegroundColor $(if ($warningCount -gt 0) { "Yellow" } else { "Green" })
    Write-Host "  Info: $infoCount" -ForegroundColor Cyan
    Write-Host "  Auto-fixable: $fixableCount" -ForegroundColor $(if ($fixableCount -gt 0) { "Cyan" } else { "Gray" })
    Write-Host ""
    
    if ($detectedIssues.Count -eq 0) {
        Write-Host "No issues detected! Your LLM Workflow environment looks healthy." -ForegroundColor Green
        Write-Host ""
        return [pscustomobject]@{
            Success = $true
            IssuesFound = 0
            IssuesFixed = 0
            Duration = (Get-Date) - $startTime
            Details = @()
        }
    }
    
    # Phase 2: Repair
    Write-Host "Phase 2: Repair" -ForegroundColor Yellow
    Write-Host "---------------" -ForegroundColor Yellow
    Write-Host ""
    
    $repairResults = @()
    $fixedCount = 0
    $failedCount = 0
    $skippedCount = 0
    
    foreach ($issue in $detectedIssues) {
        if (-not $issue.CanFix) {
            Write-Host "[$($issue.Category)] $($issue.IssueType): Cannot auto-fix" -ForegroundColor Gray
            $skippedCount++
            continue
        }
        
        $shouldFix = $Force
        
        if (-not $Force -and $Interactive -and -not $WhatIf) {
            Write-Host ""
            Write-Host "Issue: $($issue.IssueType)" -ForegroundColor $(if ($issue.Category -eq [IssueCategory]::CRITICAL) { "Red" } else { "Yellow" })
            Write-Host "Description: $($issue.Message)" -ForegroundColor Gray
            Write-Host "Proposed fix: $($issue.FixDescription)" -ForegroundColor Cyan
            $response = Read-Host "Apply fix? [Y/n]"
            $shouldFix = ($response -eq "" -or $response -match "^[Yy]")
        }
        
        if ($WhatIf) {
            Write-Host "[WHATIF] Would fix: $($issue.IssueType) - $($issue.FixDescription)" -ForegroundColor Cyan
            $repairResults += [pscustomobject]@{
                IssueType = $issue.IssueType
                Category = $issue.Category
                Status = "WouldFix"
                Message = $issue.FixDescription
                Changes = @()
            }
        } elseif ($shouldFix) {
            Write-Host "  Fixing $($issue.IssueType)... " -NoNewline -ForegroundColor Gray
            
            $repairResult = Repair-LLMWorkflowIssue `
                -IssueType $issue.IssueType `
                -ProjectRoot $ProjectRoot `
                -WhatIf:$WhatIf `
                -Force:$Force `
                -Interactive:$Interactive
            
            if ($repairResult.Success) {
                Write-Host "FIXED" -ForegroundColor Green
                $fixedCount++
            } else {
                Write-Host "FAILED" -ForegroundColor Red
                Write-Host "    $($repairResult.Message)" -ForegroundColor Red
                $failedCount++
            }
            
            $repairResults += [pscustomobject]@{
                IssueType = $issue.IssueType
                Category = $issue.Category
                Status = $(if ($repairResult.Success) { "Fixed" } else { "Failed" })
                Message = $repairResult.Message
                Changes = $repairResult.Changes
            }
        } else {
            Write-Host "  Skipped: $($issue.IssueType)" -ForegroundColor Gray
            $skippedCount++
            $repairResults += [pscustomobject]@{
                IssueType = $issue.IssueType
                Category = $issue.Category
                Status = "Skipped"
                Message = "User declined"
                Changes = @()
            }
        }
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   Repair Summary" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Total issues found: $($detectedIssues.Count)" -ForegroundColor White
    Write-Host "  Fixed: $fixedCount" -ForegroundColor Green
    Write-Host "  Failed: $failedCount" -ForegroundColor $(if ($failedCount -gt 0) { "Red" } else { "Green" })
    Write-Host "  Skipped: $skippedCount" -ForegroundColor Gray
    Write-Host ""
    
    $duration = (Get-Date) - $startTime
    Write-Host "Duration: $($duration.ToString('mm\:ss'))" -ForegroundColor Gray
    Write-Host ""
    
    # Log completion
    Write-HealLog -Message "Heal operation completed. Found: $($detectedIssues.Count), Fixed: $fixedCount, Failed: $failedCount" -Level $(if ($failedCount -eq 0) { "SUCCESS" } else { "WARN" })
    
    # Return result object
    return [pscustomobject]@{
        Success = ($failedCount -eq 0)
        IssuesFound = $detectedIssues.Count
        IssuesFixed = $fixedCount
        IssuesFailed = $failedCount
        IssuesSkipped = $skippedCount
        Duration = $duration
        Details = $repairResults
    }
}


