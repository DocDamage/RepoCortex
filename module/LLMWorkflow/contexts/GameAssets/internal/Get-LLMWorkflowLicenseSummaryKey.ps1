Set-StrictMode -Version Latest

function Get-LLMWorkflowLicenseSummaryKey {
    [CmdletBinding()]
    param(
        [string]$License
    )

    $normalized = ([string]$License).Trim().ToLowerInvariant()
    switch -Regex ($normalized) {
        "^original$" { return "original" }
        "^cc0$" { return "cc0" }
        "^cc[- ]?by([- ]?4\.0)?$" { return "ccBy" }
        "^cc[- ]?by[- ]?sa([- ]?4\.0)?$" { return "ccBySa" }
        "^proprietary$" { return "proprietary" }
        default { return "unknown" }
    }
}
