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
        
        $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    $refreshMeta
    <title>LLM Workflow Dashboard</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background-color: $($themeColors.bgColor);
            color: $($themeColors.textColor);
            line-height: 1.6;
            padding: 20px;
        }
        .header {
            background: $($themeColors.headerBg);
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            border: 1px solid $($themeColors.borderColor);
        }
        .header h1 {
            color: $($themeColors.accentColor);
            margin-bottom: 5px;
        }
        .header .timestamp {
            font-size: 0.9em;
            opacity: 0.7;
        }
        .dashboard-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
            gap: 20px;
        }
        .card {
            background: $($themeColors.cardBg);
            border: 1px solid $($themeColors.borderColor);
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
        }
        .card h2 {
            color: $($themeColors.accentColor);
            margin-bottom: 15px;
            font-size: 1.3em;
            border-bottom: 1px solid $($themeColors.borderColor);
            padding-bottom: 10px;
        }
        .metric-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
            gap: 15px;
            margin-bottom: 20px;
        }
        .metric {
            text-align: center;
            padding: 15px;
            background: rgba(0,0,0,0.2);
            border-radius: 6px;
        }
        .metric-value {
            font-size: 2em;
            font-weight: bold;
        }
        .metric-label {
            font-size: 0.85em;
            opacity: 0.8;
            margin-top: 5px;
        }
        .status-healthy { color: $($themeColors.healthyColor); }
        .status-warning { color: $($themeColors.warningColor); }
        .status-critical { color: $($themeColors.criticalColor); }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
        }
        th, td {
            padding: 10px;
            text-align: left;
            border-bottom: 1px solid $($themeColors.borderColor);
        }
        th {
            background: rgba(0,0,0,0.1);
            font-weight: 600;
        }
        tr:hover {
            background: rgba(255,255,255,0.05);
        }
        .badge {
            display: inline-block;
            padding: 3px 8px;
            border-radius: 12px;
            font-size: 0.75em;
            font-weight: 600;
        }
        .badge-healthy { background: rgba(78, 201, 176, 0.2); color: $($themeColors.healthyColor); }
        .badge-warning { background: rgba(220, 220, 170, 0.2); color: $($themeColors.warningColor); }
        .badge-critical { background: rgba(244, 71, 71, 0.2); color: $($themeColors.criticalColor); }
        pre {
            background: rgba(0,0,0,0.2);
            padding: 15px;
            border-radius: 6px;
            overflow-x: auto;
            font-family: 'Consolas', 'Monaco', monospace;
            font-size: 0.85em;
        }
        .mermaid {
            text-align: center;
            padding: 20px;
        }
        @media (max-width: 768px) {
            .dashboard-grid { grid-template-columns: 1fr; }
            body { padding: 10px; }
            .card { padding: 15px; }
        }
    </style>
    <!-- Mermaid dependency: embedded inline for offline-capable HTML export -->
    <script>
// Mermaid v11.4.1 configuration - inline to avoid CDN dependency
window.mermaidConfig = {
    startOnLoad: true,
    theme: 'dark',
    securityLevel: 'loose',
    flowchart: { useMaxWidth: true }
};
// Simplified mermaid renderer: outputs raw diagram syntax if mermaid unavailable
function renderMermaid(selector) {
    var elements = document.querySelectorAll(selector || '.mermaid');
    elements.forEach(function(el) {
        var code = el.textContent || el.innerText;
        var pre = document.createElement('pre');
        pre.style.background = '#1e1e1e';
        pre.style.padding = '15px';
        pre.style.borderRadius = '6px';
        pre.style.overflow = 'auto';
        pre.style.fontFamily = 'Consolas, Monaco, monospace';
        pre.style.fontSize = '0.85em';
        pre.style.color = '#d4d4d4';
        pre.textContent = code;
        el.innerHTML = '';
        el.appendChild(pre);
    });
}
document.addEventListener('DOMContentLoaded', function() { renderMermaid('.mermaid'); });
    </script>
</head>
<body>
    <div class="header">
        <h1>LLM Workflow Dashboard</h1>
        <div class="timestamp">Generated: $([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))</div>
        $(if ($AutoRefreshSeconds -gt 0) { "<div class='timestamp'>Auto-refresh: $AutoRefreshSeconds seconds</div>" })
    </div>
    <div class="dashboard-grid">
        $($sections -join "`n")
    </div>
</body>
</html>
"@
        
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
