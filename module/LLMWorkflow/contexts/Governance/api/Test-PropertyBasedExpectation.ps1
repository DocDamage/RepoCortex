#requires -Version 5.1
Set-StrictMode -Version Latest

function Test-PropertyBasedExpectation {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Expected,

        [Parameter(Mandatory = $true)]
        [hashtable]$Actual
    )

    begin {
        Write-Verbose "Starting property-based validation"
        $passedProperties = @()
        $failedProperties = @()
        $confidenceSum = 0.0
        $totalProperties = $Expected.Keys.Count
    }

    process {
        if ($totalProperties -eq 0) {
            Write-Warning "No expected properties to validate"
            return @{
                Success = $true
                PassedProperties = @()
                FailedProperties = @()
                Confidence = 1.0
                Details = @{}
            }
        }

        $details = @{}

        foreach ($propertyName in $Expected.Keys) {
            $expectedValue = $Expected[$propertyName]
            $actualValue = $Actual[$propertyName]
            $propertyMatch = $false
            $matchDetails = @{}

            try {
                # Handle different types of expected values
                if ($expectedValue -is [type]) {
                    # Type checking
                    $propertyMatch = $actualValue -is $expectedValue
                    $matchDetails = @{ type = $expectedValue.Name; actualType = $actualValue.GetType().Name }
                }
                elseif ($expectedValue -is [scriptblock]) {
                    # Script block validation
                    $propertyMatch = & $expectedValue $actualValue
                    $matchDetails = @{ validator = 'scriptblock' }
                }
                elseif ($expectedValue -is [hashtable] -and ($expectedValue.ContainsKey('min') -or $expectedValue.ContainsKey('max'))) {
                    # Range checking
                    $min = $expectedValue['min']
                    $max = $expectedValue['max']
                    $propertyMatch = $true
                    if ($null -ne $min -and $actualValue -lt $min) { $propertyMatch = $false }
                    if ($null -ne $max -and $actualValue -gt $max) { $propertyMatch = $false }
                    $matchDetails = @{ min = $min; max = $max; actual = $actualValue }
                }
                elseif ($expectedValue -is [array] -and $expectedValue.Count -gt 0) {
                    # Collection containment - actual should contain all expected items
                    $propertyMatch = $true
                    $missing = @()
                    foreach ($item in $expectedValue) {
                        if ($actualValue -notcontains $item) {
                            $propertyMatch = $false
                            $missing += $item
                        }
                    }
                    $matchDetails = @{ expectedItems = $expectedValue; missingItems = $missing }
                }
                elseif ($expectedValue -is [string] -and $expectedValue.StartsWith('regex:')) {
                    # Regex pattern matching
                    $pattern = $expectedValue.Substring(6)
                    $propertyMatch = $actualValue -match $pattern
                    $matchDetails = @{ pattern = $pattern }
                }
                elseif ($expectedValue -is [string] -and $expectedValue.StartsWith('like:')) {
                    # Wildcard matching
                    $pattern = $expectedValue.Substring(5)
                    $propertyMatch = $actualValue -like $pattern
                    $matchDetails = @{ pattern = $pattern }
                }
                elseif ($expectedValue -eq $true) {
                    # Presence checking - property must exist and not be null/empty
                    $exists = if ($Actual -is [hashtable]) { $Actual.ContainsKey($propertyName) } else { $null -ne $Actual.$propertyName }
                    $count = 1
                    try { if ($null -ne $actualValue) { $count = @($actualValue).Count } } catch { $count = 1 }
                    $propertyMatch = ($exists -and $null -ne $actualValue -and $actualValue -ne '' -and $count -ne 0)
                    $matchDetails = @{ check = 'presence'; exists = $exists; value = $actualValue; count = $count }
                }
                elseif ($expectedValue -eq $false) {
                    # Absence checking - property should not exist, or be null/empty/false
                    $exists = if ($Actual -is [hashtable]) { $Actual.ContainsKey($propertyName) } else { $null -ne $Actual.$propertyName }
                    $count = 0
                    try { if ($null -ne $actualValue) { $count = @($actualValue).Count } } catch { $count = 0 }
                    $propertyMatch = (-not $exists -or $null -eq $actualValue -or $actualValue -eq '' -or $actualValue -eq $false -or $count -eq 0)
                    $matchDetails = @{ check = 'absence'; exists = $exists; value = $actualValue; count = $count }
                }
                else {
                    # Exact value matching (case-insensitive for strings)
                    if ($expectedValue -is [string] -and $actualValue -is [string]) {
                        $propertyMatch = $expectedValue -eq $actualValue
                    }
                    else {
                        $propertyMatch = $expectedValue -eq $actualValue
                    }
                    $matchDetails = @{ expected = $expectedValue; actual = $actualValue }
                }
            }
            catch {
                Write-Verbose "Error validating property '$propertyName': $_"
                $propertyMatch = $false
                $matchDetails = @{ error = $_.ToString() }
            }

            $details[$propertyName] = @{
                Expected = $expectedValue
                Actual = $actualValue
                Match = $propertyMatch
                Details = $matchDetails
            }

            if ($propertyMatch) {
                $passedProperties += $propertyName
                $confidenceSum += 1.0
            }
            else {
                $failedProperties += $propertyName
            }
        }

        $overallConfidence = if ($totalProperties -gt 0) { $confidenceSum / $totalProperties } else { 0 }
        $success = $failedProperties.Count -eq 0

        # Add failed properties to details with a clear flag
        return @{
            Success = $success
            PassedProperties = $passedProperties
            FailedProperties = $failedProperties
            Confidence = [math]::Round($overallConfidence, 4)
            Details = $details
        }
    }
}
