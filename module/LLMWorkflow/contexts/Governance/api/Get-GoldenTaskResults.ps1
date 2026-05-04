#requires -Version 5.1
Set-StrictMode -Version Latest

function Get-GoldenTaskResults {
    [CmdletBinding()]
    [OutputType([array])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$TaskId,

        [Parameter(Mandatory = $false)]
        [string]$PackId,

        [Parameter(Mandatory = $false)]
        [DateTime]$FromDate,

        [Parameter(Mandatory = $false)]
        [DateTime]$ToDate,

        [Parameter(Mandatory = $false)]
        [switch]$SuccessOnly,

        [Parameter(Mandatory = $false)]
        [switch]$FailedOnly,

        [Parameter(Mandatory = $false)]
        [int]$Last = 0
    )

    begin {
        Write-Verbose "Retrieving golden task results"
        $resultsDir = $script:GoldenTaskConfig.ResultsDirectory
        
        if (-not (Test-Path $resultsDir)) {
            Write-Verbose "Results directory does not exist: $resultsDir"
            return @()
        }

        $allResults = @()
    }

    process {
        # Load all result files
        $resultFiles = Get-ChildItem -Path $resultsDir -Filter "*.json" -Recurse -File

        foreach ($file in $resultFiles) {
            try {
                $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
                $result = $content | ConvertFrom-Json -ErrorAction Stop

                if ($result) {
                    # Convert to hashtable for consistency
                    $resultObj = ConvertTo-Hashtable -InputObject $result
                    $allResults += $resultObj
                }
            }
            catch {
                Write-Warning "Failed to load golden-task result file '$($file.Name)': $_"
            }
        }

        # Apply filters
        $filteredResults = $allResults

        if ($TaskId) {
            $filteredResults = $filteredResults | Where-Object { $_.Task.TaskId -eq $TaskId }
        }

        if ($PackId) {
            $filteredResults = $filteredResults | Where-Object { $_.Task.PackId -eq $PackId }
        }

        if ($FromDate) {
            $fromStr = $FromDate.ToString("yyyy-MM-dd")
            $filteredResults = $filteredResults | Where-Object { 
                $_.Timing.StartedAt -and $_.Timing.StartedAt.Substring(0,10) -ge $fromStr 
            }
        }

        if ($ToDate) {
            $toStr = $ToDate.ToString("yyyy-MM-dd")
            $filteredResults = $filteredResults | Where-Object { 
                $_.Timing.StartedAt -and $_.Timing.StartedAt.Substring(0,10) -le $toStr 
            }
        }

        if ($SuccessOnly) {
            $filteredResults = $filteredResults | Where-Object { $_.Validation.Success -eq $true }
        }

        if ($FailedOnly) {
            $filteredResults = $filteredResults | Where-Object { $_.Validation.Success -eq $false }
        }

        # Sort by date (newest first)
        $sortedResults = $filteredResults | Sort-Object { $_.Timing.StartedAt } -Descending

        # Limit results if specified
        if ($Last -gt 0 -and $sortedResults.Count -gt $Last) {
            $sortedResults = $sortedResults | Select-Object -First $Last
        }

        Write-Verbose "Retrieved $($sortedResults.Count) results"
        return $sortedResults
    }
}
