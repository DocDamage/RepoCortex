#requires -Version 5.1
Set-StrictMode -Version Latest

function Get-GoldenTaskScore {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackId,

        [Parameter(Mandatory = $false)]
        [ValidateSet('24h', '7d', '30d', '90d', 'all')]
        [string]$TimeRange = '7d',

        [Parameter(Mandatory = $false)]
        [string]$Category = '',

        [Parameter(Mandatory = $false)]
        [string]$Difficulty = '',

        [Parameter(Mandatory = $false)]
        [string]$ProjectRoot = '.'
    )

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
    $results = Get-GoldenTaskResults -PackId $PackId -FromDate $cutoff

    # Apply filters
    if ($Category) {
        $results = $results | Where-Object { $_.Task.Category -eq $Category }
    }
    if ($Difficulty) {
        $results = $results | Where-Object { $_.Task.Difficulty -eq $Difficulty }
    }

    # Calculate latest result per task
    $latestResults = @{}
    foreach ($result in $results) {
        $taskId = $result.Task.TaskId
        if (-not $latestResults.ContainsKey($taskId) -or 
            $result.Timing.CompletedAt -gt $latestResults[$taskId].Timing.CompletedAt) {
            $latestResults[$taskId] = $result
        }
    }

    $evaluatedResults = $latestResults.Values

    if ($evaluatedResults.Count -eq 0) {
        return @{
            PackId = $PackId
            TimeRange = $TimeRange
            PassRate = 0
            AverageConfidence = 0
            TotalTasks = 0
            PassedTasks = 0
            FailedTasks = 0
            Score = 0
            Grade = 'N/A'
            Timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        }
    }

    $passed = ($evaluatedResults | Where-Object { $_.Validation.Success }).Count
    $failed = $evaluatedResults.Count - $passed
    $passRate = [math]::Round(($passed / $evaluatedResults.Count) * 100, 2)

    $avgConfidence = 0
    $confidenceSum = 0
    foreach ($result in $evaluatedResults) {
        if ($result.Validation -and $result.Validation.Confidence) {
            $confidenceSum += $result.Validation.Confidence
        }
    }
    $avgConfidence = [math]::Round($confidenceSum / $evaluatedResults.Count, 4)

    # Calculate overall score (weighted average of pass rate and confidence)
    $score = [math]::Round(($passRate * 0.6) + ($avgConfidence * 100 * 0.4), 2)

    # Determine grade
    $grade = switch ($score) {
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
        PassRate = $passRate
        AverageConfidence = $avgConfidence
        TotalTasks = $evaluatedResults.Count
        PassedTasks = $passed
        FailedTasks = $failed
        Score = $score
        Grade = $grade
        Timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        TaskBreakdown = @{
            Easy = ($evaluatedResults | Where-Object { $_.Task.Difficulty -eq 'easy' }).Count
            Medium = ($evaluatedResults | Where-Object { $_.Task.Difficulty -eq 'medium' }).Count
            Hard = ($evaluatedResults | Where-Object { $_.Task.Difficulty -eq 'hard' }).Count
        }
    }
}
