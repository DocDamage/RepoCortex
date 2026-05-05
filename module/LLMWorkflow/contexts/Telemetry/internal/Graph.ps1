Set-StrictMode -Version Latest

#===============================================================================
# Cross-Pack Graph Visualization
#===============================================================================

function Convert-ToMermaidGraph {
    <#
    .SYNOPSIS
        Converts graph data to Mermaid diagram syntax.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [hashtable]$Data
    )
    
    $mermaid = @()
    $mermaid += '```mermaid'
    $mermaid += 'graph LR'
    $mermaid += '    %% Pack Relationship Graph'
    $mermaid += "    %% Generated: $($Data.generatedAt)"
    $mermaid += ''
    
    # Style definitions
    $mermaid += '    %% Styles'
    $mermaid += '    classDef healthy fill:#4ec9b0,stroke:#2d8a7a,color:#fff'
    $mermaid += '    classDef degraded fill:#dcdcaa,stroke:#b5a642,color:#000'
    $mermaid += '    classDef critical fill:#f44747,stroke:#c13535,color:#fff'
    $mermaid += '    classDef unknown fill:#808080,stroke:#606060,color:#fff'
    $mermaid += ''
    
    # Nodes
    $mermaid += '    %% Nodes'
    foreach ($node in $Data.nodes) {
        $safeId = $node.id -replace '-', '_'
        $mermaid += "    $safeId[$($node.label)]"
    }
    $mermaid += ''
    
    # Edges
    $mermaid += '    %% Edges'
    foreach ($edge in $Data.edges) {
        $sourceId = $edge.source -replace '-', '_'
        $targetId = $edge.target -replace '-', '_'
        $mermaid += "    $sourceId -->|$($edge.type)| $targetId"
    }
    $mermaid += ''
    
    # Apply styles
    $mermaid += '    %% Apply styles'
    foreach ($node in $Data.nodes) {
        $safeId = $node.id -replace '-', '_'
        $class = switch ($node.status) {
            'Healthy' { 'healthy' }
            'Degraded' { 'degraded' }
            'Critical' { 'critical' }
            default { 'unknown' }
        }
        $mermaid += "    class $safeId $class"
    }
    
    $mermaid += '```'
    
    return $mermaid -join "`n"
}

function Write-ConsoleGraph {
    <#
    .SYNOPSIS
        Writes graph to console as ASCII art.
    #>
    [CmdletBinding()]
    param(
        [hashtable]$Data
    )
    
    $a = $script:AnsiColors
    Write-Host "$($a.Bold)$($a.Cyan)$($script:ProductBrandName) Cross-Pack Relationship Graph$($a.Reset)"
    Write-Host ''
    
    # Nodes
    Write-Host "$($a.Bold)Nodes (Packs):$($a.Reset)"
    foreach ($node in $Data.nodes) {
        $color = switch ($node.status) {
            'Healthy' { $a.Green }
            'Degraded' { $a.Yellow }
            'Critical' { $a.Red }
            default { $a.White }
        }
        Write-Host "  $color[$($node.id)]$($a.Reset) - $($node.domain) (v$($node.version)) - Score: $($node.score)"
    }
    Write-Host ''
    
    # Edges
    Write-Host "$($a.Bold)Edges (Pipelines):$($a.Reset)"
    foreach ($edge in $Data.edges) {
        $arrow = switch ($edge.status) {
            'active' { '-->' }
            'inactive' { '-x-' }
            default { '--?' }
        }
        Write-Host "  [$($edge.source)] $arrow [$($edge.target)] : $($edge.type)"
        if ($edge.assetTypes) {
            Write-Host "    Assets: $($edge.assetTypes -join ', ')"
        }
    }
}
