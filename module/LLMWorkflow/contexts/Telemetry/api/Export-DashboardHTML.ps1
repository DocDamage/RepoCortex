Set-StrictMode -Version Latest

#===============================================================================
# HTML Export Functions
#===============================================================================

<#
.SYNOPSIS
    Exports combined dashboard to HTML.

.DESCRIPTION
    Combines multiple dashboard views into a single responsive HTML page with
    auto-refresh option and dark/light theme support.

.PARAMETER Views
    Array of views to include: 'Health', 'Retrieval', 'Graph', 'Gateway', 'Federation'.

.PARAMETER Theme
    Theme: 'dark' or 'light'.

.PARAMETER AutoRefreshSeconds
    Auto-refresh interval in seconds (0 to disable).

.PARAMETER ExportPath
    Path to save HTML file.

.PARAMETER ProjectRoot
    Project root directory.

.EXAMPLE
    Export-DashboardHTML -Views @('Health', 'Gateway') -Theme dark -ExportPath 'dashboard.html'
    
    Exports health and gateway dashboards to HTML.

.EXAMPLE
    Export-DashboardHTML -AutoRefreshSeconds 30 -ExportPath 'live-dashboard.html'
    
    Creates auto-refreshing dashboard with all views.

.OUTPUTS
    System.String. The HTML content.
#>
function Export-DashboardHTML {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter()]
        [ValidateSet('Health', 'Retrieval', 'Graph', 'Gateway', 'Federation', 'All')]
        [string[]]$Views = @('All'),
        
        [Parameter()]
        [ValidateSet('dark', 'light')]
        [string]$Theme = 'dark',
        
        [Parameter()]
        [int]$AutoRefreshSeconds = 0,
        
        [Parameter(Mandatory = $true)]
        [string]$ExportPath,
        
        [Parameter()]
        [string]$ProjectRoot = '.'
    )
    
    begin {
        if ($Views -contains 'All') {
            $Views = @('Health', 'Retrieval', 'Graph', 'Gateway', 'Federation')
        }
        
        $themeColors = $script:HtmlThemes[$Theme]
        $refreshMeta = if ($AutoRefreshSeconds -gt 0) { 
            "<meta http-equiv='refresh' content='$AutoRefreshSeconds'>" 
        } else { '' }
        $graphHead = @"
    <!-- Inline mermaid-compatible rendering to avoid CDN dependency -->
    <script>
window.mermaidConfig = {
    startOnLoad: true,
    theme: '$Theme',
    securityLevel: 'loose',
    flowchart: { useMaxWidth: true }
};
function renderMermaid(selector) {
    var elements = document.querySelectorAll(selector || '.mermaid');
    elements.forEach(function(el) {
        var code = el.textContent || el.innerText;
        var pre = document.createElement('pre');
        pre.textContent = code;
        el.innerHTML = '';
        el.appendChild(pre);
    });
}
document.addEventListener('DOMContentLoaded', function() { renderMermaid('.mermaid'); });
    </script>
"@
    }
    
    process {
        $sections = @()
        
        foreach ($view in $Views) {
            switch ($view) {
                'Health' {
                    $healthData = Show-PackHealthDashboard -OutputFormat JSON -ProjectRoot $ProjectRoot | ConvertFrom-Json
                    $sections += Convert-HealthToHtmlSection -Data $healthData -ThemeColors $themeColors
                }
                'Retrieval' {
                    $retrievalData = Show-RetrievalActivityDashboard -OutputFormat JSON -ProjectRoot $ProjectRoot | ConvertFrom-Json
                    $sections += Convert-RetrievalToHtmlSection -Data $retrievalData -ThemeColors $themeColors
                }
                'Graph' {
                    $graphData = Show-CrossPackGraph -OutputFormat JSON -ProjectRoot $ProjectRoot | ConvertFrom-Json
                    $sections += Convert-GraphToHtmlSection -Data $graphData -ThemeColors $themeColors
                }
                'Gateway' {
                    $gatewayData = Show-MCPGatewayStatus -OutputFormat JSON | ConvertFrom-Json
                    $sections += Convert-GatewayToHtmlSection -Data $gatewayData -ThemeColors $themeColors
                }
                'Federation' {
                    $fedData = Show-FederationStatus -OutputFormat JSON | ConvertFrom-Json
                    $sections += Convert-FederationToHtmlSection -Data $fedData -ThemeColors $themeColors
                }
            }
        }
        
        $metaItems = @(
            "Generated $([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))",
            "Views $($Views -join ', ')",
            $(if ($AutoRefreshSeconds -gt 0) { "Auto-refresh $AutoRefreshSeconds seconds" } else { $null })
        )
        $extraHead = @($refreshMeta, $graphHead) -join "`n"
        $html = New-DashboardHtmlDocument -Title "$($script:ProductBrandName) Operations Dashboard" -Subtitle $script:ProductBrandTagline -Sections $sections -Theme $Theme -MetaItems $metaItems -ExtraHead $extraHead -UseGrid
        
        # Ensure directory exists
        $exportDir = Split-Path -Parent $ExportPath
        if ($exportDir -and -not (Test-Path -LiteralPath $exportDir)) {
            New-Item -ItemType Directory -Path $exportDir -Force | Out-Null
        }
        
        $html | Out-File -FilePath $ExportPath -Encoding UTF8
        Write-Host "Dashboard exported to: $ExportPath"
        
        return $html
    }
}
