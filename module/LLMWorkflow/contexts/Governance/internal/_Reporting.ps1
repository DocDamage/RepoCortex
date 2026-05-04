#requires -Version 5.1
Set-StrictMode -Version Latest

function ConvertTo-GoldenTaskHtmlReport {
    param([hashtable]$Report)

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>$($Report.ReportMetadata.Title)</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #333; }
        .summary { background: #f5f5f5; padding: 20px; border-radius: 5px; margin: 20px 0; }
        .metric { display: inline-block; margin: 10px 20px; }
        .metric-value { font-size: 24px; font-weight: bold; }
        .metric-label { font-size: 12px; color: #666; }
        .passed { color: green; }
        .failed { color: red; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #333; color: white; }
    </style>
</head>
<body>
    <h1>$($Report.ReportMetadata.Title)</h1>
    <p>Generated: $($Report.ReportMetadata.GeneratedAt)</p>
    
    <div class="summary">
        <h2>Summary</h2>
        <div class="metric">
            <div class="metric-value">$($Report.Summary.TotalTasks)</div>
            <div class="metric-label">Total Tasks</div>
        </div>
        <div class="metric">
            <div class="metric-value passed">$($Report.Summary.PassedTasks)</div>
            <div class="metric-label">Passed</div>
        </div>
        <div class="metric">
            <div class="metric-value failed">$($Report.Summary.FailedTasks)</div>
            <div class="metric-label">Failed</div>
        </div>
        <div class="metric">
            <div class="metric-value">$($Report.Summary.Grade)</div>
            <div class="metric-label">Grade</div>
        </div>
        <div class="metric">
            <div class="metric-value">$($Report.Summary.PassRate)%</div>
            <div class="metric-label">Pass Rate</div>
        </div>
    </div>
</body>
</html>
"@
    return $html
}

function ConvertTo-GoldenTaskMarkdownReport {
    param([hashtable]$Report)

    $md = @"
# $($Report.ReportMetadata.Title)

**Generated:** $($Report.ReportMetadata.GeneratedAt)

## Summary

| Metric | Value |
|--------|-------|
| Total Tasks | $($Report.Summary.TotalTasks) |
| Passed | $($Report.Summary.PassedTasks) |
| Failed | $($Report.Summary.FailedTasks) |
| Pass Rate | $($Report.Summary.PassRate)% |
| Grade | $($Report.Summary.Grade) |
| Avg Confidence | $([math]::Round($Report.Summary.AverageConfidence * 100, 2))% |

## Difficulty Breakdown

"@
    foreach ($diff in $Report.Summary.TaskBreakdown.Keys) {
        $md += "- **$($diff):** $($Report.Summary.TaskBreakdown[$diff])`n"
    }

    return $md
}
