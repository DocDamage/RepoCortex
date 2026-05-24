#requires -Version 5.1
Set-StrictMode -Version Latest
<#
.SYNOPSIS
    Inter-pack API example catalog.
.DESCRIPTION
    This file intentionally returns inert example metadata instead of executing pipeline actions. Runtime examples moved to tests so this production module tree does not carry stale executable sample code.
#>
function Get-InterPackExampleUsage {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()
    [ordered]@{
        VoiceAnimation = @('New-VoiceAnimationPipeline', 'Start-VoiceToAnimationSync')
        AIGeneration = @('New-AIGenerationPipeline', 'Start-AIGenerationWorkflow')
        MLDeployment = @('New-MLDeploymentPipeline', 'Start-MLDeploymentWorkflow')
        InterPackTransport = @('New-InterPackPipeline', 'Sync-InterPackAssets')
    }
}
