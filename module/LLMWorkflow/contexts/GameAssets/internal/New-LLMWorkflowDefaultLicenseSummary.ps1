Set-StrictMode -Version Latest

function New-LLMWorkflowDefaultLicenseSummary {
    [CmdletBinding()]
    param()

    return [ordered]@{
        original = 0
        cc0 = 0
        ccBy = 0
        ccBySa = 0
        proprietary = 0
        unknown = 0
    }
}
