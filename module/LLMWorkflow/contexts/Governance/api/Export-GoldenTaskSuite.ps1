#requires -Version 5.1
Set-StrictMode -Version Latest

function Export-GoldenTaskSuite {
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $true)]
        [hashtable]$Suite,

        [Parameter(Mandatory = $false)]
        [switch]$Compress
    )

    begin {
        Write-Verbose "Exporting golden task suite to: $OutputPath"
    }

    process {
        try {
            $jsonParams = @{
                Depth = 10
            }
            if ($Compress) {
                $jsonParams.Compress = $true
            }

            $json = $Suite | ConvertTo-Json @jsonParams

            # Ensure directory exists
            $directory = Split-Path -Parent $OutputPath
            if ($directory -and -not (Test-Path $directory)) {
                $null = New-Item -ItemType Directory -Path $directory -Force
            }

            $json | Out-File -FilePath $OutputPath -Encoding UTF8
            $fileInfo = Get-Item $OutputPath

            Write-Verbose "Suite exported successfully to: $OutputPath"
            return $fileInfo
        }
        catch {
            Write-Error "Failed to export suite: $_"
            throw
        }
    }
}
