Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Boundary contract validation for LLMWorkflow contexts.
.DESCRIPTION
    Ensures that contexts respect their boundaries by preventing
    private cross-context imports at build time.
#>

function Test-LLMBoundaryViolation {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [string]$ContextRoot
    )

    $content = Get-Content -LiteralPath $FilePath -Raw
    $fileDir = Split-Path -Parent (Resolve-Path -Relative -Path $FilePath)
    $relativeDir = $fileDir -replace '^\\?module\\LLMWorkflow\\contexts\\', ''
    $ownContext = ($relativeDir -split '\\|/')[0]

    # Find all dot-source patterns
    $pattern = '\.\s+["\'']?([^"\''\r\n]+)["\'']?'
    $matches = [regex]::Matches($content, $pattern)

    foreach ($m in $matches) {
        $target = $m.Groups[1].Value
        # Resolve relative to file location
        $resolved = $target
        if (-not [System.IO.Path]::IsPathRooted($target)) {
            $resolved = Join-Path (Split-Path -Parent $FilePath) $target
            $resolved = Resolve-Path $resolved -ErrorAction Ignore
        }
        if (-not $resolved) { continue }

        $targetRelative = (Resolve-Path -Relative -Path $resolved) -replace '^\\?module\\LLMWorkflow\\contexts\\', ''
        $targetContext = ($targetRelative -split '\\|/')[0]

        if ($targetContext -ne '_shared' -and $targetContext -ne $ownContext) {
            Write-Error "BOUNDARY VIOLATION: $FilePath illegally imports $resolved (context '$ownContext' -> '$targetContext')"
            return $false
        }
    }

    return $true
}
