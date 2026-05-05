Set-StrictMode -Version Latest

function Get-LLMWorkflowCockpitAssetDataUri {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string[]]$RelativeCandidates
    )

    foreach ($relativePath in $RelativeCandidates) {
        $assetPath = Join-Path $ProjectRoot $relativePath
        if (Test-Path -LiteralPath $assetPath) {
            $extension = [IO.Path]::GetExtension($assetPath).TrimStart('.').ToLowerInvariant()
            if ($extension -eq 'jpg') {
                $extension = 'jpeg'
            }
            $bytes = [IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $assetPath).Path)
            return "data:image/$extension;base64,$([Convert]::ToBase64String($bytes))"
        }
    }

    return ''
}

function Export-LLMWorkflowCockpit {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter()]
        [string]$ProjectRoot = '.',

        [Parameter(Mandatory = $true)]
        [string]$ExportPath
    )

    $resolvedRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
    $nextAction = Get-LLMWorkflowNextAction -ProjectRoot $resolvedRoot
    $versionPath = Join-Path $resolvedRoot 'VERSION'
    $version = if (Test-Path -LiteralPath $versionPath) { (Get-Content -LiteralPath $versionPath -Raw).Trim() } else { 'missing' }
    $reportDir = Join-Path $resolvedRoot 'certification-reports'
    $latestReport = $null
    if (Test-Path -LiteralPath $reportDir) {
        $latestReport = Get-ChildItem -LiteralPath $reportDir -Filter '*.json' -File |
            Sort-Object LastWriteTimeUtc, Name -Descending |
            Select-Object -First 1
    }
    $releaseEvidence = if ($latestReport) { $latestReport.Name } else { 'No certification report found' }
    $security = Test-LLMWorkflowSecurityExceptions -ProjectRoot $resolvedRoot
    $brandAsset = Get-LLMWorkflowCockpitAssetDataUri -ProjectRoot $resolvedRoot -RelativeCandidates @(
        'ModernUI\16x16\Modern_UI_Gamepad.png',
        'ModernUI\32x32\Modern_UI_Gamepad_32x32.png',
        'ModernUI\48x48\Modern_UI_Gamepad_48x48.png'
    )
    $styleAsset = Get-LLMWorkflowCockpitAssetDataUri -ProjectRoot $resolvedRoot -RelativeCandidates @(
        'ModernUI\16x16\Modern_UI_Style_1.png',
        'ModernUI\32x32\Modern_UI_Style_1_32x32.png',
        'ModernUI\48x48\Modern_UI_Style_1_48x48.png'
    )
    $hasModernUI = (-not [string]::IsNullOrWhiteSpace($brandAsset)) -or (-not [string]::IsNullOrWhiteSpace($styleAsset))
    $modernUiAttr = if ($hasModernUI) { 'true' } else { 'false' }
    $brandImage = if ($brandAsset) {
        "<img class=""pixel-mark"" src=""$brandAsset"" alt=""Repo Cortex ModernUI mark"">"
    }
    else {
        '<span class="pixel-fallback">RC</span>'
    }
    $styleImage = if ($styleAsset) {
        "<img class=""asset-strip"" src=""$styleAsset"" alt=""ModernUI interface asset strip"">"
    }
    else {
        ''
    }

    $htmlDir = Split-Path -Parent $ExportPath
    if ($htmlDir -and -not (Test-Path -LiteralPath $htmlDir)) {
        New-Item -ItemType Directory -Path $htmlDir -Force | Out-Null
    }

    $actionText = [System.Net.WebUtility]::HtmlEncode($nextAction.Action)
    $evidenceText = [System.Net.WebUtility]::HtmlEncode($nextAction.Evidence)
    $releaseText = [System.Net.WebUtility]::HtmlEncode($releaseEvidence)
    $statusText = [System.Net.WebUtility]::HtmlEncode($nextAction.Status)
    $areaText = [System.Net.WebUtility]::HtmlEncode($nextAction.Area)
    $html = @"
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>Repo Cortex Cockpit</title>
  <style>
    :root{--ink:#17202a;--panel:#fffaf0;--line:#2f3c4f;--mint:#58c7a3;--amber:#f2b84b;--red:#d95f59;--blue:#5579c6;--paper:#f5efe3}
    *{box-sizing:border-box}
    body{font-family:Segoe UI,Arial,sans-serif;margin:0;background:var(--paper);color:var(--ink)}
    .shell{max-width:1120px;margin:0 auto;padding:24px}
    .topbar{display:flex;align-items:center;justify-content:space-between;gap:16px;border:3px solid var(--line);background:#fcfbf7;padding:14px 16px;box-shadow:6px 6px 0 #c9c0ad}
    .brand{display:flex;align-items:center;gap:12px;min-width:0}
    .pixel-mark,.pixel-fallback{width:48px;height:48px;border:3px solid var(--line);background:#fff;image-rendering:pixelated;object-fit:cover;flex:0 0 auto}
    .pixel-fallback{display:grid;place-items:center;font-weight:800}
    h1{font-size:26px;line-height:1.1;margin:0}
    .subtitle{margin:4px 0 0;color:#4c5565}
    .grid{display:grid;grid-template-columns:repeat(12,1fr);gap:16px;margin-top:20px}
    section,.metric{border:3px solid var(--line);background:var(--panel);box-shadow:5px 5px 0 #c9c0ad}
    section{padding:18px}
    .metric{grid-column:span 3;padding:14px;min-height:98px}
    .wide{grid-column:span 8}.side{grid-column:span 4}.full{grid-column:1/-1}
    .label{color:#4c5565;font-size:11px;text-transform:uppercase;font-weight:800}
    .value{font-size:24px;font-weight:800;margin-top:8px}
    h2{font-size:17px;margin:0 0 12px}
    .badge{display:inline-block;border:2px solid var(--line);background:var(--mint);padding:5px 8px;font-weight:800}
    .badge.blocked{background:var(--red);color:#fff}.badge.ready{background:var(--mint)}.badge.review{background:var(--amber)}
    .asset-strip{width:100%;max-height:96px;object-fit:contain;image-rendering:pixelated;border:2px solid var(--line);background:#fff;margin-top:12px}
    .footer{margin-top:16px;color:#596273;font-size:12px}
    @media (max-width:760px){.grid{grid-template-columns:1fr}.metric,.wide,.side{grid-column:1/-1}.topbar{align-items:flex-start;flex-direction:column}}
  </style>
</head>
<body data-modern-ui="$modernUiAttr">
  <main class="shell">
    <header class="topbar">
      <div class="brand">
        $brandImage
        <div>
          <h1>Repo Cortex Cockpit</h1>
          <p class="subtitle">ModernUI operations surface</p>
        </div>
      </div>
      <span class="badge $($nextAction.Status.ToLowerInvariant())">$statusText</span>
    </header>
    <div class="grid">
      <div class="metric"><div class="label">Version</div><div class="value">$([System.Net.WebUtility]::HtmlEncode($version))</div></div>
      <div class="metric"><div class="label">Priority</div><div class="value">$($nextAction.Priority)</div></div>
      <div class="metric"><div class="label">Area</div><div class="value">$areaText</div></div>
      <div class="metric"><div class="label">Security Exceptions</div><div class="value">$($security.Total)</div></div>
    <section class="wide">
      <h2>Next Action</h2>
      <p><strong>$([System.Net.WebUtility]::HtmlEncode($nextAction.ActionId))</strong>: $actionText</p>
      <p>$evidenceText</p>
    </section>
    <section class="side">
      <h2>Release Evidence</h2>
      <p>$releaseText</p>
      $styleImage
    </section>
    </div>
    <p class="footer">ModernUI assets detected: $modernUiAttr. Asset license: ModernUI CC0/public-domain style license.</p>
  </main>
</body>
</html>
"@
    Set-Content -LiteralPath $ExportPath -Value $html -Encoding UTF8

    return [pscustomobject][ordered]@{
        ExportPath = $ExportPath
        ProjectRoot = $resolvedRoot
        NextAction = $nextAction
        ReleaseEvidence = $releaseEvidence
    }
}
