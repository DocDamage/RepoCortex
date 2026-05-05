Set-StrictMode -Version Latest

function Get-LLMWorkflowNextAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter()]
        [string]$ProjectRoot = '.'
    )

    $resolvedRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
    $versionPath = Join-Path $resolvedRoot 'VERSION'

    if (-not (Test-Path -LiteralPath $versionPath)) {
        return [pscustomobject][ordered]@{
            Priority = 1
            ActionId = 'create-version'
            Area = 'DocumentationTruth'
            Status = 'Blocked'
            Action = 'Create a VERSION file before running release gates.'
            Evidence = "Missing file: $versionPath"
            ProjectRoot = $resolvedRoot
        }
    }

    $reportDir = Join-Path $resolvedRoot 'certification-reports'
    $latestReportFile = $null
    if (Test-Path -LiteralPath $reportDir) {
        $latestReportFile = Get-ChildItem -LiteralPath $reportDir -Filter '*.json' -File |
            Sort-Object LastWriteTimeUtc, Name -Descending |
            Select-Object -First 1
    }

    if ($latestReportFile) {
        $report = Get-Content -LiteralPath $latestReportFile.FullName -Raw | ConvertFrom-Json
        $overallStatus = ''
        if ($report.PSObject.Properties['OverallStatus']) {
            $overallStatus = [string]$report.OverallStatus
        }
        elseif ($report.PSObject.Properties['OverallPassed']) {
            $overallStatus = if ([bool]$report.OverallPassed) { 'PASS' } else { 'FAIL' }
        }
        else {
            $overallStatus = 'FAIL'
        }

        if ($overallStatus -ne 'PASS') {
            $failedCategories = @()
            if ($report.PSObject.Properties['CategoryResults']) {
                $failedCategories = @($report.CategoryResults | Where-Object {
                    [string]$_.Status -eq 'FAIL'
                } | ForEach-Object {
                    [string]$_.Category
                })
            }
            elseif ($report.PSObject.Properties['Categories']) {
                $failedCategories = @($report.Categories.PSObject.Properties | Where-Object {
                    $_.Value -eq $false
                } | ForEach-Object {
                    [string]$_.Name
                })
            }

            if ($failedCategories.Count -eq 0) {
                $failedCategories = @($overallStatus)
            }

            return [pscustomobject][ordered]@{
                Priority = 1
                ActionId = 'fix-release-certification'
                Area = 'ReleaseCertification'
                Status = 'Blocked'
                Action = 'Fix failing release certification categories, then rerun strict certification.'
                Evidence = "Certification report $($latestReportFile.Name) failed: $($failedCategories -join ', ')"
                ProjectRoot = $resolvedRoot
            }
        }
    }

    $security = Test-LLMWorkflowSecurityExceptions -ProjectRoot $resolvedRoot
    if ($security.HasExpired -or $security.HasInvalid) {
        $problemCount = [int]$security.ExpiredCount + [int]$security.InvalidCount
        return [pscustomobject][ordered]@{
            Priority = 2
            ActionId = 'review-security-exceptions'
            Area = 'Security'
            Status = 'NeedsReview'
            Action = 'Review expired or invalid security exceptions before promotion.'
            Evidence = "$problemCount security exception ledger item(s) require review."
            ProjectRoot = $resolvedRoot
        }
    }

    if (-not $latestReportFile) {
        return [pscustomobject][ordered]@{
            Priority = 3
            ActionId = 'run-release-certification'
            Area = 'ReleaseCertification'
            Status = 'Ready'
            Action = 'Run strict release certification to create fresh evidence.'
            Evidence = "No certification JSON report found under $reportDir"
            ProjectRoot = $resolvedRoot
        }
    }

    return [pscustomobject][ordered]@{
        Priority = 5
        ActionId = 'review-release-readiness'
        Area = 'Operations'
        Status = 'Ready'
        Action = 'Review the latest release evidence and decide whether to promote or cut a new candidate.'
        Evidence = "Latest certification report passed: $($latestReportFile.Name)"
        ProjectRoot = $resolvedRoot
    }
}
