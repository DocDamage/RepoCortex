#requires -Version 5.1
Set-StrictMode -Version Latest

function Compare-GoldenTaskRuns {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'PackCompare')]
        [string]$PackId,

        [Parameter(Mandatory = $true, ParameterSetName = 'TaskCompare')]
        [string]$TaskId,

        [Parameter(Mandatory = $true)]
        [DateTime]$BaselineRun,

        [Parameter(Mandatory = $false)]
        [DateTime]$ComparisonRun = (Get-Date),

        [Parameter(Mandatory = $false)]
        [double]$Threshold = 0.05,

        [Parameter(Mandatory = $false)]
        [switch]$FailOnRegression
    )

    begin {
        Write-Verbose "Comparing golden task runs"
        Write-Verbose "Baseline: $BaselineRun"
        Write-Verbose "Comparison: $ComparisonRun"
    }

    process {
        try {
            # Get baseline results
            $baselineParams = @{
                FromDate = $BaselineRun.Date
                ToDate = $BaselineRun.Date.AddDays(1)
            }
            if ($PackId) { $baselineParams['PackId'] = $PackId }
            if ($TaskId) { $baselineParams['TaskId'] = $TaskId }
            
            $baselineResults = Get-GoldenTaskResults @baselineParams | 
                Group-Object { $_.Task.TaskId } | 
                ForEach-Object { $_.Group | Sort-Object { $_.Timing.CompletedAt } -Descending | Select-Object -First 1 }

            # Get comparison results
            $comparisonParams = @{
                FromDate = $ComparisonRun.Date.AddDays(-7)
                ToDate = $ComparisonRun
            }
            if ($PackId) { $comparisonParams['PackId'] = $PackId }
            if ($TaskId) { $comparisonParams['TaskId'] = $TaskId }
            
            $comparisonResults = Get-GoldenTaskResults @comparisonParams | 
                Group-Object { $_.Task.TaskId } | 
                ForEach-Object { $_.Group | Sort-Object { $_.Timing.CompletedAt } -Descending | Select-Object -First 1 }

            # Initialize comparison collections
            $regressions = @()
            $improvements = @()
            $stable = @()
            $newTasks = @()
            $missingTasks = @()

            # Create lookup dictionaries
            $baselineLookup = @{}
            foreach ($result in $baselineResults) {
                $baselineLookup[$result.Task.TaskId] = $result
            }

            $comparisonLookup = @{}
            foreach ($result in $comparisonResults) {
                $comparisonLookup[$result.Task.TaskId] = $result
            }

            # Compare all tasks from comparison run
            foreach ($taskId in $comparisonLookup.Keys) {
                $current = $comparisonLookup[$taskId]
                
                if (-not $baselineLookup.ContainsKey($taskId)) {
                    $newTasks += @{
                        TaskId = $taskId
                        TaskName = $current.Task.Name
                        CurrentStatus = if ($current.Validation.Success) { "PASSED" } else { "FAILED" }
                        CurrentConfidence = $current.Validation.Confidence
                    }
                    continue
                }

                $baseline = $baselineLookup[$taskId]
                
                $baselineSuccess = $baseline.Validation.Success
                $currentSuccess = $current.Validation.Success
                $baselineConfidence = $baseline.Validation.Confidence
                $currentConfidence = $current.Validation.Confidence
                $confidenceDelta = $currentConfidence - $baselineConfidence

                $comparisonItem = @{
                    TaskId = $taskId
                    TaskName = $current.Task.Name
                    BaselineStatus = if ($baselineSuccess) { "PASSED" } else { "FAILED" }
                    CurrentStatus = if ($currentSuccess) { "PASSED" } else { "FAILED" }
                    BaselineConfidence = [math]::Round($baselineConfidence, 4)
                    CurrentConfidence = [math]::Round($currentConfidence, 4)
                    ConfidenceDelta = [math]::Round($confidenceDelta, 4)
                    BaselineDuration = $baseline.Timing.DurationSeconds
                    CurrentDuration = $current.Timing.DurationSeconds
                    DurationDelta = [math]::Round($current.Timing.DurationSeconds - $baseline.Timing.DurationSeconds, 2)
                }

                # Detect regression (was passing, now failing)
                if ($baselineSuccess -and -not $currentSuccess) {
                    $comparisonItem.RegressionType = "CRITICAL - Pass to Fail"
                    $regressions += $comparisonItem
                }
                # Detect pass but confidence drop below threshold
                elseif ($baselineSuccess -and $currentSuccess -and $confidenceDelta -lt -$Threshold) {
                    $comparisonItem.RegressionType = "WARNING - Confidence Drop"
                    $regressions += $comparisonItem
                }
                # Detect improvement (was failing, now passing)
                elseif (-not $baselineSuccess -and $currentSuccess) {
                    $comparisonItem.ImprovementType = "RECOVERED - Fail to Pass"
                    $improvements += $comparisonItem
                }
                # Detect confidence improvement above threshold
                elseif ($baselineSuccess -and $currentSuccess -and $confidenceDelta -gt $Threshold) {
                    $comparisonItem.ImprovementType = "ENHANCED - Confidence Gain"
                    $improvements += $comparisonItem
                }
                else {
                    $stable += $comparisonItem
                }
            }

            # Find missing tasks (in baseline but not in current)
            foreach ($taskId in $baselineLookup.Keys) {
                if (-not $comparisonLookup.ContainsKey($taskId)) {
                    $baseline = $baselineLookup[$taskId]
                    $missingTasks += @{
                        TaskId = $taskId
                        TaskName = $baseline.Task.Name
                        BaselineStatus = if ($baseline.Validation.Success) { "PASSED" } else { "FAILED" }
                        BaselineConfidence = $baseline.Validation.Confidence
                    }
                }
            }

            # Calculate statistics
            $totalCompared = $regressions.Count + $improvements.Count + $stable.Count
            $regressionRate = if ($totalCompared -gt 0) { ($regressions.Count / $totalCompared) * 100 } else { 0 }
            $improvementRate = if ($totalCompared -gt 0) { ($improvements.Count / $totalCompared) * 100 } else { 0 }

            # Determine overall status
            $criticalRegressions = ($regressions | Where-Object { $_.RegressionType -eq "CRITICAL - Pass to Fail" }).Count
            $hasRegression = $criticalRegressions -gt 0

            $result = @{
                PackId = $PackId
                TaskId = $TaskId
                BaselineRun = $BaselineRun.ToString("yyyy-MM-ddTHH:mm:ssZ")
                ComparisonRun = $ComparisonRun.ToString("yyyy-MM-ddTHH:mm:ssZ")
                Summary = @{
                    TotalTasksCompared = $totalCompared
                    TotalRegressions = $regressions.Count
                    CriticalRegressions = $criticalRegressions
                    TotalImprovements = $improvements.Count
                    StableTasks = $stable.Count
                    NewTasks = $newTasks.Count
                    MissingTasks = $missingTasks.Count
                    RegressionRate = [math]::Round($regressionRate, 2)
                    ImprovementRate = [math]::Round($improvementRate, 2)
                    HasRegression = $hasRegression
                    Status = if ($hasRegression) { "REGRESSION_DETECTED" } elseif ($improvements.Count -gt 0) { "IMPROVED" } else { "STABLE" }
                }
                Regressions = $regressions
                Improvements = $improvements
                Stable = $stable
                NewTasks = $newTasks
                MissingTasks = $missingTasks
                Threshold = $Threshold
                GeneratedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
            }

            # Output summary
            foreach ($line in @(
                '',
                'Golden Task Run Comparison',
                "  Pack: $PackId$(if($TaskId){" / Task: $TaskId"})",
                "  Baseline: $($result.BaselineRun)",
                "  Comparison: $($result.ComparisonRun)",
                "  Tasks Compared: $($result.Summary.TotalTasksCompared)",
                $(if ($result.Summary.CriticalRegressions -gt 0) { "  CRITICAL REGRESSIONS: $($result.Summary.CriticalRegressions)" }),
                $(if ($result.Summary.TotalRegressions -gt 0) { "  Total Regressions: $($result.Summary.TotalRegressions)" }),
                $(if ($result.Summary.TotalImprovements -gt 0) { "  Improvements: $($result.Summary.TotalImprovements)" }),
                "  Status: $($result.Summary.Status)"
            ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) {
                Write-Information $line -InformationAction Continue
            }

            if ($FailOnRegression -and $hasRegression) {
                Write-Error "Regressions detected in golden task comparison"
            }

            return $result
        }
        catch {
            Write-Error "Failed to compare golden task runs: $_"
            throw
        }
    }
}
