Set-StrictMode -Version Latest

function Get-DashboardHtmlStyles {
    param($ThemeColors)

    return @"
        :root {
            --rc-bg: $($ThemeColors.bgColor); --rc-surface: $($ThemeColors.cardBg);
            --rc-surface-strong: $($ThemeColors.headerBg); --rc-text: $($ThemeColors.textColor);
            --rc-muted: $($ThemeColors.mutedTextColor); --rc-border: $($ThemeColors.borderColor);
            --rc-accent: $($ThemeColors.accentColor); --rc-accent-2: $($ThemeColors.accentColor2);
            --rc-good: $($ThemeColors.healthyColor); --rc-warn: $($ThemeColors.warningColor);
            --rc-bad: $($ThemeColors.criticalColor); --rc-shadow: $($ThemeColors.shadowColor);
            --rc-stripe: $($ThemeColors.tableStripe);
        }
        * { box-sizing: border-box; }
        body {
            margin: 0; color: var(--rc-text); line-height: 1.5; padding: 28px;
            font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            background:
                radial-gradient(circle at top left, color-mix(in srgb, var(--rc-accent) 18%, transparent), transparent 30rem),
                linear-gradient(180deg, var(--rc-bg), var(--rc-bg));
        }
        .page-shell { max-width: 1440px; margin: 0 auto; }
        .brand-header {
            display: flex; justify-content: space-between; align-items: flex-end;
            gap: 24px; padding: 24px; margin-bottom: 22px;
            background: linear-gradient(135deg, var(--rc-surface-strong), var(--rc-surface));
            border: 1px solid var(--rc-border); border-radius: 8px;
            box-shadow: 0 18px 50px var(--rc-shadow);
        }
        .brand-lockup { display: flex; align-items: center; gap: 16px; min-width: 0; }
        .brand-mark {
            width: 52px; height: 52px; display: grid; place-items: center; flex: 0 0 auto;
            border: 1px solid color-mix(in srgb, var(--rc-accent) 45%, var(--rc-border));
            border-radius: 8px;
            background: linear-gradient(135deg, color-mix(in srgb, var(--rc-accent) 28%, transparent), color-mix(in srgb, var(--rc-accent-2) 24%, transparent));
            color: var(--rc-text); font-weight: 800; letter-spacing: 0;
        }
        .brand-title { margin: 0; color: var(--rc-text); font-size: clamp(1.55rem, 2.4vw, 2.25rem); line-height: 1.05; letter-spacing: 0; }
        .brand-subtitle { margin-top: 6px; color: var(--rc-muted); font-size: 0.95rem; }
        .brand-meta {
            display: flex; flex-wrap: wrap; justify-content: flex-end; gap: 8px;
            color: var(--rc-muted); font-size: 0.82rem;
        }
        .meta-chip { border: 1px solid var(--rc-border); border-radius: 8px; padding: 6px 9px; background: color-mix(in srgb, var(--rc-surface) 82%, transparent); white-space: nowrap; }
        .dashboard-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(360px, 1fr)); gap: 18px; align-items: start; }
        .card {
            background: var(--rc-surface); border: 1px solid var(--rc-border); border-radius: 8px;
            padding: 20px; margin-bottom: 18px; box-shadow: 0 12px 32px var(--rc-shadow); overflow: hidden;
        }
        .card h2, .card h3 { color: var(--rc-text); margin: 0 0 14px; letter-spacing: 0; }
        .card h2 { font-size: 1.08rem; padding-bottom: 10px; border-bottom: 1px solid var(--rc-border); }
        .card h3 { margin-top: 18px; font-size: 0.92rem; color: var(--rc-muted); text-transform: uppercase; }
        .metric-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(118px, 1fr)); gap: 12px; margin-bottom: 18px; }
        .metric {
            min-height: 88px; display: flex; flex-direction: column; justify-content: center;
            gap: 4px; padding: 14px;
            background: color-mix(in srgb, var(--rc-bg) 55%, var(--rc-surface));
            border: 1px solid color-mix(in srgb, var(--rc-border) 70%, transparent);
            border-radius: 8px;
        }
        .metric-value { color: var(--rc-text); font-size: 1.65rem; line-height: 1; font-weight: 800; }
        .metric-label { color: var(--rc-muted); font-size: 0.78rem; font-weight: 600; text-transform: uppercase; }
        .status-healthy { color: var(--rc-good); }
        .status-warning { color: var(--rc-warn); }
        .status-critical { color: var(--rc-bad); }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; font-size: 0.9rem; }
        th, td {
            padding: 10px 12px; text-align: left;
            border-bottom: 1px solid var(--rc-border); vertical-align: middle;
        }
        th {
            color: var(--rc-muted); background: var(--rc-stripe);
            font-size: 0.76rem; font-weight: 700; text-transform: uppercase;
        }
        tr:hover { background: var(--rc-stripe); }
        .badge {
            display: inline-flex; align-items: center; min-height: 24px; padding: 3px 8px;
            border-radius: 8px; font-size: 0.75rem; font-weight: 700; border: 1px solid currentColor;
        }
        .badge-healthy { background: color-mix(in srgb, var(--rc-good) 14%, transparent); color: var(--rc-good); }
        .badge-warning { background: color-mix(in srgb, var(--rc-warn) 16%, transparent); color: var(--rc-warn); }
        .badge-critical { background: color-mix(in srgb, var(--rc-bad) 14%, transparent); color: var(--rc-bad); }
        pre {
            background: color-mix(in srgb, var(--rc-bg) 62%, black); padding: 15px;
            border-radius: 8px; overflow-x: auto;
            font-family: 'Cascadia Mono', 'Consolas', 'Monaco', monospace;
            font-size: 0.84rem; color: var(--rc-text);
        }
        .mermaid { text-align: left; padding: 0; }
        @media (max-width: 760px) {
            body { padding: 14px; }
            .brand-header { align-items: flex-start; flex-direction: column; padding: 18px; }
            .brand-lockup { align-items: flex-start; flex-direction: column; gap: 12px; }
            .brand-meta { justify-content: flex-start; }
            .dashboard-grid { grid-template-columns: 1fr; }
            .card { padding: 15px; }
            table { display: block; overflow-x: auto; white-space: nowrap; }
        }
