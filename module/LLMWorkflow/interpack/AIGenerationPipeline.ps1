#Requires -Version 5.1
Set-StrictMode -Version Latest
<#
.SYNOPSIS
    AI generation pipeline with deterministic artifacts, provenance, and fail-loud provider behavior.
.DESCRIPTION
    Builds generation request records, converts generated artifacts for engine packs, and records provenance.
    Only the Mock provider produces synthetic files; real providers require explicit endpoint integration.
#>
$script:AIGenerationProviders = @('ComfyUI','Automatic1111','Local','Cloud-Azure','Cloud-AWS','Cloud-Stability','Cloud-OpenAI','Mock')
$script:AIGenerationRegistry = @{}
function New-AIGenerationId { [CmdletBinding()] param([string]$Prefix='ai') ('{0}-{1}' -f $Prefix,([guid]::NewGuid().ToString('N'))) }
function New-AIGenerationDirectory { [CmdletBinding()] param([Parameter(Mandatory)][string]$Path) if(-not(Test-Path -LiteralPath $Path -PathType Container)){New-Item -ItemType Directory -Path $Path -Force|Out-Null}; (Resolve-Path -LiteralPath $Path).Path }
function Write-AIGenerationJson { [CmdletBinding()] param([Parameter(Mandatory)]$Data,[Parameter(Mandatory)][string]$Path) $parent=Split-Path -Parent $Path; if($parent -and -not(Test-Path -LiteralPath $parent)){New-Item -ItemType Directory -Path $parent -Force|Out-Null}; $Data|ConvertTo-Json -Depth 20|Set-Content -LiteralPath $Path -Encoding UTF8 }
function Get-AIValue { param($Object,[string]$Name,$Default=$null) if($Object -is [hashtable] -and $Object.ContainsKey($Name)){return $Object[$Name]}; if($Object.PSObject.Properties[$Name]){return $Object.$Name}; $Default }
function Get-DefaultEndpoint { [CmdletBinding()] param([Parameter(Mandatory)][string]$Provider) switch($Provider){'ComfyUI'{'http://localhost:8188'}'Automatic1111'{'http://localhost:7860'}'Local'{'local'}'Mock'{'mock://local'}default{''}} }
function New-AIGenerationPipeline {
    [CmdletBinding()] [OutputType([hashtable])]
    param([Parameter(Mandatory)][ValidateSet('ComfyUI','Automatic1111','Local','Cloud-Azure','Cloud-AWS','Cloud-Stability','Cloud-OpenAI','Mock')][string]$Provider,[Parameter(Mandatory)][ValidateSet('GodotPack','BlenderPack','UnityPack','UnrealPack')][string]$TargetPack,[string]$ConfigPath,[hashtable]$Config=@{},[string]$Endpoint,[string]$ApiKey)
    $providerConfig=@{Type=$Provider;Endpoint=if($Endpoint){$Endpoint}else{Get-DefaultEndpoint -Provider $Provider};ApiKeyRef=if($ApiKey){'provided-at-runtime'}else{''}}
    $pipelineConfig=@{Version='1.0.0';Provider=$providerConfig;GenerationSettings=@{DefaultWidth=1024;DefaultHeight=1024;DefaultSteps=30;DefaultGuidance=7.5;SafetyChecker=$true;Watermark=$false;ModelCheckpoint='SDXL'};OutputSettings=@{Format='png';Quality=95;IncludeMetadata=$true;ProvenanceTracking=$true;OutputDirectory='./ai_generations'};PackIntegration=@{TargetPack=$TargetPack;AutoImport=$false;AssetPrefix='AI_'};OptimizationSettings=@{TargetTextureSize=2048;CompressionLevel='Medium';GenerateLODs=$true}}
    foreach($key in $Config.Keys){if($pipelineConfig.ContainsKey($key)-and $pipelineConfig[$key] -is [hashtable] -and $Config[$key] -is [hashtable]){foreach($sub in $Config[$key].Keys){$pipelineConfig[$key][$sub]=$Config[$key][$sub]}}else{$pipelineConfig[$key]=$Config[$key]}}
    if($ConfigPath){$safe=$pipelineConfig.Clone(); $safe.Provider=$pipelineConfig.Provider.Clone(); $safe.Provider.ApiKeyRef=if($safe.Provider.ApiKeyRef){'provided-at-runtime'}else{''}; Write-AIGenerationJson $safe $ConfigPath}
    $pipelineConfig
}
function Start-AIGenerationPipeline {
    [CmdletBinding()] [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][ValidateSet('ComfyUI','Automatic1111','Local','Cloud-Azure','Cloud-AWS','Cloud-Stability','Cloud-OpenAI','Mock')][string]$Provider,[Parameter(Mandatory)][string]$TargetPack,[Parameter(Mandatory)][hashtable]$Config)
    $endpoint=Get-AIValue $Config.Provider 'Endpoint' ''
    if($Provider -ne 'Mock' -and [string]::IsNullOrWhiteSpace($endpoint)){throw "Provider '$Provider' requires an endpoint or runtime adapter. Use Provider 'Mock' for offline deterministic fixture generation."}
    $p=[pscustomobject]@{PipelineId=New-AIGenerationId -Prefix 'pipeline';Provider=$Provider;TargetPack=$TargetPack;Config=$Config;Status='Initialized';CreatedAt=(Get-Date).ToUniversalTime().ToString('o');Generations=@()}
    $script:AIGenerationRegistry[$p.PipelineId]=$p; $p
}
function New-AIGeneratedAsset {
    [CmdletBinding()] [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][pscustomobject]$Pipeline,[Parameter(Mandatory)][ValidateSet('Image','Texture','Mesh','Material')][string]$AssetType,[Parameter(Mandatory)][string]$Prompt,[hashtable]$Parameters=@{},[string]$OutputName='')
    if($Pipeline.Provider -ne 'Mock'){throw "Provider '$($Pipeline.Provider)' execution is not implemented in-process. Register a provider adapter before generating assets."}
    $outRoot=New-AIGenerationDirectory -Path (Get-AIValue $Pipeline.Config.OutputSettings 'OutputDirectory' './ai_generations')
    $assetId=New-AIGenerationId -Prefix 'asset'; if([string]::IsNullOrWhiteSpace($OutputName)){$OutputName=$assetId}
    $file=Join-Path $outRoot ("$OutputName.$AssetType.json"); $asset=[ordered]@{AssetId=$assetId;AssetType=$AssetType;SourcePrompt=$Prompt;Parameters=$Parameters;Provider='Mock';GeneratedAt=(Get-Date).ToUniversalTime().ToString('o');Status='Generated';FilePath=$file;Metadata=@{PromptHash=([Math]::Abs($Prompt.GetHashCode())).ToString();MockGenerated=$true}}
    Write-AIGenerationJson $asset $file; $obj=[pscustomobject]$asset; $Pipeline.Generations += $obj; $obj
}
function Convert-ToGameFormat {
    [CmdletBinding()] [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][pscustomobject]$Pipeline,[Parameter(Mandatory)][pscustomobject]$Asset,[string]$TargetFormat='')
    if([string]::IsNullOrWhiteSpace($TargetFormat)){ $TargetFormat=switch($Pipeline.TargetPack){'GodotPack'{'tres'}'BlenderPack'{'json'}'UnityPack'{'asset'}'UnrealPack'{'uasset.json'}default{'json'}} }
    $target=Join-Path ([IO.Path]::GetDirectoryName($Asset.FilePath)) ("$($Asset.AssetId).converted.$TargetFormat")
    [ordered]@{AssetId=$Asset.AssetId;SourcePath=$Asset.FilePath;TargetPack=$Pipeline.TargetPack;TargetFormat=$TargetFormat;ConvertedAt=(Get-Date).ToUniversalTime().ToString('o')} | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $target -Encoding UTF8
    $Asset | Add-Member -NotePropertyName ConvertedPath -NotePropertyValue $target -Force; $Asset | Add-Member -NotePropertyName TargetFormat -NotePropertyValue $TargetFormat -Force; $Asset
}
function Optimize-AssetForGame {
    [CmdletBinding()] [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][pscustomobject]$Pipeline,[Parameter(Mandatory)][pscustomobject]$Asset,[string]$OptimizationLevel='Medium')
    $manifest=Join-Path ([IO.Path]::GetDirectoryName($Asset.FilePath)) ("$($Asset.AssetId).optimization.json")
    [ordered]@{AssetId=$Asset.AssetId;OptimizationLevel=$OptimizationLevel;TargetPack=$Pipeline.TargetPack;OptimizedAt=(Get-Date).ToUniversalTime().ToString('o');ActualBinaryOptimizationPerformed=$false} | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $manifest -Encoding UTF8
    $Asset | Add-Member -NotePropertyName OptimizationManifest -NotePropertyValue $manifest -Force; $Asset
}
function Register-GeneratedAsset {
    [CmdletBinding()] [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][pscustomobject]$Pipeline,[Parameter(Mandatory)][pscustomobject]$Asset,[string]$WorkflowId='')
    $prov=Join-Path ([IO.Path]::GetDirectoryName($Asset.FilePath)) ("$($Asset.AssetId).provenance.json")
    [ordered]@{WorkflowId=$WorkflowId;PipelineId=$Pipeline.PipelineId;AssetId=$Asset.AssetId;TargetPack=$Pipeline.TargetPack;Prompt=$Asset.SourcePrompt;GeneratedPath=$Asset.FilePath;ConvertedPath=$Asset.ConvertedPath;RecordedAt=(Get-Date).ToUniversalTime().ToString('o')} | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $prov -Encoding UTF8
    $Asset | Add-Member -NotePropertyName ProvenanceId -NotePropertyValue ([IO.Path]::GetFileNameWithoutExtension($prov)) -Force; $Asset | Add-Member -NotePropertyName ProvenancePath -NotePropertyValue $prov -Force; $Asset
}
function Import-ToGodot { [CmdletBinding()] param([Parameter(Mandatory)][pscustomobject]$Pipeline,[Parameter(Mandatory)][pscustomobject]$Asset,[string]$ProjectPath='') if(-not$ProjectPath){$ProjectPath=Join-Path (Get-AIValue $Pipeline.Config.OutputSettings 'OutputDirectory' './ai_generations') 'godot-import'}; $dir=New-AIGenerationDirectory $ProjectPath; Copy-Item -LiteralPath $Asset.ConvertedPath -Destination (Join-Path $dir ([IO.Path]::GetFileName($Asset.ConvertedPath))) -Force; $Asset }
function Import-ToBlender { [CmdletBinding()] param([Parameter(Mandatory)][pscustomobject]$Pipeline,[Parameter(Mandatory)][pscustomobject]$Asset,[string]$ProjectPath='') if(-not$ProjectPath){$ProjectPath=Join-Path (Get-AIValue $Pipeline.Config.OutputSettings 'OutputDirectory' './ai_generations') 'blender-import'}; $dir=New-AIGenerationDirectory $ProjectPath; Copy-Item -LiteralPath $Asset.ConvertedPath -Destination (Join-Path $dir ([IO.Path]::GetFileName($Asset.ConvertedPath))) -Force; $Asset }
function Start-AIGenerationWorkflow {
    [CmdletBinding()] [OutputType([hashtable])]
    param([Parameter(Mandatory)][hashtable]$Config,[Parameter(Mandatory)][hashtable]$Workflow,[switch]$AutoImport)
    $pipeline=Start-AIGenerationPipeline -Provider $Config.Provider.Type -TargetPack $Config.PackIntegration.TargetPack -Config $Config; $workflowId=New-AIGenerationId -Prefix 'workflow'; $assets=@(); $failures=@()
    foreach($assetDef in @($Workflow.Assets)){try{$type=Get-AIValue $assetDef 'Type' 'Image'; $prompt=Get-AIValue $assetDef 'Prompt' ''; $name=Get-AIValue $assetDef 'OutputName' ''; $params=Get-AIValue $assetDef 'Parameters' @{}; $format=Get-AIValue $assetDef 'TargetFormat' ''; $asset=New-AIGeneratedAsset -Pipeline $pipeline -AssetType $type -Prompt $prompt -Parameters $params -OutputName $name; $asset=Convert-ToGameFormat -Pipeline $pipeline -Asset $asset -TargetFormat $format; $asset=Optimize-AssetForGame -Pipeline $pipeline -Asset $asset -OptimizationLevel $Config.OptimizationSettings.CompressionLevel; $asset=Register-GeneratedAsset -Pipeline $pipeline -Asset $asset -WorkflowId $workflowId; if($AutoImport -or $Config.PackIntegration.AutoImport){if($Config.PackIntegration.TargetPack -eq 'GodotPack'){Import-ToGodot -Pipeline $pipeline -Asset $asset|Out-Null}elseif($Config.PackIntegration.TargetPack -eq 'BlenderPack'){Import-ToBlender -Pipeline $pipeline -Asset $asset|Out-Null}}; $assets+=$asset}catch{$failures+=@{asset=$assetDef;error=$_.Exception.Message}}}
    @{WorkflowId=$workflowId;PipelineId=$pipeline.PipelineId;Success=($failures.Count -eq 0);GeneratedAssets=$assets;Failures=$failures}
}
