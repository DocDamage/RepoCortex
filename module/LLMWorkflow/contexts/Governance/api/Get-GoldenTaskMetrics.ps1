#requires -Version 5.1
Set-StrictMode -Version Latest

function Get-GoldenTaskMetrics {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackId,

        [Parameter(Mandatory = $false)]
        [string]$TaskId,

        [Parameter(Mandatory = $false)]
        [ValidateSet('24h', '7d', '30d', '90d', 'all')]
        [string]$TimeRange = '7d',

        [Parameter(Mandatory = $false)]
        [string]$Category = '',

        [Parameter(Mandatory = $false)]
        [string]$Difficulty = '',

        [Parameter(Mandatory = $false)]
        [switch]$CompareToPrevious
    )

    begin {
        Write-Verbose "Calculating golden task metrics for pack: $PackId"
    }

    process {
        # Calculate cutoff date
        $cutoff = switch ($TimeRange) {
            '24h' { (Get-Date).AddHours(-24) }
            '7d' { (Get-Date).AddDays(-7) }
            '30d' { (Get-Date).AddDays(-30) }
            '90d' { (Get-Date).AddDays(-90) }
            'all' { [DateTime]::MinValue }
            default { (Get-Date).AddDays(-7) }
        }

        # Get results
        $params = @{ PackId = $PackId; FromDate = $cutoff }
        if ($TaskId) { $params['TaskId'] = $TaskId }
        $results = Get-GoldenTaskResults @params

        # Apply filters
        if ($Category) {
            $results = $results | Where-Object { $_.Task.Category -eq $Category }
        }
        if ($Difficulty) {
            $results = $results | Where-Object { $_.Task.Difficulty -eq $Difficulty }
        }

        if ($results.Count -eq 0) {
            return @{
                PackId = $PackId
                TimeRange = $TimeRange
                Summary = @{
                    TotalTasks = 0
                    PassedTasks = 0
                    FailedTasks = 0
                    PassRate = 0
                    AverageConfidence = 0
                    Score = 0
                    Grade = 'N/A'
                }
                Breakdowns = @{}
                Trends = @{}
                Regression = @{ RegressionDetected = $false }
                Timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
            }
        }

        # Get latest result per task
        $latestResults = @{}
        foreach ($result in $results) {
            $tid = $result.Task.TaskId
            if (-not $latestResults.ContainsKey($tid) -or 
                $result.Timing.CompletedAt -gt $latestResults[$tid].Timing.CompletedAt) {
                $latestResults[$tid] = $result
            }
        }
        $evaluatedResults = $latestResults.Values

        # Summary metrics
        $passed = ($evaluatedResults | Where-Object { $_.Validation.Success }).Count
        $failed = $evaluatedResults.Count - $passed
        $passRate = if ($evaluatedResults.Count -gt 0) { ($passed / $evaluatedResults.Count) * 100 } else { 0 }
        
        $confidenceValues = $evaluatedResults | ForEach-Object { $_.Validation.Confidence }
        $avgConfidence = if ($confidenceValues.Count -gt 0) { 
            ($confidenceValues | Measure-Object -Average).Average 
        } else { 0 }

        # Calculate weighted score
        $difficultyWeights = @{ easy = 1.0; medium = 1.5; hard = 2.0 }
        $weightedScore = 0
        $totalWeight = 0
        foreach ($result in $evaluatedResults) {
            $weight = $difficultyWeights[$result.Task.Difficulty]
            if ($result.Validation.Success) {
                $weightedScore += $weight * $result.Validation.Confidence * 100
            }
            $totalWeight += $weight
        }
        $finalScore = if ($totalWeight -gt 0) { ($weightedScore / $totalWeight) } else { 0 }

        # Category breakdown
        $categoryBreakdown = @{}
        foreach ($cat in ($evaluatedResults | Select-Object -ExpandProperty Task | Select-Object -ExpandProperty Category -Unique)) {
            $catResults = $evaluatedResults | Where-Object { $_.Task.Category -eq $cat }
            $catPassed = ($catResults | Where-Object { $_.Validation.Success }).Count
            $categoryBreakdown[$cat] = @{
                Total = $catResults.Count
                Passed = $catPassed
                Failed = $catResults.Count - $catPassed
                PassRate = if ($catResults.Count -gt 0) { ($catPassed / $catResults.Count) * 100 } else { 0 }
            }
        }

        # Difficulty breakdown
        $difficultyBreakdown = @{}
        foreach ($diff in ($evaluatedResults | Select-Object -ExpandProperty Task | Select-Object -ExpandProperty Difficulty -Unique)) {
            $diffResults = $evaluatedResults | Where-Object { $_.Task.Difficulty -eq $diff }
            $diffPassed = ($diffResults | Where-Object { $_.Validation.Success }).Count
            $difficultyBreakdown[$diff] = @{
                Total = $diffResults.Count
                Passed = $diffPassed
                Failed = $diffResults.Count - $diffPassed
                PassRate = if ($diffResults.Count -gt 0) { ($diffPassed / $diffResults.Count) * 100 } else { 0 }
            }
        }

        # Tag breakdown
        $tagBreakdown = @{}
        foreach ($result in $evaluatedResults) {
            foreach ($tag in $result.Task.Tags) {
                if (-not $tagBreakdown.ContainsKey($tag)) {
                    $tagBreakdown[$tag] = @{ Total = 0; Passed = 0; Failed = 0 }
                }
                $tagBreakdown[$tag].Total++
                if ($result.Validation.Success) {
                    $tagBreakdown[$tag].Passed++
                } else {
                    $tagBreakdown[$tag].Failed++
                }
            }
        }
        foreach ($tag in $tagBreakdown.Keys) {
            $tagBreakdown[$tag].PassRate = if ($tagBreakdown[$tag].Total -gt 0) { 
                ($tagBreakdown[$tag].Passed / $tagBreakdown[$tag].Total) * 100 
            } else { 0 }
        }

        # Trend analysis (if multiple results per task)
        $trends = @{
            Improving = @()
            Declining = @()
            Stable = @()
        }
        if ($CompareToPrevious) {
            $previousCutoff = $cutoff.AddDays(-($cutoff - [DateTime]::MinValue).Days / 2)
            $previousParams = @{ PackId = $PackId; FromDate = $previousCutoff; ToDate = $cutoff }
            if ($TaskId) { $previousParams['TaskId'] = $TaskId }
            $previousResults = Get-GoldenTaskResults @previousParams

            foreach ($taskId in $latestResults.Keys) {
                $current = $latestResults[$taskId]
                $previous = $previousResults | Where-Object { $_.Task.TaskId -eq $taskId } | 
                    Sort-Object { $_.Timing.CompletedAt } -Descending | Select-Object -First 1

                if ($previous) {
                    $currentSuccess = $current.Validation.Success
                    $previousSuccess = $previous.Validation.Success
                    $currentConf = $current.Validation.Confidence
                    $previousConf = $previous.Validation.Confidence

                    if ($currentSuccess -and -not $previousSuccess) {
                        $trends.Improving += $taskId
                    } elseif (-not $currentSuccess -and $previousSuccess) {
                        $trends.Declining += $taskId
                    } elseif ([Math]::Abs($currentConf - $previousConf) -lt 0.05) {
                        $trends.Stable += $taskId
                    } elseif ($currentConf -gt $previousConf) {
                        $trends.Improving += $taskId
                    } else {
                        $trends.Declining += $taskId
                    }
                }
            }
        }

        # Regression detection
        $regression = @{
            RegressionDetected = $trends.Declining.Count -gt 0
            NewFailures = $trends.Declining
            TasksBelowThreshold = @()
            ConfidenceDrops = @()
        }

        foreach ($result in $evaluatedResults) {
            if (-not $result.Validation.Success -or 
                $result.Validation.Confidence -lt $result.Validation.MinConfidenceRequired) {
                $regression.TasksBelowThreshold += @{
                    TaskId = $result.Task.TaskId
                    Confidence = $result.Validation.Confidence
                    Required = $result.Validation.MinConfidenceRequired
                }
            }
        }

        # Determine grade
        $grade = switch ($finalScore) {
            { $_ -ge 95 } { 'A+' }
            { $_ -ge 90 } { 'A' }
            { $_ -ge 85 } { 'B+' }
            { $_ -ge 80 } { 'B' }
            { $_ -ge 70 } { 'C' }
            { $_ -ge 60 } { 'D' }
            default { 'F' }
        }

        return @{
            PackId = $PackId
            TimeRange = $TimeRange
            Summary = @{
                TotalTasks = $evaluatedResults.Count
                PassedTasks = $passed
                FailedTasks = $failed
                PassRate = [math]::Round($passRate, 2)
                AverageConfidence = [math]::Round($avgConfidence, 4)
                WeightedScore = [math]::Round($finalScore, 2)
                Grade = $grade
            }
            Breakdowns = @{
                ByCategory = $categoryBreakdown
                ByDifficulty = $difficultyBreakdown
                ByTag = $tagBreakdown
            }
            Trends = $trends
            Regression = $regression
            Timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        }
    }
}
