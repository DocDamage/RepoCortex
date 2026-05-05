Set-StrictMode -Version Latest

#===============================================================================
# Cross-Pack Graph Visualization
#===============================================================================

<#
.SYNOPSIS
    Visualizes cross-pack relationships as a graph.

.DESCRIPTION
    Generates graph visualization of pack relationships including nodes for
    each pack, edges for inter-pack pipelines, and status colors. Supports
    Mermaid diagram output and JSON graph format.

.PARAMETER OutputFormat
    Output format: 'Mermaid', 'JSON', 'Console', or 'HTML'.

.PARAMETER ProjectRoot
    Project root directory.

.PARAMETER IncludeInactive
    Include inactive/disabled pipelines in the graph.

.PARAMETER ExportPath
    Path to export the graph output.

.EXAMPLE
    Show-CrossPackGraph -OutputFormat Mermaid
    
    Generates Mermaid diagram syntax for pack relationships.

.EXAMPLE
    Show-CrossPackGraph -OutputFormat JSON | Out-File 'graph.json'
    
    Exports graph data as JSON for programmatic use.

.OUTPUTS
    String (Mermaid/JSON) or Hashtable depending on format.
#>
function Show-CrossPackGraph {
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter()]
        [ValidateSet('Mermaid', 'JSON', 'Console', 'HTML')]
        [string]$OutputFormat = 'Console',
        
        [Parameter()]
        [string]$ProjectRoot = '.',
        
        [Parameter()]
        [switch]$IncludeInactive,
        
        [Parameter()]
        [string]$ExportPath = ''
    )
    
    begin {
        $graphData = @{
            generatedAt = [DateTime]::UtcNow.ToString('o')
            version = $script:DashboardVersion
            nodes = @()
            edges = @()
        }
    }
    
    process {
        # Get packs as nodes
        $packs = Get-PackList -ProjectRoot $ProjectRoot
        foreach ($pack in $packs) {
            # Get pack health for color
            $health = Get-BasicPackHealth -PackId $pack.packId -ProjectRoot $ProjectRoot
            
            $node = @{
                id = $pack.packId
                label = $pack.packId
                domain = $pack.domain
                version = $pack.version
                status = $health.status
                score = $health.overallScore
            }
            $graphData.nodes += $node
        }
        
        # Get pipelines as edges
        $pipelinesDir = Join-Path $ProjectRoot '.llm-workflow/interpack/pipelines'
        if (Test-Path -LiteralPath $pipelinesDir) {
            $pipelineFiles = Get-DashboardChildItems -Path $pipelinesDir -Filter '*.json' -ItemType File -Context 'Cross-pack pipeline scan'
            
            foreach ($file in $pipelineFiles) {
                try {
                    $pipeline = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
                    
                    if ($pipeline.status -eq 'active' -or $IncludeInactive) {
                        $edge = @{
                            source = $pipeline.sourcePack
                            target = $pipeline.targetPack
                            type = $pipeline.intermediateFormat
                            status = $pipeline.status
                            assetTypes = $pipeline.assetTypes
                            pipelineId = $pipeline.pipelineId
                        }
                        $graphData.edges += $edge
                    }
                }
                catch {
                    Write-Verbose "Failed to parse pipeline: $($file.Name)"
                }
            }
        }
        
        # Note: When no pipeline files exist, graph will show nodes without edges
        # This is correct behavior - do not inject synthetic/known relationships
        # to avoid presenting misleading data in production dashboards.
        
        # Output based on format
        switch ($OutputFormat) {
            'Mermaid' {
                $output = Convert-ToMermaidGraph -Data $graphData
                if ($ExportPath) {
                    $output | Out-File -FilePath $ExportPath -Encoding UTF8
                    Write-Host "Mermaid graph exported to: $ExportPath"
                }
                return $output
            }
            'JSON' {
                $json = $graphData | ConvertTo-Json -Depth 10
                if ($ExportPath) {
                    $json | Out-File -FilePath $ExportPath -Encoding UTF8
                }
                return $json
            }
            'Console' {
                Write-ConsoleGraph -Data $graphData
                return $graphData
            }
            'HTML' {
                $html = Convert-ToGraphHTML -Data $graphData -Theme 'dark' -ProjectRoot $ProjectRoot
                if ($ExportPath) {
                    $html | Out-File -FilePath $ExportPath -Encoding UTF8
                }
                return $html
            }
        }
        
        return $graphData
    }
}
