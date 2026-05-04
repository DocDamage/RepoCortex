#requires -Version 5.1
Set-StrictMode -Version Latest

function Export-GoldenTaskReport {
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackId,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet('json', 'html', 'markdown')]
        [string]$Format = 'json',

        [Parameter(Mandatory = $false)]
        [ValidateSet('24h', '7d', '30d', '90d', 'all')]
        [string]$TimeRange = '30d',

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDetails,

        [Parameter(Mandatory = $false)]
        [string]$ProjectRoot = '.'
    )

    begin {
        Write-Verbose "Generating golden task report for pack: $PackId"
    }

    process {
        try {
            # Get score summary
            $score = Get-GoldenTaskScore -PackId $PackId -TimeRange $TimeRange

            # Get detailed results if requested
            $details = @()
            if ($IncludeDetails) {
                $cutoff = switch ($TimeRange) {
                    '24h' { (Get-Date).AddHours(-24) }
                    '7d' { (Get-Date).AddDays(-7) }
                    '30d' { (Get-Date).AddDays(-30) }
                    '90d' { (Get-Date).AddDays(-90) }
                    'all' { [DateTime]::MinValue }
                    default { (Get-Date).AddDays(-7) }
                }
                $details = Get-GoldenTaskResults -PackId $PackId -FromDate $cutoff
            }

            # Build report object
            $report = @{
                ReportMetadata = @{
                    Title = "Golden Task Evaluation Report - $PackId"
                    GeneratedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
                    TimeRange = $TimeRange
                    Format = $Format
                    Version = $script:GoldenTaskConfig.Version
                }
                Summary = $score
                Details = $details
            }

            # Generate output based on format
            switch ($Format) {
                'json' {
                    $content = $report | ConvertTo-Json -Depth 20 -Compress:$false
                }
                'html' {
                    $content = ConvertTo-GoldenTaskHtmlReport -Report $report
                }
                'markdown' {
                    $content = ConvertTo-GoldenTaskMarkdownReport -Report $report
                }
            }

            # Ensure output directory exists
            $outputDir = Split-Path -Parent $OutputPath
            if ($outputDir -and -not (Test-Path $outputDir)) {
                $null = New-Item -ItemType Directory -Path $outputDir -Force
            }

            # Write report
            $content | Out-File -FilePath $OutputPath -Encoding UTF8
            $fileInfo = Get-Item $OutputPath

            Write-Verbose "Report exported to: $OutputPath"
            return $fileInfo
        }
        catch {
            Write-Error "Failed to export golden task report: $_"
            throw
        }
    }
}
