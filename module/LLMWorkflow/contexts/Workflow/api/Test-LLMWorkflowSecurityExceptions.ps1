Set-StrictMode -Version Latest

function Test-LLMWorkflowSecurityExceptions {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter()]
        [string]$ProjectRoot = '.',

        [Parameter()]
        [string]$LedgerPath
    )

    $resolvedRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
    if (-not $LedgerPath) {
        $LedgerPath = Join-Path $resolvedRoot '.llm-workflow\security-exceptions.json'
        if (-not (Test-Path -LiteralPath $LedgerPath)) {
            $LedgerPath = Join-Path $resolvedRoot 'security-exceptions.json'
        }
    }

    if (-not (Test-Path -LiteralPath $LedgerPath)) {
        return [pscustomobject][ordered]@{
            LedgerPath = $LedgerPath
            HasLedger = $false
            Total = 0
            ExpiredCount = 0
            InvalidCount = 0
            HasExpired = $false
            HasInvalid = $false
            Exceptions = @()
        }
    }

    $ledger = Get-Content -LiteralPath $LedgerPath -Raw | ConvertFrom-Json
    $today = (Get-Date).Date
    $items = foreach ($exception in @(Get-LLMWorkflowObjectProperty -InputObject $ledger -Name 'exceptions' -Default @())) {
        $status = 'Active'
        $expiresOn = [string](Get-LLMWorkflowObjectProperty -InputObject $exception -Name 'expiresOn' -Default '')
        $expiry = $null
        if ([string]::IsNullOrWhiteSpace($expiresOn)) {
            $status = 'Invalid'
        }
        else {
            try {
                $expiry = [DateTime]::Parse($expiresOn, [Globalization.CultureInfo]::InvariantCulture).Date
                if ($expiry -lt $today) {
                    $status = 'Expired'
                }
            }
            catch {
                $status = 'Invalid'
            }
        }

        [pscustomobject][ordered]@{
            Id = [string](Get-LLMWorkflowObjectProperty -InputObject $exception -Name 'id' -Default '')
            Owner = [string](Get-LLMWorkflowObjectProperty -InputObject $exception -Name 'owner' -Default '')
            Reason = [string](Get-LLMWorkflowObjectProperty -InputObject $exception -Name 'reason' -Default '')
            ExpiresOn = $expiresOn
            Scanner = [string](Get-LLMWorkflowObjectProperty -InputObject $exception -Name 'scanner' -Default '')
            Fingerprint = [string](Get-LLMWorkflowObjectProperty -InputObject $exception -Name 'fingerprint' -Default '')
            Status = $status
        }
    }

    $expired = @($items | Where-Object { $_.Status -eq 'Expired' }).Count
    $invalid = @($items | Where-Object { $_.Status -eq 'Invalid' }).Count

    return [pscustomObject][ordered]@{
        LedgerPath = $LedgerPath
        HasLedger = $true
        Total = @($items).Count
        ExpiredCount = $expired
        InvalidCount = $invalid
        HasExpired = ($expired -gt 0)
        HasInvalid = ($invalid -gt 0)
        Exceptions = @($items)
    }
}
