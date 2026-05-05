Set-StrictMode -Version Latest

function Invoke-LLMWorkflowCorpusRegression {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CorpusRoot,

        [Parameter()]
        [string]$ReportPath
    )

    $resolvedCorpus = (Resolve-Path -LiteralPath $CorpusRoot -ErrorAction Stop).Path
    $caseFiles = @(Get-ChildItem -LiteralPath $resolvedCorpus -Filter '*.case.json' -File -Recurse)
    $results = foreach ($file in $caseFiles) {
        $case = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
        $expected = @(Get-LLMWorkflowObjectProperty -InputObject $case -Name 'expectedEvidence' -Default @())
        $actual = @(Get-LLMWorkflowObjectProperty -InputObject $case -Name 'actualEvidence' -Default @())
        $missing = @($expected | Where-Object { $_ -notin $actual })
        [pscustomobject][ordered]@{
            id = [string](Get-LLMWorkflowObjectProperty -InputObject $case -Name 'id' -Default $file.BaseName)
            packId = [string](Get-LLMWorkflowObjectProperty -InputObject $case -Name 'packId' -Default '')
            query = [string](Get-LLMWorkflowObjectProperty -InputObject $case -Name 'query' -Default '')
            status = $(if ($missing.Count -eq 0) { 'Pass' } else { 'Fail' })
            missingEvidence = @($missing)
            file = $file.FullName
        }
    }

    $passed = @($results | Where-Object { $_.status -eq 'Pass' }).Count
    $failed = @($results | Where-Object { $_.status -eq 'Fail' }).Count
    $summary = [pscustomobject][ordered]@{
        schemaVersion = 1
        generatedAt = [DateTime]::UtcNow.ToString('o')
        CorpusRoot = $resolvedCorpus
        TotalCases = @($results).Count
        Passed = $passed
        Failed = $failed
        Results = @($results)
    }

    if ($ReportPath) {
        $reportDir = Split-Path -Parent $ReportPath
        if ($reportDir -and -not (Test-Path -LiteralPath $reportDir)) {
            New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
        }
        $summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ReportPath -Encoding UTF8
    }

    return $summary
}
