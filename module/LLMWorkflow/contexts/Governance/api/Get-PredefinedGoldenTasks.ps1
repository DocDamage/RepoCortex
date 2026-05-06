#requires -Version 5.1
Set-StrictMode -Version Latest

function Get-PredefinedGoldenTasks {
    [CmdletBinding()]
    [OutputType([array])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$PackId = ''
    )

    $allTasks = @()
    $allTasks += Get-PredefinedRPGMakerTasks
    $allTasks += Get-PredefinedGodotTasks
    $allTasks += Get-PredefinedBlenderTasks
    $allTasks += Get-PredefinedApiReverseTasks
    $allTasks += Get-PredefinedNotebookDataTasks
    $allTasks += Get-PredefinedAgentSimTasks
    $allTasks += Get-PredefinedNegativeTasks

    if ($PackId) {
        return $allTasks | Where-Object { $_.packId -eq $PackId }
    }

    return $allTasks
}
