Set-StrictMode -Version Latest

function Convert-ToHealthDashboardHTML {
    param($Data, $Theme, [string]$ProjectRoot = '')

    $sections = @(Convert-HealthToHtmlSection -Data $Data -ThemeColors $script:HtmlThemes[$Theme])
    return New-DashboardHtmlDocument -Title "$($script:ProductBrandName) Pack Health" -Subtitle $script:ProductBrandTagline -Sections $sections -Theme $Theme -MetaItems @("Dashboard v$($Data.version)", "Generated $($Data.generatedAt)") -ProjectRoot $ProjectRoot
}

function Convert-ToRetrievalDashboardHTML {
    param($Data, $Theme, [string]$ProjectRoot = '')

    $sections = @(Convert-RetrievalToHtmlSection -Data $Data -ThemeColors $script:HtmlThemes[$Theme])
    return New-DashboardHtmlDocument -Title "$($script:ProductBrandName) Retrieval" -Subtitle $script:ProductBrandTagline -Sections $sections -Theme $Theme -MetaItems @("Range $($Data.timeRange)", "Dashboard v$($Data.version)") -ProjectRoot $ProjectRoot
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
    param($Data, $Theme, [string]$ProjectRoot = '')

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
    return New-DashboardHtmlDocument -Title "$($script:ProductBrandName) Cross-Pack Graph" -Subtitle $script:ProductBrandTagline -Sections $sections -Theme $Theme -MetaItems @("Dashboard v$($Data.version)", "Generated $($Data.generatedAt)") -ExtraHead $graphHead -ProjectRoot $ProjectRoot
}
