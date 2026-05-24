Set-StrictMode -Version Latest

function New-DashboardHtmlHeader {
    param(
        [string]$Title,
        [string]$Subtitle,
        [string[]]$MetaItems = @(),
        [string]$BrandAssetUri = ''
    )

    $metaHtml = $MetaItems | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object {
        "<span class='meta-chip'>$($_)</span>"
    }
    $brandMarkHtml = if ([string]::IsNullOrWhiteSpace($BrandAssetUri)) {
        '<div class="brand-mark">RC</div>'
    }
    else {
        "<img class=`"brand-mark brand-mark-image`" src=`"$BrandAssetUri`" alt=`"Repo Cortex ModernUI mark`">"
    }

    return @"
<header class="brand-header">
    <div class="brand-lockup">
        $brandMarkHtml
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
        [string]$ProjectRoot = '',
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
    $brandAssetUri = Get-DashboardModernUIAssetDataUri -ProjectRoot $ProjectRoot -RelativeCandidates @(
        'ModernUI\48x48\Modern_UI_Gamepad_48x48.png',
        'ModernUI\32x32\Modern_UI_Gamepad_32x32.png',
        'ModernUI\16x16\Modern_UI_Gamepad.png'
    )
    $styleOneAssetUri = Get-DashboardModernUIAssetDataUri -ProjectRoot $ProjectRoot -RelativeCandidates @(
        'ModernUI\48x48\Modern_UI_Style_1_48x48.png',
        'ModernUI\32x32\Modern_UI_Style_1_32x32.png',
        'ModernUI\16x16\Modern_UI_Style_1.png'
    )
    $styleTwoAssetUri = Get-DashboardModernUIAssetDataUri -ProjectRoot $ProjectRoot -RelativeCandidates @(
        'ModernUI\48x48\Modern_UI_Style_2_48x48.png',
        'ModernUI\32x32\Modern_UI_Style_2_32x32.png',
        'ModernUI\16x16\Modern_UI_Style_2.png'
    )
    $actionAssetUri = Get-DashboardModernUIAssetDataUri -ProjectRoot $ProjectRoot -RelativeCandidates @(
        'ModernUI\48x48\Animated_48x48\Modern_UI_Button_Trash_48x48_1.gif',
        'ModernUI\32x32\Animated_32x32\Modern_UI_Button_Trash_32x32_1.gif',
        'ModernUI\16x16\Animated\Modern_UI_Button_Trash_1.gif'
    )
    $modernUIAssets = @{
        Brand = $brandAssetUri
        StyleOne = $styleOneAssetUri
        StyleTwo = $styleTwoAssetUri
        Action = $actionAssetUri
    }
    $modernUIEnabled = if ([string]::IsNullOrWhiteSpace($brandAssetUri)) { 'false' } else { 'true' }
    $header = New-DashboardHtmlHeader -Title $Title -Subtitle $Subtitle -MetaItems $MetaItems -BrandAssetUri $brandAssetUri
    $modernUIChrome = if ($modernUIEnabled -eq 'true') { New-DashboardModernUIChrome -Assets $modernUIAssets } else { '' }

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
<body data-modern-ui="$modernUIEnabled">
<main class="page-shell">
$header
$modernUIChrome
$content
</main>
</body>
</html>
"@
}