"@
}

function New-DashboardHtmlHeader {
    param(
        [string]$Title,
        [string]$Subtitle,
        [string[]]$MetaItems = @()
    )

    $metaHtml = $MetaItems | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object {
        "<span class='meta-chip'>$($_)</span>"
    }

    return @"
<header class="brand-header">
    <div class="brand-lockup">
        <div class="brand-mark">RC</div>
        <div>
            <h1 class="brand-title">$Title</h1>
            <div class="brand-subtitle">$Subtitle</div>
        </div>
    </div>
    <div class="brand-meta">
        $($metaHtml -join "`n")
    </div>
</header>
"@
}

function New-DashboardHtmlDocument {
    param(
        [string]$Title,
        [string]$Subtitle,
        [string[]]$Sections,
        [string]$Theme,
        [string[]]$MetaItems = @(),
        [string]$ExtraHead = '',
        [switch]$UseGrid
    )

    $themeColors = $script:HtmlThemes[$Theme]
    $content = if ($UseGrid) {
        "<div class='dashboard-grid'>$($Sections -join "`n")</div>"
    }
    else {
        $Sections -join "`n"
    }
    $styles = Get-DashboardHtmlStyles -ThemeColors $themeColors
    $header = New-DashboardHtmlHeader -Title $Title -Subtitle $Subtitle -MetaItems $MetaItems

    return @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>$Title</title>
$ExtraHead
<style>
$styles
</style>
</head>
<body>
<main class="page-shell">
$header
$content
</main>
</body>
</html>
"@
}

function Convert-ToHealthDashboardHTML {
    param($Data, $Theme)
    
    $sections = @(Convert-HealthToHtmlSection -Data $Data -ThemeColors $script:HtmlThemes[$Theme])
    return New-DashboardHtmlDocument -Title "$($script:ProductBrandName) Pack Health" -Subtitle $script:ProductBrandTagline -Sections $sections -Theme $Theme -MetaItems @("Dashboard v$($Data.version)", "Generated $($Data.generatedAt)")
}

function Convert-ToRetrievalDashboardHTML {
    param($Data, $Theme)
    
    $sections = @(Convert-RetrievalToHtmlSection -Data $Data -ThemeColors $script:HtmlThemes[$Theme])
    return New-DashboardHtmlDocument -Title "$($script:ProductBrandName) Retrieval" -Subtitle $script:ProductBrandTagline -Sections $sections -Theme $Theme -MetaItems @("Range $($Data.timeRange)", "Dashboard v$($Data.version)")
}

function Convert-ToGatewayStatusHTML {
    param($Data, $Theme)
    
    $sections = @(Convert-GatewayToHtmlSection -Data $Data -ThemeColors $script:HtmlThemes[$Theme])
    return New-DashboardHtmlDocument -Title "$($script:ProductBrandName) MCP Gateway" -Subtitle $script:ProductBrandTagline -Sections $sections -Theme $Theme -MetaItems @("Dashboard v$($Data.version)", "Generated $($Data.generatedAt)")
}

function Convert-ToFederationStatusHTML {
    param($Data, $Theme)
    
    $sections = @(Convert-FederationToHtmlSection -Data $Data -ThemeColors $script:HtmlThemes[$Theme])
    return New-DashboardHtmlDocument -Title "$($script:ProductBrandName) Federation" -Subtitle $script:ProductBrandTagline -Sections $sections -Theme $Theme -MetaItems @("Dashboard v$($Data.version)", "Generated $($Data.generatedAt)")
}

function Convert-ToGraphHTML {
    param($Data, $Theme)
    
    $sections = @(Convert-GraphToHtmlSection -Data $Data -ThemeColors $script:HtmlThemes[$Theme])
    
    $graphHead = @"
    <!-- Inline mermaid-compatible rendering to avoid CDN dependency -->
    <script>
window.mermaidConfig = { startOnLoad: true, theme: 'dark', securityLevel: 'loose' };
function renderMermaid(selector) {
    var elements = document.querySelectorAll(selector || '.mermaid');
    elements.forEach(function(el) {
        var code = el.textContent || el.innerText;
        var pre = document.createElement('pre');
        pre.style.background = '#1e1e1e'; pre.style.padding = '15px';
        pre.style.borderRadius = '6px'; pre.style.overflow = 'auto';
        pre.style.fontFamily = 'Consolas, Monaco, monospace';
        pre.style.fontSize = '0.85em'; pre.style.color = '#d4d4d4';
        pre.textContent = code; el.innerHTML = ''; el.appendChild(pre);
    });
}
document.addEventListener('DOMContentLoaded', function() { renderMermaid('.mermaid'); });
    </script>
"@
    return New-DashboardHtmlDocument -Title "$($script:ProductBrandName) Cross-Pack Graph" -Subtitle $script:ProductBrandTagline -Sections $sections -Theme $Theme -MetaItems @("Dashboard v$($Data.version)", "Generated $($Data.generatedAt)") -ExtraHead $graphHead
}
