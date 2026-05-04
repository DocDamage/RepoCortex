#requires -Version 5.1
Set-StrictMode -Version Latest

function Invoke-GoldenTask {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Task,

        [Parameter(Mandatory = $false)]
        [hashtable]$SystemConfig = @{},

        [Parameter(Mandatory = $false)]
        [switch]$RecordResults,

        [Parameter(Mandatory = $false)]
        [string]$LLMProvider = "default",

        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 120,

        [Parameter(Mandatory = $false)]
        [switch]$Offline
    )

    begin {
        Write-Verbose "Starting golden task evaluation: $($Task.taskId)"
        $startTime = Get-Date
    }

    process {
        try {
            # Validate task structure
            if (-not $Task.query) {
                throw "Task '$($Task.taskId)' is missing required 'query' field"
            }

            # Execute LLM query (real provider if available, or -Offline for simulation)
            $llmResponse = Invoke-LLMQuery -Query $Task.query -Provider $LLMProvider -Timeout $TimeoutSeconds -Offline:$Offline

            # Extract properties from LLM response
            $extractedProperties = Extract-ResponseProperties -Response $llmResponse -Task $Task

            # Validate the result
            $validation = Test-GoldenTaskResult `
                -Task $Task `
                -ActualResult $extractedProperties `
                -AnswerText $llmResponse.content

            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalSeconds

            # Build evaluation result
            $evalResult = @{
                EvaluationId = [Guid]::NewGuid().ToString()
                Task = @{
                    TaskId = $Task.taskId
                    Name = $Task.name
                    PackId = $Task.packId
                    Category = $Task.category
                    Difficulty = $Task.difficulty
                }
                Success = $validation.Success
                Query = $Task.query
                LLMResponse = $llmResponse
                ExtractedProperties = $extractedProperties
                Validation = $validation
                Timing = @{
                    StartedAt = $startTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
                    CompletedAt = $endTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
                    DurationSeconds = [math]::Round($duration, 2)
                }
                SystemConfig = $SystemConfig
            }

            # Record results if requested
            if ($RecordResults) {
                Save-GoldenTaskResult -Result $evalResult
                Write-Verbose "Results recorded for task '$($Task.taskId)'"
            }

            return $evalResult
        }
        catch {
            $errorResult = @{
                EvaluationId = [Guid]::NewGuid().ToString()
                Task = @{
                    TaskId = $Task.taskId
                    Name = $Task.name
                    PackId = $Task.packId
                }
                Success = $false
                Error = $_.ToString()
                Timing = @{
                    StartedAt = $startTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
                    FailedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
                }
            }

            if ($RecordResults) {
                Save-GoldenTaskResult -Result $errorResult
            }

            Write-Error "Golden task evaluation failed: $_"
            return $errorResult
        }
    }
}
