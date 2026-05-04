#requires -Version 5.1
Set-StrictMode -Version Latest

function Get-SafeObjectPropertyValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $InputObject,

        [Parameter(Mandatory = $true)]
        [string]$PropertyName,

        [Parameter()]
        $Default = $null
    )

    if ($null -eq $InputObject) {
        return $Default
    }

    if ($InputObject -is [hashtable]) {
        if ($InputObject.ContainsKey($PropertyName)) {
            return $InputObject[$PropertyName]
        }
        return $Default
    }

    $property = $InputObject.PSObject.Properties[$PropertyName]
    if ($null -ne $property) {
        return $property.Value
    }

    return $Default
}

function Write-GoldenTaskSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Summary
    )

    $lines = @(
        '',
        "Golden Task Summary for '$($Summary.PackId)':",
        "  Tasks Run: $($Summary.TasksRun)",
        "  Passed: $($Summary.Passed)",
        "  Failed: $($Summary.Failed)",
        "  Pass Rate: $([math]::Round($Summary.PassRate * 100, 2))%",
        "  Avg Confidence: $($Summary.AverageConfidence)"
    )

    foreach ($line in $lines) {
        Write-Information $line -InformationAction Continue
    }
}

function ConvertTo-Hashtable {
    param(
        $InputObject
    )

    if ($InputObject -is [System.Collections.Hashtable]) {
        return $InputObject
    }

    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        return @($InputObject | ForEach-Object { ConvertTo-Hashtable -InputObject $_ })
    }

    if ($InputObject -is [pscustomobject] -or $InputObject -is [System.Management.Automation.PSCustomObject]) {
        $hash = @{}
        foreach ($property in $InputObject.PSObject.Properties) {
            $hash[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
        }
        return $hash
    }

    return $InputObject
}
