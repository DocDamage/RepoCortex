Set-StrictMode -Version Latest

#===============================================================================
# MCP Gateway Status
#===============================================================================

<#
.SYNOPSIS
    Displays MCP gateway status dashboard.

.DESCRIPTION
    Shows connected pack servers, tool counts per pack, circuit breaker states,
    request rates, error rates, and health indicators.

.PARAMETER OutputFormat
    Output format: 'Console', 'HTML', or 'JSON'.

.PARAMETER UseAnsi
    Use ANSI color codes.

.PARAMETER ExportPath
    Path to export output.

.EXAMPLE
    Show-MCPGatewayStatus
    
    Displays current MCP gateway status.

.OUTPUTS
    System.Collections.Hashtable or formatted output.
#>
function Show-MCPGatewayStatus {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter()]
        [ValidateSet('Console', 'HTML', 'JSON')]
        [string]$OutputFormat = 'Console',
        
        [Parameter()]
        [switch]$UseAnsi,
        
        [Parameter()]
        [string]$ExportPath = ''
    )
    
    begin {
        $useAnsiColors = $UseAnsi -or (Test-AnsiSupport)
        
        $statusData = @{
            generatedAt = [DateTime]::UtcNow.ToString('o')
            version = $script:DashboardVersion
            gatewayStatus = @{
                isRunning = $false
                uptime = ''
                routeCount = 0
                sessionCount = 0
            }
            routes = @()
            circuitBreakers = @()
        }
    }
    
    process {
        # Try to get gateway status from MCP module
        $gatewayStatus = $null
        try {
            $statusCmd = Get-DashboardCommand -CommandName 'Get-MCPCompositeGatewayStatus'
            if ($statusCmd) {
                $gatewayStatus = Get-MCPCompositeGatewayStatus
            }
        }
        catch {
            Write-Verbose "MCP Gateway not running or not available"
        }
        
        if ($gatewayStatus) {
            $statusData.gatewayStatus = @{
                isRunning = $gatewayStatus.isRunning
                uptime = $gatewayStatus.uptime
                routeCount = $gatewayStatus.routeCount
                enabledRouteCount = $gatewayStatus.enabledRouteCount
                sessionCount = $gatewayStatus.sessionCount
                activeSessions = $gatewayStatus.activeSessions
            }
            
            # Circuit breakers
            if ($gatewayStatus.circuitBreakerStates) {
                foreach ($cb in $gatewayStatus.circuitBreakerStates.GetEnumerator()) {
                    $statusData.circuitBreakers += @{
                        packId = $cb.Key
                        state = $cb.Value.state
                        failureCount = $cb.Value.failureCount
                        successCount = $cb.Value.successCount
                        lastFailureAt = $cb.Value.lastFailureAt
                    }
                }
            }
        }
        # Note: When MCP gateway is not running, statusData retains its default
        # (isRunning = $false, empty routes/breakers) to distinguish
        # "not connected" from "connected but idle"
        
        # Output
        switch ($OutputFormat) {
            'Console' {
                Write-ConsoleGatewayStatus -Data $statusData -UseAnsi:$useAnsiColors
            }
            'HTML' {
                $html = Convert-ToGatewayStatusHTML -Data $statusData -Theme 'dark'
                if ($ExportPath) {
                    $html | Out-File -FilePath $ExportPath -Encoding UTF8
                }
                return $html
            }
            'JSON' {
                $json = $statusData | ConvertTo-Json -Depth 10
                if ($ExportPath) {
                    $json | Out-File -FilePath $ExportPath -Encoding UTF8
                }
                return $json
            }
        }
        
        return $statusData
    }
}
