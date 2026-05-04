@{
    Files = @(
        'internal/_Constants.ps1'
        'internal/Diagnostics.ps1'
        'internal/History.ps1'
        'internal/Templates.ps1'
        'internal/Python.ps1'
        'internal/Input.ps1'
        'internal/Issue-Repair_MissingEnvFile.ps1'
        'internal/Issue-Repair_InvalidPythonPath.ps1'
        'internal/Issue-Repair_MissingChromaDB.ps1'
        'internal/Issue-Repair_MissingPalaceDirectory.ps1'
        'internal/Issue-Repair_CorruptedSyncState.ps1'
        'internal/Issue-Repair_TemplateDrift.ps1'
        'internal/Issue-Repair_MissingContextLatticeApiKey.ps1'
        'internal/Issue-Repair_MissingContextLatticeUrl.ps1'
        'internal/Issue-Repair_MissingBridgeConfig.ps1'
        'internal/Issue-Repair_CorruptedBridgeConfig.ps1'
        'api/Test-LLMWorkflowIssue.ps1'
        'api/Repair-LLMWorkflowIssue.ps1'
        'api/Get-LLMWorkflowRepairHistory.ps1'
        'api/Clear-LLMWorkflowRepairHistory.ps1'
        'api/Export-LLMWorkflowRepairHistory.ps1'
        'api/Invoke-LLMWorkflowHeal.ps1'
    )
    DependsOn = @('_shared')
}
