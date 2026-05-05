# Rebrand legacy top-level product naming to Repo Cortex.
param(
    [string]$RootPath = ".",
    [switch]$WhatIf
)

$resolvedRoot = (Resolve-Path -LiteralPath $RootPath).Path
$skipDirectoryNames = @('.git', 'certification-reports', 'security-reports', '__pycache__')
$skipFileNames = @('rebrand.ps1', 'repo_cortex_transparent_logo.png')
$skipFilePrefixes = @('AAA_')
$allowedExtensions = @('.md', '.txt')

$replacements = [ordered]@{
    'CodeMunch \+ ContextLattice \+ MemPalace workflow toolkit' = 'Repo Cortex workflow toolkit'
}

function Test-RebrandSkipPath {
    param([System.IO.FileInfo]$File)

    if ($allowedExtensions -notcontains $File.Extension) {
        return $true
    }

    if ($skipFileNames -contains $File.Name) {
        return $true
    }

    foreach ($prefix in $skipFilePrefixes) {
        if ($File.Name.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }

    $relativePath = $File.FullName.Substring($resolvedRoot.Length)
    foreach ($part in $relativePath.Split([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)) {
        if ($skipDirectoryNames -contains $part) {
            return $true
        }
    }

    return $false
}

$updated = 0
Get-ChildItem -LiteralPath $resolvedRoot -Recurse -File | Where-Object {
    -not (Test-RebrandSkipPath -File $_)
} | ForEach-Object {
    $content = Get-Content -LiteralPath $_.FullName -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrEmpty($content)) { return }

    $newContent = $content
    foreach ($pattern in $replacements.Keys) {
        $newContent = $newContent -replace $pattern, $replacements[$pattern]
    }

    if ($newContent -ne $content) {
        if (-not $WhatIf) {
            Set-Content -LiteralPath $_.FullName -Value $newContent -NoNewline -Encoding UTF8
        }
        $verb = if ($WhatIf) { "Would update" } else { "Updated" }
        Write-Host "$verb $($_.FullName)" -ForegroundColor Green
        $updated++
    }
}

$summaryVerb = if ($WhatIf) { "Would update" } else { "Updated" }
Write-Host "Done. $summaryVerb $updated files." -ForegroundColor Cyan
