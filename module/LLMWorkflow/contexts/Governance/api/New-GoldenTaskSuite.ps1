#requires -Version 5.1
Set-StrictMode -Version Latest

function New-GoldenTaskSuite {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SuiteName,

        [Parameter(Mandatory = $true)]
        [array]$Tasks,

        [Parameter(Mandatory = $false)]
        [string]$Description = "",

        [Parameter(Mandatory = $false)]
        [string]$Version = "1.0.0"
    )

    begin {
        Write-Verbose "Creating golden task suite: $SuiteName"
    }

    process {
        $suite = @{
            suiteName = $SuiteName
            description = $Description
            version = $Version
            createdAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
            taskCount = $Tasks.Count
            tasks = $Tasks
            metadata = @{
                schemaVersion = "1.0"
                compatibleWith = @("1.0.0")
            }
        }

        Write-Verbose "Suite '$SuiteName' created with $($Tasks.Count) tasks"
        return $suite
    }
}
