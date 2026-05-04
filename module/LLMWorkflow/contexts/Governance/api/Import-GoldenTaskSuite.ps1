#requires -Version 5.1
Set-StrictMode -Version Latest

function Import-GoldenTaskSuite {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$ValidateOnly
    )

    begin {
        Write-Verbose "Importing golden task suite from: $Path"
    }

    process {
        try {
            if (-not (Test-Path $Path)) {
                throw "Suite file not found: $Path"
            }

            $content = Get-Content -Path $Path -Raw -Encoding UTF8
            $suite = $content | ConvertFrom-Json

            # Convert to hashtable recursively
            $suiteObj = ConvertTo-Hashtable -InputObject $suite

            # Validate structure
            $requiredFields = @('suiteName', 'tasks', 'version')
            foreach ($field in $requiredFields) {
                if (-not $suiteObj.ContainsKey($field)) {
                    throw "Invalid suite: missing required field '$field'"
                }
            }

            if ($ValidateOnly) {
                Write-Verbose "Suite validation passed"
                return @{ Valid = $true; SuiteName = $suiteObj.suiteName }
            }

            Write-Verbose "Suite '$($suiteObj.suiteName)' imported successfully with $($suiteObj.tasks.Count) tasks"
            return $suiteObj
        }
        catch {
            Write-Error "Failed to import suite: $_"
            throw
        }
    }
}
