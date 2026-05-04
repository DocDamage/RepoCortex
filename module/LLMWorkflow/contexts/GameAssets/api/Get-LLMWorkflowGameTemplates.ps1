Set-StrictMode -Version Latest

function Get-LLMWorkflowGameTemplates {
    <#
    .SYNOPSIS
        Lists available game templates.
    .DESCRIPTION
        Returns a list of pre-defined game templates with descriptions and tags.
    .EXAMPLE
        Get-LLMWorkflowGameTemplates
        Lists all available templates.
    .EXAMPLE
        Get-LLMWorkflowGameTemplates | Where-Object { $_.tags -contains "2d" }
        Lists only 2D game templates.
    #>
    [OutputType([pscustomobject[]])]
    [CmdletBinding()]
    param()
    
    $preset = Get-GamePresetData
    $templates = @()
    
    foreach ($t in $preset.gameTemplates) {
        $templates += [pscustomobject]@{
            Id = $t.id
            Name = $t.name
            Description = $t.description
            Tags = $t.tags
            DefaultEngine = $t.defaultEngine
            Provenance = [ordered]@{
                generatedBy = 'LLMWorkflow.GameFunctions'
                generatedAt = [DateTime]::UtcNow.ToString('o')
            }
        }
    }
    
    return $templates
}
