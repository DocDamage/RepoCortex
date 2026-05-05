Set-StrictMode -Version Latest

function ConvertTo-LLMWorkflowPascalName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $parts = @($Value -split '[^A-Za-z0-9]+' | Where-Object { $_ })
    $result = foreach ($part in $parts) {
        if ($part.Length -eq 1) {
            $part.ToUpperInvariant()
        }
        else {
            $part.Substring(0, 1).ToUpperInvariant() + $part.Substring(1)
        }
    }
    return ($result -join '')
}

function New-LLMWorkflowPackScaffold {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter()]
        [string]$ProjectRoot = '.',

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[a-z0-9][a-z0-9-]*[a-z0-9]$')]
        [string]$PackId,

        [Parameter(Mandatory = $true)]
        [string]$DisplayName,

        [Parameter()]
        [string]$Description = ''
    )

    $resolvedRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
    $manifestDir = Join-Path $resolvedRoot 'packs\manifests'
    $registryDir = Join-Path $resolvedRoot 'packs\registries'
    $goldenDir = Join-Path $resolvedRoot 'tests\golden'
    foreach ($dir in @($manifestDir, $registryDir, $goldenDir)) {
        if (-not (Test-Path -LiteralPath $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }

    $created = @()
    $manifestPath = Join-Path $manifestDir "$PackId.json"
    $registryPath = Join-Path $registryDir "$PackId.sources.json"
    $goldenPath = Join-Path $goldenDir "$(ConvertTo-LLMWorkflowPascalName -Value $PackId)GoldenTasks.ps1"

    $manifest = [ordered]@{
        id = $PackId
        name = $DisplayName
        description = $Description
        version = '0.1.0'
        schemaVersion = 1
        status = 'draft'
        capabilities = @()
        provenance = [ordered]@{
            createdBy = 'New-LLMWorkflowPackScaffold'
            createdAt = [DateTime]::UtcNow.ToString('o')
        }
    }
    $manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    $created += $manifestPath

    $registry = [ordered]@{
        packId = $PackId
        schemaVersion = 1
        sources = @()
    }
    $registry | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $registryPath -Encoding UTF8
    $created += $registryPath

    $goldenContent = @"
#requires -Version 5.1
Set-StrictMode -Version Latest

function Get-$((ConvertTo-LLMWorkflowPascalName -Value $PackId))GoldenTasks {
    [CmdletBinding()]
    [OutputType([array])]
    param()

    return @(
        @{
            taskId = '$PackId-smoke-001'
            name = '$DisplayName smoke task'
            packId = '$PackId'
            query = 'Describe the primary evidence this pack should retrieve.'
            expectedResult = 'Evidence is retrieved from a governed source.'
            validationRules = @('hasEvidence', 'hasProvenance')
        }
    )
}
"@
    Set-Content -LiteralPath $goldenPath -Value $goldenContent -Encoding UTF8
    $created += $goldenPath

    return [pscustomobject][ordered]@{
        PackId = $PackId
        DisplayName = $DisplayName
        CreatedFiles = @($created)
    }
}
