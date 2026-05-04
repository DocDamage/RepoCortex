Set-StrictMode -Version Latest

#===============================================================================
# Pack Health Dashboard
#===============================================================================

<#
.SYNOPSIS
    Displays pack health overview dashboard.

.DESCRIPTION
    Shows health scores, status indicators, freshness, source counts, and
    validation status for all packs. Output can be formatted as console table
    or exported to HTML.

.PARAMETER PackId
    Optional specific pack ID to show. If not specified, shows all packs.

.PARAMETER OutputFormat
    Output format: 'Console', 'HTML', or 'JSON'.

.PARAMETER ProjectRoot
    Project root directory. Defaults to current directory.

.PARAMETER UseAnsi
    Use ANSI color codes in console output.

.PARAMETER IncludeDetails
    Include detailed component breakdown.

.EXAMPLE
    Show-PackHealthDashboard
    
    Displays health dashboard for all packs in console.

.EXAMPLE
    Show-PackHealthDashboard -PackId 'rpgmaker-mz' -OutputFormat HTML -ExportPath 'health.html'
    
    Exports health dashboard for specific pack to HTML.

.OUTPUTS
    System.Collections.Hashtable or file output based on format.
#>
function Show-PackHealthDashboard {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter()]
        [string]$PackId = '',
        
        [Parameter()]
        [ValidateSet('Console', 'HTML', 'JSON')]
        [string]$OutputFormat = 'Console',
        
        [Parameter()]
        [string]$ProjectRoot = '.',
        
        [Parameter()]
        [switch]$UseAnsi,
        
        [Parameter()]
        [switch]$IncludeDetails,
        
        [Parameter()]
        [string]$ExportPath = ''
    )
    
    begin {
        $useAnsiColors = $UseAnsi -or (Test-AnsiSupport)
        $healthScorePath = Join-Path $PSScriptRoot 'workflow/HealthScore.ps1'
        
        # Import HealthScore module if available
        if (Test-Path -LiteralPath $healthScorePath) {
            . $healthScorePath
        }
        
        $dashboardData = @{
            generatedAt = [DateTime]::UtcNow.ToString('o')
            version = $script:DashboardVersion
            packs = @()
            summary = @{
                totalPacks = 0
                healthy = 0
                degraded = 0
                critical = 0
                averageScore = 0
            }
        }
    }
    
    process {
        # Get pack list
        $packs = if ($PackId) {
            @(@{ packId = $PackId })
        }
        else {
            Get-PackList -ProjectRoot $ProjectRoot
        }
        
        $totalScore = 0
        
        foreach ($pack in $packs) {
            $packHealth = $null
            
            # Try to get health score
            try {
                $healthCmd = Get-DashboardCommand -CommandName 'Test-PackHealth'
                if ($healthCmd) {
                    $packHealth = Test-PackHealth -PackId $pack.packId
                }
                else {
                    # Fallback: basic health check
                    $packHealth = Get-BasicPackHealth -PackId $pack.packId -ProjectRoot $ProjectRoot
                }
            }
            catch {
                Write-Warning "Failed to get health for pack '$($pack.packId)': $_"
                $packHealth = @{
                    packId = $pack.packId
                    overallScore = 0
                    status = 'Critical'
                    error = $_.ToString()
                }
            }
            
            $packEntry = @{
                packId = $pack.packId
                score = $packHealth.overallScore
                status = $packHealth.status
                severity = if ($packHealth.severity) { $packHealth.severity } else { $packHealth.status }
                warnings = if ($packHealth.warnings) { $packHealth.warnings.Count } else { 0 }
                criticalIssues = if ($packHealth.criticalIssues) { $packHealth.criticalIssues.Count } else { 0 }
                rawMetrics = $packHealth.rawMetrics
                components = if ($IncludeDetails) { $packHealth.components } else { $null }
            }
            
            $dashboardData.packs += $packEntry
            $totalScore += $packHealth.overallScore
            
            # Update summary counts
            switch ($packHealth.status) {
                'Healthy' { $dashboardData.summary.healthy++ }
                'Degraded' { $dashboardData.summary.degraded++ }
                'Critical' { $dashboardData.summary.critical++ }
            }
        }
        
        $dashboardData.summary.totalPacks = $packs.Count
        $dashboardData.summary.averageScore = if ($packs.Count -gt 0) { 
            [math]::Round($totalScore / $packs.Count) 
        } else { 0 }
        
        # Output based on format
        switch ($OutputFormat) {
            'Console' {
                Write-ConsoleHealthDashboard -Data $dashboardData -UseAnsi:$useAnsiColors -IncludeDetails:$IncludeDetails
            }
            'HTML' {
                $html = Convert-ToHealthDashboardHTML -Data $dashboardData -Theme 'dark'
                if ($ExportPath) {
                    $html | Out-File -FilePath $ExportPath -Encoding UTF8
                    Write-Host "Health dashboard exported to: $ExportPath"
                }
                return $html
            }
            'JSON' {
                $json = $dashboardData | ConvertTo-Json -Depth 10
                if ($ExportPath) {
                    $json | Out-File -FilePath $ExportPath -Encoding UTF8
                    Write-Host "Health dashboard exported to: $ExportPath"
                }
                return $json
            }
        }
        
        return $dashboardData
    }
}
