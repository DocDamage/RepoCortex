#requires -Version 5.1
Set-StrictMode -Version Latest

function Invoke-PackGoldenTasks {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackId,

        [Parameter(Mandatory = $false)]
        [hashtable]$Filter = @{},

        [Parameter(Mandatory = $false)]
        [switch]$Parallel,

        [Parameter(Mandatory = $false)]
        [int]$MaxParallelJobs = $script:GoldenTaskConfig.MaxParallelJobs,

        [Parameter(Mandatory = $false)]
        [switch]$RecordResults,

        [Parameter(Mandatory = $false)]
        [switch]$FailFast
    )

    begin {
        Write-Verbose "Loading golden tasks for pack: $PackId"
        $allTasks = Get-PredefinedGoldenTasks -PackId $PackId

        if (-not $allTasks -or $allTasks.Count -eq 0) {
            Write-Warning "No golden tasks found for pack: $PackId"
            return @{ PackId = $PackId; TasksRun = 0; Passed = 0; Failed = 0; Tasks = @(); Summary = "No tasks found" }
        }

        Write-Verbose "Found $($allTasks.Count) golden tasks"

        # Apply filters
        $filteredTasks = $allTasks | Where-Object {
            $t = $_
            $include = $true

            # Safe property access for strict mode (handles hashtable or pscustomobject)
            $taskCategory = $null
            $taskDifficulty = $null
            $taskTags = $null

            if ($t -is [hashtable]) {
                $taskCategory = $t['category']
                $taskDifficulty = $t['difficulty']
                $taskTags = $t['tags']
            }
            else {
                $taskCategory = Get-SafeObjectPropertyValue -InputObject $t -PropertyName 'category'
                $taskDifficulty = Get-SafeObjectPropertyValue -InputObject $t -PropertyName 'difficulty'
                $taskTags = Get-SafeObjectPropertyValue -InputObject $t -PropertyName 'tags' -Default @()
            }

            if ($Filter.ContainsKey('category') -and $Filter.category -and $taskCategory -ne $Filter.category) { $include = $false }
            if ($Filter.ContainsKey('difficulty') -and $Filter.difficulty -and $taskDifficulty -ne $Filter.difficulty) { $include = $false }
            if ($Filter.ContainsKey('tags') -and $Filter.tags) {
                foreach ($tag in $Filter.tags) {
                    if ($taskTags -notcontains $tag) { $include = $false; break }
                }
            }
            if ($Filter.ContainsKey('excludeTags') -and $Filter.excludeTags) {
                foreach ($tag in $Filter.excludeTags) {
                    if ($taskTags -contains $tag) { $include = $false; break }
                }
            }

            $include
        }

        $tasksToRun = @($filteredTasks)
        Write-Verbose "Running $($tasksToRun.Count) tasks after filtering"

        $startTime = Get-Date
        $results = @()
    }

    process {
        if (-not $allTasks -or $allTasks.Count -eq 0) {
            return
        }

        if ($Parallel -and $tasksToRun.Count -gt 1) {
            # Run in parallel using runspaces
            $results = Invoke-ParallelGoldenTasks -Tasks $tasksToRun -MaxParallelJobs $MaxParallelJobs -RecordResults:$RecordResults -FailFast:$FailFast
        }
        else {
            # Run sequentially
            foreach ($task in $tasksToRun) {
                Write-Verbose "Running task: $($task.taskId)"
                $result = Invoke-GoldenTask -Task $task -RecordResults:$RecordResults
                $results += $result

                if ($FailFast -and $result -and $result.Validation -and -not $result.Validation.Success) {
                    Write-Warning "Task '$($task.taskId)' failed and FailFast is enabled. Stopping."
                    break
                }
            }
        }

        $endTime = Get-Date
        $duration = 0
        if ($null -ne $startTime) {
            $duration = ($endTime - $startTime).TotalSeconds
        }

        # Calculate statistics
        $passed = 0
        $resultList = @($results)
        if ($resultList.Count -gt 0) {
            # Safely check for Success property on either hashtable or pscustomobject
            $passed = (@($resultList | Where-Object { 
                $r = $_
                $isSucc = $false
                if ($r -is [hashtable]) {
                    $isSucc = $r['Success'] -eq $true
                }
                else {
                    $isSucc = (Get-SafeObjectPropertyValue -InputObject $r -PropertyName 'Success' -Default $false) -eq $true
                }
                $isSucc
            })).Count
        }
        $failed = $resultList.Count - $passed
        $avgConfidence = 0.0
        if ($resultList.Count -gt 0) {
            $measure = $resultList | Measure-Object -Property { 
                $conf = 0.0
                if ($_ -is [hashtable]) {
                    if ($_.ContainsKey('Validation') -and $_['Validation'] -is [hashtable]) {
                        $conf = $_['Validation']['Confidence']
                    }
                    elseif ($_.ContainsKey('Confidence')) {
                        $conf = $_['Confidence']
                    }
                }
                else {
                    $validation = Get-SafeObjectPropertyValue -InputObject $_ -PropertyName 'Validation'
                    if ($null -ne $validation) {
                        $conf = Get-SafeObjectPropertyValue -InputObject $validation -PropertyName 'Confidence' -Default 0.0
                    }
                    else {
                        $conf = Get-SafeObjectPropertyValue -InputObject $_ -PropertyName 'Confidence' -Default 0.0
                    }
                }
                $conf
            } -Average
            # Use safe property check for strict mode
            if ($measure.PSObject.Properties['Average'] -and $measure.Average -ne $null) {
                $avgConfidence = $measure.Average
            }
        }

        $categoryStats = @{}
        foreach ($res in $results) {
            # Find the original task if possible, or use ID
            $cat = "General"
            if ($res -is [hashtable]) { 
                # In Invoke-PackGoldenTasks, we might have stored the category in the result or we look it up
                # Actually, the result doesn't have Category currently. 
                # Let's assume it might be in TaskName or we can lookup from $allTasks
                $taskMatch = $allTasks | Where-Object { 
                    if ($_ -is [hashtable]) { $_['taskId'] -eq $res['TaskId'] } else { $_.taskId -eq $res.TaskId }
                }
                if ($taskMatch) { $cat = if ($taskMatch -is [hashtable]) { $taskMatch['category'] } else { $taskMatch.category } }
            }
            
            if (-not $categoryStats.ContainsKey($cat)) {
                $categoryStats[$cat] = @{ Passed = 0; Failed = 0; Total = 0 }
            }
            $categoryStats[$cat].Total++
            $isSuccess = if ($res -is [hashtable]) { $res['Success'] } else { 
                try { $res.Success } catch { 
                    Write-Verbose "GoldenTasks: Failed to read Success property from result - treating as false"
                    $false 
                } 
            }
            if ($isSuccess) {
                $categoryStats[$cat].Passed++
            }
            else {
                $categoryStats[$cat].Failed++
            }
        }

        $difficultyStats = @{}
        foreach ($res in $results) {
            $diff = "Medium"
            $taskMatch = $allTasks | Where-Object { 
                if ($_ -is [hashtable]) { $_['taskId'] -eq $res['TaskId'] } else { $_.taskId -eq $res.TaskId }
            }
            if ($taskMatch) { $diff = if ($taskMatch -is [hashtable]) { $taskMatch['difficulty'] } else { $taskMatch.difficulty } }
            
            if (-not $difficultyStats.ContainsKey($diff)) {
                $difficultyStats[$diff] = @{ Passed = 0; Failed = 0; Total = 0 }
            }
            $difficultyStats[$diff].Total++
            $isSuccess = if ($res -is [hashtable]) { $res['Success'] } else { 
                try { $res.Success } catch { 
                    Write-Verbose "GoldenTasks: Failed to read Success property from difficultyStats result - treating as false"
                    $false 
                } 
            }
            if ($isSuccess) {
                $difficultyStats[$diff].Passed++
            }
            else {
                $difficultyStats[$diff].Failed++
            }
        }

        $summary = @{
            PackId = $PackId
            TasksRun = $results.Count
            Passed = $passed
            Failed = $failed
            PassRate = if ($results.Count -gt 0) { [math]::Round($passed / $results.Count, 4) } else { 0 }
            AverageConfidence = [math]::Round($avgConfidence, 4)
            DurationSeconds = [math]::Round($duration, 2)
            CategoryBreakdown = $categoryStats
            DifficultyBreakdown = $difficultyStats
            Filter = $Filter
            Tasks = $results
            StartedAt = $startTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
            CompletedAt = $endTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
        }

        Write-GoldenTaskSummary -Summary $summary

        return $summary
    }
}
