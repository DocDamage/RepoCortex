#Requires -Version 5.1
<#
.SYNOPSIS
    Repairs mojibake (UTF-8 bytes misread as Windows-1252) in release-facing markdown docs.
.DESCRIPTION
    Reads each file as raw bytes, decodes as UTF-8, applies a replacement table for common
    Windows-1252 misread sequences, then writes back as UTF-8 (no BOM) only when changes occur.
#>
[CmdletBinding()]
param(
    [string]$ProjectRoot = "",
    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path
}

$releaseDocs = @(
    "README.md",
    "PROGRESS.md",
    "docs\implementation\PROGRESS.md",
    "docs\implementation\REMAINING_WORK.md",
    "docs\releases\RELEASE_STATE.md",
    "docs\releases\V1_RELEASE_CRITERIA.md",
    "docs\releases\RELEASE_CERTIFICATION_CHECKLIST.md",
    "docs\reference\DOCS_TRUTH_MATRIX.md"
)

# Build the replacement map using PowerShell [char] escapes so the script file itself
# stays pure ASCII and is immune to save-encoding corruption.

# Helper: build a mojibake key string from the raw Windows-1252 byte values
# that result when UTF-8 multi-byte sequences are misread as Latin-1.
function ConvertTo-MojibakeKey {
    param([byte[]]$Bytes)
    $chars = $Bytes | ForEach-Object { [char]$_ }
    return -join $chars
}

# Table: correct Unicode codepoint -> Windows-1252 bytes that represent it when misread
# U+00B7 MIDDLE DOT        UTF-8: C2 B7  -> W1252: 0xC2=Â  0xB7=·
# U+00A0 NO-BREAK SPACE    UTF-8: C2 A0  -> W1252: 0xC2=Â  0xA0=<nbsp>
# U+2013 EN DASH           UTF-8: E2 80 93 -> W1252: 0xE2=â 0x80=€ 0x93=
# U+2014 EM DASH           UTF-8: E2 80 94 -> W1252: 0xE2=â 0x80=€ 0x94="
# U+2018 LEFT SINGLE QUOT  UTF-8: E2 80 98
# U+2019 RIGHT SINGLE QUOT UTF-8: E2 80 99
# U+201C LEFT DOUBLE QUOT  UTF-8: E2 80 9C
# U+201D RIGHT DOUBLE QUOT UTF-8: E2 80 9D
# U+2705 CHECK MARK EMOJI  UTF-8: E2 9C 85
# U+1F534 RED CIRCLE       UTF-8: F0 9F 94 B4
# U+1F7E0 ORANGE CIRCLE    UTF-8: F0 9F 9F A0
# U+1F7E1 YELLOW CIRCLE    UTF-8: F0 9F 9F A1
# U+1F7E2 GREEN CIRCLE     UTF-8: F0 9F 9F A2
# U+26AA  WHITE CIRCLE     UTF-8: E2 9A AA

$replacements = [System.Collections.Generic.List[object]]::new()

function Add-Replacement {
    param([byte[]]$BadBytes, [string]$Good)
    $bad = ConvertTo-MojibakeKey -Bytes $BadBytes
    $replacements.Add([PSCustomObject]@{ Bad = $bad; Good = $Good })
}

# Middle dot separator
Add-Replacement -BadBytes @(0xC2, 0xB7) -Good ([char]0x00B7)
# Non-breaking space
Add-Replacement -BadBytes @(0xC2, 0xA0) -Good ([char]0x00A0)
# En dash
Add-Replacement -BadBytes @(0xE2, 0x80, 0x93) -Good ([char]0x2013)
# Em dash
Add-Replacement -BadBytes @(0xE2, 0x80, 0x94) -Good ([char]0x2014)
# Left single quote
Add-Replacement -BadBytes @(0xE2, 0x80, 0x98) -Good ([char]0x2018)
# Right single quote
Add-Replacement -BadBytes @(0xE2, 0x80, 0x99) -Good ([char]0x2019)
# Left double quote
Add-Replacement -BadBytes @(0xE2, 0x80, 0x9C) -Good ([char]0x201C)
# Right double quote
Add-Replacement -BadBytes @(0xE2, 0x80, 0x9D) -Good ([char]0x201D)
# Check mark emoji U+2705
Add-Replacement -BadBytes @(0xE2, 0x9C, 0x85) -Good ([char]::ConvertFromUtf32(0x2705))
# White circle U+26AA
Add-Replacement -BadBytes @(0xE2, 0x9A, 0xAA) -Good ([char]::ConvertFromUtf32(0x26AA))
# Red circle U+1F534
Add-Replacement -BadBytes @(0xF0, 0x9F, 0x94, 0xB4) -Good ([char]::ConvertFromUtf32(0x1F534))
# Orange circle U+1F7E0
Add-Replacement -BadBytes @(0xF0, 0x9F, 0x9F, 0xA0) -Good ([char]::ConvertFromUtf32(0x1F7E0))
# Yellow circle U+1F7E1
Add-Replacement -BadBytes @(0xF0, 0x9F, 0x9F, 0xA1) -Good ([char]::ConvertFromUtf32(0x1F7E1))
# Green circle U+1F7E2
Add-Replacement -BadBytes @(0xF0, 0x9F, 0x9F, 0xA2) -Good ([char]::ConvertFromUtf32(0x1F7E2))

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$win1252   = [System.Text.Encoding]::GetEncoding(1252)

$fixedCount   = 0
$cleanCount   = 0
$skippedCount = 0

foreach ($rel in $releaseDocs) {
    $path = Join-Path $ProjectRoot $rel
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Verbose "Not found (skipped): $rel"
        $skippedCount++
        continue
    }

    # Read raw bytes and decode as Windows-1252 (how the mojibake appears in editors)
    $rawBytes  = [System.IO.File]::ReadAllBytes($path)
    $content   = $win1252.GetString($rawBytes)
    $original  = $content
    $hadChange = $false

    foreach ($entry in $replacements) {
        if ($content.Contains($entry.Bad)) {
            $content   = $content.Replace($entry.Bad, $entry.Good)
            $hadChange = $true
        }
    }

    if (-not $hadChange) {
        Write-Output "CLEAN    : $rel"
        $cleanCount++
        continue
    }

    if ($WhatIf) {
        Write-Output "WOULD-FIX: $rel"
        $fixedCount++
        continue
    }

    # Write back as UTF-8 (no BOM)
    [System.IO.File]::WriteAllBytes($path, $utf8NoBom.GetBytes($content))
    Write-Output "FIXED    : $rel"
    $fixedCount++
}

Write-Output ""
Write-Output "Done: $fixedCount fixed, $cleanCount already clean, $skippedCount not found."
