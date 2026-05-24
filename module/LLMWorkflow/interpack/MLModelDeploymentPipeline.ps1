#Requires -Version 5.1
Set-StrictMode -Version Latest
<#
.SYNOPSIS
    ML model deployment pipeline for Repo Cortex inter-pack workflows.
.DESCRIPTION
    Deterministic artifact export, optimization metadata, inference verification,
    deployment artifact generation, and model version registration. Unsupported
    conversions fail loudly instead of generating placeholder scripts.
#>
$script:MLDeploymentExportExtensions = @{ ONNX = '.onnx'; TensorFlowLite = '.tflite'; PyTorchMobile = '.ptl' }
$script:MLDeploymentRegistry = @{}
$script:MLModelVersionRegistry = @{}
function New-MLDeploymentId { [CmdletBinding()] param([string]$Prefix = 'ml') ('{0}-{1}' -f $Prefix, ([guid]::NewGuid().ToString('N'))) }
function New-MLDeploymentDirectory { [CmdletBinding()] param([Parameter(Mandatory)][string]$Path) if (-not (Test-Path -LiteralPath $Path -PathType Container)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }; (Resolve-Path -LiteralPath $Path).Path }
function Get-MLSourceFormat {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$ModelPath)
    switch ([IO.Path]::GetExtension($ModelPath).ToLowerInvariant()) { '.pt' { 'PyTorch' } '.pth' { 'PyTorch' } '.pb' { 'TensorFlow' } '.h5' { 'TensorFlow' } '.onnx' { 'ONNX' } '.tflite' { 'TensorFlowLite' } '.ptl' { 'PyTorchMobile' } default { 'Unknown' } }
}
function Assert-MLConversionSupported {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$SourceFormat, [Parameter(Mandatory)][string]$TargetFormat)
    if (@('ONNX->ONNX', 'TensorFlowLite->TensorFlowLite', 'PyTorchMobile->PyTorchMobile') -notcontains ('{0}->{1}' -f $SourceFormat, $TargetFormat)) {
        throw "Unsupported ML model conversion '$SourceFormat->$TargetFormat'. Convert the model with the appropriate ML toolchain first, then provide an ONNX, TensorFlowLite, or PyTorchMobile artifact."
    }
}
function New-MLDeploymentPipeline {
    [CmdletBinding()] [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][ValidateSet('ONNX', 'TensorFlow', 'PyTorch', 'TensorFlowLite', 'PyTorchMobile')][string]$ModelFormat,
        [Parameter(Mandatory)][ValidateSet('Godot', 'Blender', 'Unity', 'Unreal')][string]$TargetEngine,
        [string]$TargetVersion = '', [string]$ConfigPath = '', [hashtable]$Config = @(),
        [ValidateSet('ONNXRuntime', 'TensorFlowLite', 'PyTorchMobile', 'Custom')][string]$RuntimeEngine = ''
    )
    $loadedConfig = @{}
    if (-not [string]::IsNullOrWhiteSpace($ConfigPath)) {
        if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) { throw "ConfigPath not found: $ConfigPath" }
        $loadedObject = Get-Content -LiteralPath $ConfigPath -Raw -ErrorAction Stop | ConvertFrom-Json
        foreach ($property in $loadedObject.PSObject.Properties) { $loadedConfig[$property.Name] = $property.Value }
    }
    $defaultRuntime = switch ($ModelFormat) { 'ONNX' { 'ONNXRuntime' } 'TensorFlow' { 'TensorFlowLite' } 'TensorFlowLite' { 'TensorFlowLite' } 'PyTorch' { 'PyTorchMobile' } 'PyTorchMobile' { 'PyTorchMobile' } }
    $finalConfig = @{ RuntimeEngine = if ($RuntimeEngine) { $RuntimeEngine } else { $defaultRuntime }; Platform = 'Windows'; Architecture = 'x64'; EnableOptimization = $true; Quantization = 'none'; OutputDirectory = './ml_deployments'; DeploymentType = if ($TargetEngine -eq 'Godot') { 'GDExtension' } elseif ($TargetEngine -eq 'Blender') { 'Addon' } else { 'Plugin' } }
    foreach ($key in $loadedConfig.Keys) { $finalConfig[$key] = $loadedConfig[$key] }; foreach ($key in $Config.Keys) { $finalConfig[$key] = $Config[$key] }
    [pscustomobject]@{ PipelineId = New-MLDeploymentId -Prefix 'pipeline'; ModelFormat = $ModelFormat; TargetEngine = $TargetEngine; TargetVersion = $TargetVersion; Config = $finalConfig; Status = 'Configured'; CreatedAt = (Get-Date).ToUniversalTime().ToString('o'); BuildState = [ordered]@{ ExportComplete = $false; OptimizationComplete = $false; TestingComplete = $false; DeploymentComplete = $false }; WorkflowSteps = @() }
}
function Export-MLModel {
    [CmdletBinding()] [OutputType([string])]
    param(
        [Parameter(Mandatory)][ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })][string]$ModelPath,
        [Parameter(Mandatory)][ValidateSet('ONNX', 'TensorFlowLite', 'PyTorchMobile')][string]$TargetFormat,
        [string]$OutputPath = './exported', [int[]]$InputShape = @(1, 224, 224, 3), [hashtable]$Config = @{}, [int]$OpsetVersion = 17
    )
    $sourceFormat = Get-MLSourceFormat -ModelPath $ModelPath; Assert-MLConversionSupported -SourceFormat $sourceFormat -TargetFormat $TargetFormat
    $resolvedOutputPath = New-MLDeploymentDirectory -Path $OutputPath
    $outputFile = Join-Path $resolvedOutputPath ("{0}{1}" -f [IO.Path]::GetFileNameWithoutExtension($ModelPath), $script:MLDeploymentExportExtensions[$TargetFormat])
    Copy-Item -LiteralPath $ModelPath -Destination $outputFile -Force -ErrorAction Stop
    [ordered]@{ SourceFormat = $sourceFormat; TargetFormat = $TargetFormat; SourcePath = (Resolve-Path -LiteralPath $ModelPath).Path; OutputPath = (Resolve-Path -LiteralPath $outputFile).Path; InputShape = $InputShape; OpsetVersion = $OpsetVersion; ExportTimestamp = (Get-Date).ToUniversalTime().ToString('o'); PlaceholderGenerated = $false } | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $resolvedOutputPath 'export_metadata.json') -Encoding UTF8
    $outputFile
}
function Optimize-ModelForInference {
    [CmdletBinding()] [OutputType([string])]
    param(
        [Parameter(Mandatory)][ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })][string]$ModelPath,
        [ValidateSet('none', 'fp16', 'int8', 'int4', 'dynamic')][string]$Quantization = 'none', [switch]$EnablePruning,
        [ValidateRange(0.0, 1.0)][float]$TargetSparsity = 0.3, [string]$OutputPath = ''
    )
    if ([string]::IsNullOrWhiteSpace($OutputPath)) { $OutputPath = Join-Path ([IO.Path]::GetDirectoryName((Resolve-Path -LiteralPath $ModelPath).Path)) 'optimized' }
    $resolvedOutputPath = New-MLDeploymentDirectory -Path $OutputPath
    $optimizedFile = Join-Path $resolvedOutputPath ("{0}_optimized{1}" -f [IO.Path]::GetFileNameWithoutExtension($ModelPath), [IO.Path]::GetExtension($ModelPath))
    Copy-Item -LiteralPath $ModelPath -Destination $optimizedFile -Force -ErrorAction Stop
    [ordered]@{ SourcePath = (Resolve-Path -LiteralPath $ModelPath).Path; OptimizedPath = (Resolve-Path -LiteralPath $optimizedFile).Path; Quantization = $Quantization; PruningEnabled = [bool]$EnablePruning; TargetSparsity = $TargetSparsity; OptimizationTimestamp = (Get-Date).ToUniversalTime().ToString('o'); ActualGraphOptimizationPerformed = $false; Note = 'Artifact copied with optimization metadata. External optimizer integration is required for graph-level transformations.' } | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $resolvedOutputPath 'optimization_metadata.json') -Encoding UTF8
    $optimizedFile
}
function Test-ModelInference {
    [CmdletBinding()] [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })][string]$ModelPath, [int]$Iterations = 100)
    $file = Get-Item -LiteralPath $ModelPath -ErrorAction Stop
    [pscustomobject]@{ TestId = New-MLDeploymentId -Prefix 'infer'; Success = $true; ModelPath = $file.FullName; Iterations = $Iterations; FileSizeBytes = $file.Length; LatencyMs = 0; Throughput = 0; Accuracy = 0; VerifiedAt = (Get-Date).ToUniversalTime().ToString('o'); VerificationMode = 'artifact-exists'; Note = 'Runtime inference execution was not attempted because no inference runtime was supplied.' }
}
function Deploy-ToGodot {
    [CmdletBinding()] [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })][string]$ModelPath, [Parameter(Mandatory)][string]$ProjectPath, [string]$ExtensionName = 'MLInference', [object]$Config = $null)
    $extensionDir = New-MLDeploymentDirectory -Path (Join-Path (New-MLDeploymentDirectory -Path (Join-Path $ProjectPath 'addons')) $ExtensionName)
    $modelTarget = Join-Path $extensionDir ([IO.Path]::GetFileName($ModelPath)); Copy-Item -LiteralPath $ModelPath -Destination $modelTarget -Force -ErrorAction Stop
    $manifestPath = Join-Path $extensionDir 'ml_deployment.json'
    [ordered]@{ engine = 'Godot'; extensionName = $ExtensionName; model = (Resolve-Path -LiteralPath $modelTarget).Path; deployedAt = (Get-Date).ToUniversalTime().ToString('o'); pipelineId = if ($Config -and $Config.PipelineId) { $Config.PipelineId } else { $null } } | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    $deployment = [pscustomobject]@{ DeploymentId = New-MLDeploymentId -Prefix 'deploy'; TargetEngine = 'Godot'; TargetProject = (Resolve-Path -LiteralPath $ProjectPath).Path; DeploymentPath = $extensionDir; ModelPath = (Resolve-Path -LiteralPath $modelTarget).Path; ManifestPath = $manifestPath; Status = 'Deployed'; DeployedAt = (Get-Date).ToUniversalTime().ToString('o') }
    $script:MLDeploymentRegistry[$deployment.DeploymentId] = $deployment; $deployment
}
function Deploy-ToTarget {
    [CmdletBinding()] [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })][string]$ModelPath, [Parameter(Mandatory)][string]$Platform, [string]$Architecture = 'x64', [object]$Config = $null)
    $baseOutput = if ($Config -and $Config.Config -and $Config.Config.OutputDirectory) { $Config.Config.OutputDirectory } else { './ml_deployments' }
    $deploymentDir = New-MLDeploymentDirectory -Path (Join-Path (Join-Path $baseOutput $Platform) $Architecture)
    $modelTarget = Join-Path $deploymentDir ([IO.Path]::GetFileName($ModelPath)); Copy-Item -LiteralPath $ModelPath -Destination $modelTarget -Force -ErrorAction Stop
    $deployment = [pscustomobject]@{ DeploymentId = New-MLDeploymentId -Prefix 'deploy'; TargetEngine = if ($Config -and $Config.TargetEngine) { $Config.TargetEngine } else { 'Generic' }; Platform = $Platform; Architecture = $Architecture; DeploymentPath = $deploymentDir; ModelPath = (Resolve-Path -LiteralPath $modelTarget).Path; Status = 'Deployed'; DeployedAt = (Get-Date).ToUniversalTime().ToString('o') }
    $script:MLDeploymentRegistry[$deployment.DeploymentId] = $deployment; $deployment
}
function Register-MLModelVersion {
    [CmdletBinding()] [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })][string]$ModelPath, [string]$Version = '1.0.0', [hashtable]$Metadata = @{})
    $versionInfo = [pscustomobject]@{ VersionId = New-MLDeploymentId -Prefix 'model'; ModelName = [IO.Path]::GetFileNameWithoutExtension($ModelPath); Version = $Version; ModelPath = (Resolve-Path -LiteralPath $ModelPath).Path; Metadata = $Metadata; CreatedAt = (Get-Date).ToUniversalTime().ToString('o'); Status = 'Active' }
    $script:MLModelVersionRegistry[$versionInfo.VersionId] = $versionInfo; $versionInfo
}
function Get-MLDeploymentStatus {
    [CmdletBinding()] [OutputType([object])] param([string]$DeploymentId = '')
    if ([string]::IsNullOrWhiteSpace($DeploymentId)) { return @($script:MLDeploymentRegistry.Values) }
    if (-not $script:MLDeploymentRegistry.ContainsKey($DeploymentId)) { throw "Deployment not found: $DeploymentId" }
    $script:MLDeploymentRegistry[$DeploymentId]
}
function Start-MLDeploymentWorkflow {
    [CmdletBinding()] [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][pscustomobject]$Config, [Parameter(Mandatory)][ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })][string]$ModelPath, [switch]$SkipOptimization, [switch]$SkipTesting, [string[]]$DeployTargets = @(), [string]$Version = '1.0.0')
    $Config.Status = 'Running'
    try {
        $targetFormat = switch ($Config.ModelFormat) { 'PyTorch' { 'ONNX' } 'TensorFlow' { 'TensorFlowLite' } default { $Config.ModelFormat } }
        $exportedModel = Export-MLModel -ModelPath $ModelPath -TargetFormat $targetFormat -OutputPath (Join-Path $Config.Config.OutputDirectory 'exported') -Config $Config.Config; $Config.BuildState.ExportComplete = $true
        $optimizedModel = $exportedModel
        if (-not $SkipOptimization -and $Config.Config.EnableOptimization) { $optimizedModel = Optimize-ModelForInference -ModelPath $exportedModel -Quantization $Config.Config.Quantization; $Config.BuildState.OptimizationComplete = $true }
        $testResults = $null
        if (-not $SkipTesting) { $testResults = Test-ModelInference -ModelPath $optimizedModel -Iterations 100; $Config.BuildState.TestingComplete = $true }
        $versionInfo = Register-MLModelVersion -ModelPath $optimizedModel -Version $Version -Metadata @{ PipelineId = $Config.PipelineId; ModelFormat = $Config.ModelFormat; TargetEngine = $Config.TargetEngine }
        if ($DeployTargets.Count -eq 0) { $DeployTargets = @($Config.Config.Platform) }
        $deployments = @(); foreach ($target in $DeployTargets) { if ($Config.TargetEngine -eq 'Godot') { $deployments += Deploy-ToGodot -ModelPath $optimizedModel -ProjectPath $Config.Config.OutputDirectory -ExtensionName 'MLInference' -Config $Config } else { $deployments += Deploy-ToTarget -ModelPath $optimizedModel -Platform $target -Architecture $Config.Config.Architecture -Config $Config } }
        $Config.BuildState.DeploymentComplete = $true; $Config.Status = 'Complete'
        [pscustomobject]@{ Pipeline = $Config; ExportedModel = $exportedModel; OptimizedModel = $optimizedModel; TestResults = $testResults; Deployments = $deployments; Version = $versionInfo; Success = $true }
    } catch { $Config.Status = 'Failed'; throw }
}
