Set-StrictMode -Version Latest

function Convert-ToHealthDashboardHTML {
    param($Data, $Theme)
    
    $sections = @(Convert-HealthToHtmlSection -Data $Data -ThemeColors $script:HtmlThemes[$Theme])
    
    return @"
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>Pack Health Dashboard</title>
<style>
body { font-family: sans-serif; background: $($script:HtmlThemes[$Theme].bgColor); color: $($script:HtmlThemes[$Theme].textColor); padding: 20px; }
.card { background: $($script:HtmlThemes[$Theme].cardBg); border: 1px solid $($script:HtmlThemes[$Theme].borderColor); border-radius: 8px; padding: 20px; margin-bottom: 20px; }
h2 { color: $($script:HtmlThemes[$Theme].accentColor); }
.metric-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px; }
.metric { text-align: center; padding: 15px; background: rgba(0,0,0,0.2); border-radius: 6px; }
.metric-value { font-size: 2em; font-weight: bold; }
.status-healthy { color: $($script:HtmlThemes[$Theme].healthyColor); }
.status-warning { color: $($script:HtmlThemes[$Theme].warningColor); }
.status-critical { color: $($script:HtmlThemes[$Theme].criticalColor); }
table { width: 100%; border-collapse: collapse; }
th, td { padding: 10px; border-bottom: 1px solid $($script:HtmlThemes[$Theme].borderColor); text-align: left; }
</style></head><body>$($sections -join "`n")</body></html>
"@
}

function Convert-ToRetrievalDashboardHTML {
    param($Data, $Theme)
    
    $sections = @(Convert-RetrievalToHtmlSection -Data $Data -ThemeColors $script:HtmlThemes[$Theme])
    
    return @"
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>Retrieval Activity Dashboard</title>
<style>
body { font-family: sans-serif; background: $($script:HtmlThemes[$Theme].bgColor); color: $($script:HtmlThemes[$Theme].textColor); padding: 20px; }
.card { background: $($script:HtmlThemes[$Theme].cardBg); border: 1px solid $($script:HtmlThemes[$Theme].borderColor); border-radius: 8px; padding: 20px; margin-bottom: 20px; }
h2 { color: $($script:HtmlThemes[$Theme].accentColor); }
.metric-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 15px; }
.metric { text-align: center; padding: 15px; background: rgba(0,0,0,0.2); border-radius: 6px; }
.metric-value { font-size: 2em; font-weight: bold; }
table { width: 100%; border-collapse: collapse; }
th, td { padding: 10px; border-bottom: 1px solid $($script:HtmlThemes[$Theme].borderColor); text-align: left; }
</style></head><body>$($sections -join "`n")</body></html>
"@
}

function Convert-ToGatewayStatusHTML {
    param($Data, $Theme)
    
    $sections = @(Convert-GatewayToHtmlSection -Data $Data -ThemeColors $script:HtmlThemes[$Theme])
    
    return @"
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>MCP Gateway Status</title>
<style>
body { font-family: sans-serif; background: $($script:HtmlThemes[$Theme].bgColor); color: $($script:HtmlThemes[$Theme].textColor); padding: 20px; }
.card { background: $($script:HtmlThemes[$Theme].cardBg); border: 1px solid $($script:HtmlThemes[$Theme].borderColor); border-radius: 8px; padding: 20px; margin-bottom: 20px; }
h2 { color: $($script:HtmlThemes[$Theme].accentColor); }
.metric-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px; }
.metric { text-align: center; padding: 15px; background: rgba(0,0,0,0.2); border-radius: 6px; }
.metric-value { font-size: 2em; font-weight: bold; }
.status-healthy { color: $($script:HtmlThemes[$Theme].healthyColor); }
.status-critical { color: $($script:HtmlThemes[$Theme].criticalColor); }
table { width: 100%; border-collapse: collapse; }
th, td { padding: 10px; border-bottom: 1px solid $($script:HtmlThemes[$Theme].borderColor); text-align: left; }
.badge { padding: 3px 8px; border-radius: 12px; font-size: 0.75em; }
.badge-healthy { background: rgba(78, 201, 176, 0.2); color: $($script:HtmlThemes[$Theme].healthyColor); }
.badge-critical { background: rgba(244, 71, 71, 0.2); color: $($script:HtmlThemes[$Theme].criticalColor); }
</style></head><body>$($sections -join "`n")</body></html>
"@
}

function Convert-ToFederationStatusHTML {
    param($Data, $Theme)
    
    $sections = @(Convert-FederationToHtmlSection -Data $Data -ThemeColors $script:HtmlThemes[$Theme])
    
    return @"
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>Federation Status</title>
<style>
body { font-family: sans-serif; background: $($script:HtmlThemes[$Theme].bgColor); color: $($script:HtmlThemes[$Theme].textColor); padding: 20px; }
.card { background: $($script:HtmlThemes[$Theme].cardBg); border: 1px solid $($script:HtmlThemes[$Theme].borderColor); border-radius: 8px; padding: 20px; margin-bottom: 20px; }
h2 { color: $($script:HtmlThemes[$Theme].accentColor); }
.metric-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px; }
.metric { text-align: center; padding: 15px; background: rgba(0,0,0,0.2); border-radius: 6px; }
.metric-value { font-size: 2em; font-weight: bold; }
.status-healthy { color: $($script:HtmlThemes[$Theme].healthyColor); }
.status-warning { color: $($script:HtmlThemes[$Theme].warningColor); }
table { width: 100%; border-collapse: collapse; }
th, td { padding: 10px; border-bottom: 1px solid $($script:HtmlThemes[$Theme].borderColor); text-align: left; }
.badge { padding: 3px 8px; border-radius: 12px; font-size: 0.75em; }
.badge-healthy { background: rgba(78, 201, 176, 0.2); color: $($script:HtmlThemes[$Theme].healthyColor); }
.badge-warning { background: rgba(220, 220, 170, 0.2); color: $($script:HtmlThemes[$Theme].warningColor); }
</style></head><body>$($sections -join "`n")</body></html>
"@
}

function Convert-ToGraphHTML {
    param($Data, $Theme)
    
    $sections = @(Convert-GraphToHtmlSection -Data $Data -ThemeColors $script:HtmlThemes[$Theme])
    
    return @"
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>Cross-Pack Graph</title>
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
<style>
body { font-family: sans-serif; background: $($script:HtmlThemes[$Theme].bgColor); color: $($script:HtmlThemes[$Theme].textColor); padding: 20px; }
.card { background: $($script:HtmlThemes[$Theme].cardBg); border: 1px solid $($script:HtmlThemes[$Theme].borderColor); border-radius: 8px; padding: 20px; }
h2 { color: $($script:HtmlThemes[$Theme].accentColor); }
.mermaid { text-align: center; }
</style></head><body>$($sections -join "`n")</body></html>
"@
}
