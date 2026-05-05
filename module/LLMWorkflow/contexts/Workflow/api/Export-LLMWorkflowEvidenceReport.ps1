Set-StrictMode -Version Latest

function Get-LLMWorkflowObjectProperty {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$InputObject,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter()]
        [object]$Default = $null
    )

    if ($null -eq $InputObject) {
        return $Default
    }

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $Default
    }

    return $property.Value
}

function Export-LLMWorkflowEvidenceReport {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [object]$AnswerTrace,

        [Parameter(Mandatory = $true)]
        [string]$ExportPath,

        [Parameter()]
        [string]$HtmlPath
    )

    $evidence = @(Get-LLMWorkflowObjectProperty -InputObject $AnswerTrace -Name 'evidence' -Default @())
    $normalizedEvidence = foreach ($item in $evidence) {
        [pscustomobject][ordered]@{
            sourcePath = [string](Get-LLMWorkflowObjectProperty -InputObject $item -Name 'sourcePath' -Default '')
            confidence = Get-LLMWorkflowObjectProperty -InputObject $item -Name 'confidence' -Default $null
            excerpt = [string](Get-LLMWorkflowObjectProperty -InputObject $item -Name 'excerpt' -Default '')
        }
    }

    $report = [pscustomobject][ordered]@{
        schemaVersion = 1
        generatedAt = [DateTime]::UtcNow.ToString('o')
        query = [string](Get-LLMWorkflowObjectProperty -InputObject $AnswerTrace -Name 'query' -Default '')
        route = Get-LLMWorkflowObjectProperty -InputObject $AnswerTrace -Name 'route' -Default ([pscustomobject]@{})
        confidence = Get-LLMWorkflowObjectProperty -InputObject $AnswerTrace -Name 'confidence' -Default $null
        evidence = @($normalizedEvidence)
        evidenceCount = @($normalizedEvidence).Count
        caveats = @(Get-LLMWorkflowObjectProperty -InputObject $AnswerTrace -Name 'caveats' -Default @())
        policy = Get-LLMWorkflowObjectProperty -InputObject $AnswerTrace -Name 'policy' -Default ([pscustomobject]@{})
    }

    $exportDir = Split-Path -Parent $ExportPath
    if ($exportDir -and -not (Test-Path -LiteralPath $exportDir)) {
        New-Item -ItemType Directory -Path $exportDir -Force | Out-Null
    }

    $report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ExportPath -Encoding UTF8

    if ($HtmlPath) {
        $htmlDir = Split-Path -Parent $HtmlPath
        if ($htmlDir -and -not (Test-Path -LiteralPath $htmlDir)) {
            New-Item -ItemType Directory -Path $htmlDir -Force | Out-Null
        }

        $evidenceRows = foreach ($item in $normalizedEvidence) {
            $source = [System.Net.WebUtility]::HtmlEncode($item.sourcePath)
            $confidence = [System.Net.WebUtility]::HtmlEncode([string]$item.confidence)
            $excerpt = [System.Net.WebUtility]::HtmlEncode($item.excerpt)
            "<tr><td>$source</td><td>$confidence</td><td>$excerpt</td></tr>"
        }
        $query = [System.Net.WebUtility]::HtmlEncode($report.query)
        $policy = [System.Net.WebUtility]::HtmlEncode(($report.policy | ConvertTo-Json -Depth 5 -Compress))
        $html = @"
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>Answer Evidence Explorer</title>
  <style>body{font-family:Segoe UI,Arial,sans-serif;margin:32px;color:#1f2937}table{border-collapse:collapse;width:100%}td,th{border:1px solid #d1d5db;padding:8px;text-align:left}th{background:#f3f4f6}.meta{color:#4b5563}</style>
</head>
<body>
  <h1>Answer Evidence Explorer</h1>
  <p class="meta">Generated $($report.generatedAt)</p>
  <h2>Query</h2>
  <p>$query</p>
  <h2>Evidence</h2>
  <table><thead><tr><th>Source</th><th>Confidence</th><th>Excerpt</th></tr></thead><tbody>$($evidenceRows -join "`n")</tbody></table>
  <h2>Policy</h2>
  <pre>$policy</pre>
</body>
</html>
"@
        Set-Content -LiteralPath $HtmlPath -Value $html -Encoding UTF8
    }

    return [pscustomobject][ordered]@{
        ReportPath = $ExportPath
        HtmlPath = $HtmlPath
        EvidenceCount = @($normalizedEvidence).Count
        Query = $report.query
    }
}
