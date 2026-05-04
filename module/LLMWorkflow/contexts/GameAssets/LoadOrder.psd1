@{
    Files = @(
        'internal/Get-GamePresetPath.ps1',
        'internal/Test-GamePresetAvailable.ps1',
        'internal/Get-GamePresetData.ps1',
        'internal/New-LLMWorkflowDefaultAssetCategories.ps1',
        'internal/New-LLMWorkflowDefaultAssetTemplates.ps1',
        'internal/New-LLMWorkflowDefaultLicenseSummary.ps1',
        'internal/New-LLMWorkflowDefaultAssetManifest.ps1',
        'internal/Get-LLMWorkflowRelativeAssetPath.ps1',
        'internal/Format-LLMWorkflowAssetFileSize.ps1',
        'internal/Get-LLMWorkflowExistingAssetLookup.ps1',
        'internal/Merge-LLMWorkflowAssetManifest.ps1',
        'internal/Get-LLMWorkflowDefaultAssetSource.ps1',
        'internal/Get-LLMWorkflowAssetCategory.ps1',
        'internal/Get-LLMWorkflowAssetKind.ps1',
        'internal/Get-LLMWorkflowAssetEngineFamily.ps1',
        'internal/Get-LLMWorkflowAssetTags.ps1',
        'internal/Get-LLMWorkflowLicenseSummaryKey.ps1',
        'api/New-LLMWorkflowGamePreset.ps1',
        'api/Get-LLMWorkflowGameTemplates.ps1',
        'api/Export-LLMWorkflowAssetManifest.ps1',
        'api/Invoke-LLMWorkflowGameUp.ps1'
    )
    DependsOn = @('_shared', 'Ingestion')
}
