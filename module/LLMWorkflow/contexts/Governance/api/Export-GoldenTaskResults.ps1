#requires -Version 5.1
Set-StrictMode -Version Latest

function Export-GoldenTaskResults {
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet('json', 'csv')]
        [string]$Format = 'json',

        [Parameter(Mandatory = $false)]
        [string]$PackId,

        [Parameter(Mandatory = $false)]
        [string]$TaskId,

        [Parameter(Mandatory = $false)]
        [DateTime]$FromDate,

        [Parameter(Mandatory = $false)]
        [DateTime]$ToDate,

        [Parameter(Mandatory = $false)]
        [switch]$SuccessOnly,

        [Parameter(Mandatory = $false)]
        [switch]$FailedOnly,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeProperties
    )

    begin {
        Write-Verbose "Exporting golden task results to: $OutputPath"
    }

    process {
        try {
            # Get results with filters
            $params = @{}
            if ($PackId) { $params['PackId'] = $PackId }
            if ($TaskId) { $params['TaskId'] = $TaskId }
            if ($FromDate) { $params['FromDate'] = $FromDate }
            if ($ToDate) { $params['ToDate'] = $ToDate }
            if ($SuccessOnly) { $params['SuccessOnly'] = $true }
            if ($FailedOnly) { $params['FailedOnly'] = $true }

            $results = Get-GoldenTaskResults @params

            if ($results.Count -eq 0) {
                Write-Warning "No results found matching the specified criteria"
                return $null
            }

            # Process results for export
            $exportData = $results | ForEach-Object {
                $row = [ordered]@{
                    EvaluationId = $_.EvaluationId
                    TaskId = $_.Task.TaskId
                    TaskName = $_.Task.Name
                    PackId = $_.Task.PackId
                    Category = $_.Task.Category
                    Difficulty = $_.Task.Difficulty
                    Success = $_.Validation.Success
                    Confidence = $_.Validation.Confidence
                    MinConfidenceRequired = $_.Validation.MinConfidenceRequired
                    PassedProperties = ($_.Validation.PropertyValidation.PassedProperties -join ';')
                    FailedProperties = ($_.Validation.PropertyValidation.FailedProperties -join ';')
                    EvidenceSatisfied = $_.Validation.Evidence.Satisfied
                    EvidenceMissing = $_.Validation.Evidence.MissingCount
                    ForbiddenViolations = $_.Validation.ForbiddenPatterns.Violations
                    Errors = ($_.Validation.Errors -join ';')
                    StartedAt = $_.Timing.StartedAt
                    CompletedAt = $_.Timing.CompletedAt
                    DurationSeconds = $_.Timing.DurationSeconds
                }

                if ($IncludeProperties -and $_.Validation.PropertyValidation.Details) {
                    foreach ($prop in $_.Validation.PropertyValidation.Details.Keys) {
                        $row["Prop_$prop"] = $_.Validation.PropertyValidation.Details[$prop].Match
                    }
                }

                [PSCustomObject]$row
            }

            # Ensure output directory exists
            $outputDir = Split-Path -Parent $OutputPath
            if ($outputDir -and -not (Test-Path $outputDir)) {
                $null = New-Item -ItemType Directory -Path $outputDir -Force
            }

            # Export based on format
            switch ($Format) {
                'json' {
                    $exportData | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding UTF8
                }
                'csv' {
                    $exportData | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
                }
            }

            $fileInfo = Get-Item $OutputPath
            Write-Verbose "Exported $($results.Count) results to: $OutputPath"
            return $fileInfo
        }
        catch {
            Write-Error "Failed to export golden task results: $_"
            throw
        }
    }
}
