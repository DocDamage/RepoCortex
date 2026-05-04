#requires -Version 5.1
Set-StrictMode -Version Latest

function Invoke-LLMQuery {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [string]$Query,
        [string]$Provider = "default",
        [int]$Timeout = 120,
        [switch]$Offline
    )

    if ($Offline) {
        Write-Verbose "[OFFLINE SIMULATION] Returning simulated response for provider '$Provider'"
        return @{
            content = "[Offline Simulated LLM Response] This is a placeholder response."
            provider = $Provider
            tokens = @{ prompt = 100; completion = 200 }
            latency = 500
            mode = "OfflineSimulation"
        }
    }

    # Attempt real execution: check for available LLM provider via environment
    $resolvedProvider = Resolve-ProviderProfile -RequestedProvider $Provider -ErrorAction SilentlyContinue
    if ($resolvedProvider -and $resolvedProvider.ApiKeySet) {
        Write-Verbose "Querying LLM provider '$Provider' with timeout $Timeout`s"
        # If we have a resolved provider, attempt actual API call
        try {
            $queryStartTime = Get-Date
            $headers = @{
                "Authorization" = "Bearer $($resolvedProvider.ApiKey)"
                "Content-Type" = "application/json"
            }
            $body = @{
                model = "default"
                messages = @(@{ role = "user"; content = $Query })
                max_tokens = 4096
            } | ConvertTo-Json

            $response = Invoke-RestMethod -Method Post `
                -Uri "$($resolvedProvider.BaseUrl)/chat/completions" `
                -Headers $headers `
                -Body $body `
                -TimeoutSec $Timeout `
                -ErrorAction Stop

            return @{
                content = $response.choices[0].message.content
                provider = $Provider
                tokens = @{ prompt = $response.usage.prompt_tokens; completion = $response.usage.completion_tokens }
                latency = [math]::Round(((Get-Date) - $queryStartTime).TotalMilliseconds)
                mode = "Live"
            }
        }
        catch {
            Write-Verbose "Live query failed, returning degraded response: $($_.Exception.Message)"
            return @{
                content = "[DEGRADED] Query submission failed: $($_.Exception.Message)"
                provider = $Provider
                tokens = @{ prompt = 0; completion = 0 }
                latency = 0
                mode = "Degraded"
                error = $_.Exception.Message
            }
        }
    }

    # No executor available and not explicitly offline - fail clearly
    throw "No LLM query executor is available. Either configure a provider (set $($Provider.ToUpper())_API_KEY) or pass -Offline for simulation mode."
}

function Save-GoldenTaskResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Result,

        [Parameter()]
        [string]$OutputPath
    )

    if ([string]::IsNullOrWhiteSpace($OutputPath)) {
        $OutputPath = Join-Path $pwd "golden-task-results.json"
    }

    $existing = @()
    if (Test-Path -LiteralPath $OutputPath) {
        try {
            # PS 5.1-compatible JSON parse: ConvertFrom-Json -AsHashtable is PS 7+
            $rawJson = Get-Content -LiteralPath $OutputPath -Raw
            if (-not [string]::IsNullOrWhiteSpace($rawJson)) {
                $parsed = ConvertFrom-Json -InputObject $rawJson
                if ($parsed -is [array]) {
                    $existing = @($parsed | ForEach-Object { ConvertTo-Hashtable -InputObject $_ })
                } elseif ($parsed -is [pscustomobject]) {
                    $existing = @(ConvertTo-Hashtable -InputObject $parsed)
                }
            }
        }
        catch {
            Write-Verbose "Could not parse existing results file, starting fresh: $($_.Exception.Message)"
            $existing = @()
        }
    }

    $existing += $Result
    $existing | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
    Write-Verbose "Saved golden task result to $OutputPath"
}

function Invoke-ParallelGoldenTasks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Tasks,

        [Parameter()]
        [int]$MaxParallelJobs = 4,

        [Parameter()]
        [switch]$RecordResults,

        [Parameter()]
        [switch]$FailFast
    )

    $results = @()
    foreach ($task in $Tasks) {
        try {
            $result = Invoke-GoldenTask -Task $task
            $results += $result
            if ($FailFast -and -not $result.Success) {
                Write-Warning "FailFast enabled: stopping after first failure."
                break
            }
        }
        catch {
            $results += @{
                TaskId = $task.id
                Success = $false
                Error = $_.Exception.Message
            }
            if ($FailFast) {
                Write-Warning "FailFast enabled: stopping after first exception."
                break
            }
        }
    }
    return $results
}
