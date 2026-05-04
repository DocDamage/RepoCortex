#requires -Version 5.1
Set-StrictMode -Version Latest

function Invoke-GoldenTaskSuite {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'SuiteObject')]
        [hashtable]$Suite,

        [Parameter(Mandatory = $true, ParameterSetName = 'SuitePath')]
        [string]$SuitePath,

        [Parameter(Mandatory = $false)]
        [hashtable]$Filter = @{},

        [Parameter(Mandatory = $false)]
        [switch]$Parallel,

        [Parameter(Mandatory = $false)]
        [int]$MaxParallelJobs = $script:GoldenTaskConfig.MaxParallelJobs,

        [Parameter(Mandatory = $false)]
        [switch]$RecordResults,

        [Parameter(Mandatory = $false)]
        [switch]$FailFast,

        [Parameter(Mandatory = $false)]
        [switch]$ExportResults,

        [Parameter(Mandatory = $false)]
        [string]$ExportPath = "",

        [Parameter(Mandatory = $false)]
        [ValidateSet('json', 'csv')]
        [string]$ExportFormat = 'json'
    )

    begin {
        Write-Verbose "Starting golden task suite execution"

        # Load suite if path provided
        if ($SuitePath) {
            $Suite = Import-GoldenTaskSuite -Path $SuitePath
        }

        Write-Verbose "Suite: $($Suite.suiteName) with $($Suite.tasks.Count) tasks"
    }

    process {
        try {
            $startTime = Get-Date
            $allTasks = $Suite.tasks

            # Apply filters
            $filteredTasks = $allTasks | Where-Object {
                $task = $_
                $include = $true

                if ($Filter.category -and $task.category -ne $Filter.category) { $include = $false }
                if ($Filter.difficulty -and $task.difficulty -ne $Filter.difficulty) { $include = $false }
                if ($Filter.tags) {
                    foreach ($tag in $Filter.tags) {
                        if ($task.tags -notcontains $tag) { $include = $false; break }
                    }
                }
                if ($Filter.excludeTags) {
                    foreach ($tag in $Filter.excludeTags) {
                        if ($task.tags -contains $tag) { $include = $false; break }
                    }
                }

                $include
            }

            $tasksToRun = @($filteredTasks)
            Write-Verbose "Running $($tasksToRun.Count) tasks after filtering"

            # Run tasks
            $results = @()
            if ($Parallel -and $tasksToRun.Count -gt 1) {
                $results = Invoke-ParallelGoldenTasks -Tasks $tasksToRun -MaxParallelJobs $MaxParallelJobs `
                    -RecordResults:$RecordResults -FailFast:$FailFast
            } else {
                foreach ($task in $tasksToRun) {
                    Write-Verbose "Running task: $($task.taskId)"
                    $result = Invoke-GoldenTask -Task $task -RecordResults:$RecordResults
                    $results += $result

                    if ($FailFast -and -not $result.Validation.Success) {
                        Write-Warning "Task '$($task.taskId)' failed and FailFast is enabled. Stopping."
                        break
                    }
                }
            }

            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalSeconds

            # Calculate statistics
            $passed = ($results | Where-Object { $_.Validation.Success }).Count
            $failed = $results.Count - $passed
            $passRate = if ($results.Count -gt 0) { ($passed / $results.Count) * 100 } else { 0 }
            $avgConfidence = if ($results.Count -gt 0) {
                ($results | Measure-Object -Property { $_.Validation.Confidence } -Average).Average
            } else { 0 }

            # Category breakdown
            $categoryStats = @{}
            foreach ($result in $results) {
                $cat = $result.Task.Category
                if (-not $categoryStats.ContainsKey($cat)) {
                    $categoryStats[$cat] = @{ Passed = 0; Failed = 0; Total = 0 }
                }
                $categoryStats[$cat].Total++
                if ($result.Validation.Success) {
                    $categoryStats[$cat].Passed++
                } else {
                    $categoryStats[$cat].Failed++
                }
            }

            # Difficulty breakdown
            $difficultyStats = @{}
            foreach ($result in $results) {
                $diff = $result.Task.Difficulty
                if (-not $difficultyStats.ContainsKey($diff)) {
                    $difficultyStats[$diff] = @{ Passed = 0; Failed = 0; Total = 0 }
                }
                $difficultyStats[$diff].Total++
                if ($result.Validation.Success) {
                    $difficultyStats[$diff].Passed++
                } else {
                    $difficultyStats[$diff].Failed++
                }
            }

            $summary = @{
                SuiteName = $Suite.suiteName
                SuiteVersion = $Suite.version
                TasksRun = $results.Count
                Passed = $passed
                Failed = $failed
                PassRate = [math]::Round($passRate, 2)
                AverageConfidence = [math]::Round($avgConfidence, 4)
                DurationSeconds = [math]::Round($duration, 2)
                CategoryBreakdown = $categoryStats
                DifficultyBreakdown = $difficultyStats
                Filter = $Filter
                Tasks = $results
                StartedAt = $startTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
                CompletedAt = $endTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
            }

            # Export results if requested
            if ($ExportResults) {
                if (-not $ExportPath) {
                    $ExportPath = Join-Path $script:GoldenTaskConfig.ResultsDirectory `
                        "suite-$($Suite.suiteName)-$(Get-Date -Format 'yyyyMMdd-HHmmss').$ExportFormat"
                }
                Export-GoldenTaskResults -OutputPath $ExportPath -Format $ExportFormat
                $summary.ExportPath = $ExportPath
            }

            foreach ($line in @(
                '',
                "Golden Task Suite Summary - '$($Suite.suiteName)'",
                "  Tasks Run: $($summary.TasksRun)",
                "  Passed: $($summary.Passed)",
                "  Failed: $($summary.Failed)",
                "  Pass Rate: $($summary.PassRate)%",
                "  Avg Confidence: $($summary.AverageConfidence)"
            )) {
                Write-Information $line -InformationAction Continue
            }

            return $summary
        }
        catch {
            Write-Error "Suite execution failed: $_"
            throw
        }
    }
}
