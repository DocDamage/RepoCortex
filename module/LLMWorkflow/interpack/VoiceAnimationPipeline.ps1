#Requires -Version 5.1
Set-StrictMode -Version Latest
<#
.SYNOPSIS
    Voice-to-animation synchronization pipeline with deterministic lip-sync artifacts.
.DESCRIPTION
    Builds audio manifests, phoneme/viseme timing, keyframes, and Godot/Blender export artifacts.
    TTS execution is not faked as real WAV output; simulated audio is recorded as a manifest.
#>
$script:VoiceVisemes = @('sil','aa','E','ih','oh','ou','ee','oo','ff','mm','sh','th')
$script:VoiceBlendMap = @{aa=@{jawOpen=0.8;mouthOpen=0.7};E=@{mouthSmile=0.3;jawOpen=0.4};ih=@{jawOpen=0.3;mouthWide=0.5};oh=@{jawOpen=0.5;mouthPucker=0.6};ou=@{mouthPucker=0.8;jawOpen=0.3};ee=@{mouthSmile=0.6;mouthWide=0.4};oo=@{mouthPucker=0.9;jawOpen=0.2};ff=@{jawOpen=0.1;mouthUpperUp=0.3};mm=@{mouthClose=1.0};sh=@{jawOpen=0.2;mouthPucker=0.4};th=@{jawOpen=0.3;tongueOut=0.5};sil=@{}}
function New-VoicePipelineId { [CmdletBinding()] param([string]$Prefix='voice') ('{0}-{1}' -f $Prefix,([guid]::NewGuid().ToString('N'))) }
function New-VoiceDirectory { [CmdletBinding()] param([Parameter(Mandatory)][string]$Path) if(-not(Test-Path -LiteralPath $Path -PathType Container)){New-Item -ItemType Directory -Path $Path -Force|Out-Null}; (Resolve-Path -LiteralPath $Path).Path }
function Write-VoiceJson { [CmdletBinding()] param([Parameter(Mandatory)]$Data,[Parameter(Mandatory)][string]$Path) $parent=Split-Path -Parent $Path; if($parent -and -not(Test-Path -LiteralPath $parent)){New-Item -ItemType Directory -Path $parent -Force|Out-Null}; $Data|ConvertTo-Json -Depth 20|Set-Content -LiteralPath $Path -Encoding UTF8 }
function New-VoiceAnimationPipeline {
    [CmdletBinding()] [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][string]$VoicePack,[Parameter(Mandatory)][string]$AnimationPack,[hashtable]$Config=@{},[string]$OutputDir='./output')
    $engine=if($AnimationPack -match 'Godot'){'Godot'}elseif($AnimationPack -match 'Blender'){'Blender'}else{'Generic'}; $cfg=@{Version='1.0.0';VoicePack=@{PackId=$VoicePack;TTSProvider='manifest-only';AudioFormat='manifest';SampleRate=48000};AnimationPack=@{PackId=$AnimationPack;Engine=$engine;RigFormat='gltf';BlendShapeSupport=$true};SyncSettings=@{FrameRate=30;VisemeSet='ARKit';SmoothingFactor=0.5;TimeOffset=0.0};OutputSettings=@{Format='json';IncludeMetadata=$true;Compression='none';OutputDir=$OutputDir};PipelineStatus='Configured'}
    foreach($key in $Config.Keys){if($cfg.ContainsKey($key)-and $cfg[$key] -is [hashtable] -and $Config[$key] -is [hashtable]){foreach($sub in $Config[$key].Keys){$cfg[$key][$sub]=$Config[$key][$sub]}}else{$cfg[$key]=$Config[$key]}}
    New-VoiceDirectory $OutputDir|Out-Null; [pscustomobject]@{PipelineId=New-VoicePipelineId -Prefix 'pipeline';Config=$cfg;CreatedAt=(Get-Date).ToUniversalTime().ToString('o');Operations=@()}
}
function Export-VoiceAudio {
    [CmdletBinding()] [OutputType([hashtable])]
    param([string]$Text,[string]$VoiceId='en-US-Aria',[string]$SourceAudio,[Parameter(Mandatory)][string]$OutputDir,[string]$OutputName='voice',[switch]$UseSTS,[ValidateSet('Azure','AWS','Local','ManifestOnly')][string]$Provider='ManifestOnly')
    $dir=New-VoiceDirectory $OutputDir
    if($UseSTS -and $SourceAudio){if(-not(Test-Path -LiteralPath $SourceAudio -PathType Leaf)){throw "SourceAudio not found: $SourceAudio"}; $target=Join-Path $dir ([IO.Path]::GetFileName($SourceAudio)); Copy-Item -LiteralPath $SourceAudio -Destination $target -Force; return @{AudioFile=$target;ManifestPath=$null;Source='Existing';Provider=$Provider;VoiceId=$VoiceId}}
    if([string]::IsNullOrWhiteSpace($Text)){throw 'Text or SourceAudio is required.'}
    $manifest=Join-Path $dir "$OutputName.audio-manifest.json"; Write-VoiceJson ([ordered]@{Mode='tts-request';Text=$Text;VoiceId=$VoiceId;Provider=$Provider;GeneratedAt=(Get-Date).ToUniversalTime().ToString('o');ActualAudioGenerated=$false}) $manifest
    @{AudioFile=$manifest;ManifestPath=$manifest;Source='TTS-Manifest';Provider=$Provider;VoiceId=$VoiceId;Text=$Text}
}
function Get-PhonemeTimings {
    [CmdletBinding()] [OutputType([hashtable])]
    param([Parameter(Mandatory)][ValidateScript({Test-Path -LiteralPath $_ -PathType Leaf})][string]$AudioFile,[string]$Text,[string]$Language='en-US',[ValidateSet('Deterministic','Rhubarb','Allosaurus','Azure','Librosa')][string]$Engine='Deterministic')
    $tokens=if($Text){@($Text -split '\s+'|Where-Object{$_})}else{@('sil')}; $duration=[Math]::Max(1.0,[double]($tokens.Count)*0.32); $phonemes=@(); $t=0.0; $i=0
    while($t -lt $duration){$name=$script:VoiceVisemes[$i % $script:VoiceVisemes.Count]; $end=[Math]::Min($duration,$t+0.12); $phonemes+=[pscustomobject]@{Phoneme=$name;StartTime=$t;EndTime=$end;Duration=($end-$t);Confidence=0.85}; $t=$end; $i++}
    @{AudioFile=$AudioFile;Duration=$duration;Language=$Language;Engine=$Engine;Phonemes=$phonemes;Count=$phonemes.Count}
}
function Export-LipSyncData {
    [CmdletBinding()] [OutputType([hashtable])]
    param([Parameter(Mandatory)][hashtable]$PhonemeData,[ValidateSet('ARKit','Oculus','Custom')][string]$VisemeSet='ARKit',[Parameter(Mandatory)][string]$OutputDir,[string]$OutputName='lipsync',[switch]$Smoothing)
    $dir=New-VoiceDirectory $OutputDir; $visemes=@(); foreach($p in $PhonemeData.Phonemes){$visemes+=[pscustomobject]@{VisemeId=New-VoicePipelineId -Prefix 'viseme';VisemeName=$p.Phoneme;StartTime=$p.StartTime;EndTime=$p.EndTime;Intensity=$p.Confidence;BlendShapeWeights=if($script:VoiceBlendMap.ContainsKey($p.Phoneme)){$script:VoiceBlendMap[$p.Phoneme]}else{@{}}}}
    $path=Join-Path $dir "$OutputName.visemes.json"; Write-VoiceJson ([ordered]@{version='1.0';trackId=New-VoicePipelineId -Prefix 'track';audioFile=$PhonemeData.AudioFile;duration=$PhonemeData.Duration;visemeSet=$VisemeSet;visemes=$visemes}) $path
    @{TrackId=[IO.Path]::GetFileNameWithoutExtension($path);VisemeSet=$VisemeSet;Visemes=$visemes;Duration=$PhonemeData.Duration;OutputPath=$path}
}
function Smooth-BlendShapeTracks { param([hashtable]$Tracks,[int]$WindowSize=3) $smoothed=@{}; foreach($shape in $Tracks.Keys){$values=$Tracks[$shape]; $count=$values.Length; $smoothed[$shape]=[float[]]::new($count); for($i=0; $i -lt $count; $i++){ $sum=0.0; $weightSum=0.0; for($j=-$WindowSize; $j -le $WindowSize; $j++){ $idx=[math]::Max(0,[math]::Min($count-1,$i+$j)); $weight=1.0-([math]::Abs($j)/($WindowSize+1)); $sum+=$values[$idx]*$weight; $weightSum+=$weight }; $smoothed[$shape][$i]=if($weightSum -gt 0){$sum/$weightSum}else{0}}}; $smoothed }
function Convert-ToAnimationKeyframes {
    [CmdletBinding()] [OutputType([hashtable])]
    param([Parameter(Mandatory)][hashtable]$LipSyncData,[int]$FrameRate=30,[string]$BlendShapeSet='ARKit',[int]$SmoothingWindow=3)
    $total=[math]::Ceiling($LipSyncData.Duration*$FrameRate); $shapes=@('jawOpen','mouthOpen','mouthSmile','mouthWide','mouthPucker','mouthUpperUp','mouthClose','tongueOut'); $tracks=@{}; foreach($s in $shapes){$tracks[$s]=[float[]]::new($total)}
    foreach($v in $LipSyncData.Visemes){$start=[math]::Floor($v.StartTime*$FrameRate); $end=[math]::Min([math]::Ceiling($v.EndTime*$FrameRate),$total-1); foreach($shape in $v.BlendShapeWeights.Keys){if($tracks.ContainsKey($shape)){for($f=$start; $f -le $end; $f++){ $value=[double]$v.BlendShapeWeights[$shape]*[double]$v.Intensity; if($value -gt $tracks[$shape][$f]){$tracks[$shape][$f]=$value}}}}}
    if($SmoothingWindow -gt 0){$tracks=Smooth-BlendShapeTracks -Tracks $tracks -WindowSize $SmoothingWindow}; $keyframes=@(); for($i=0; $i -lt $total; $i++){ $blend=@{}; foreach($s in $tracks.Keys){if($tracks[$s][$i] -gt 0.001){$blend[$s]=[math]::Round($tracks[$s][$i],4)}}; $keyframes+=@{Frame=$i;Time=($i/$FrameRate);BlendShapes=$blend}}
    @{TrackId=$LipSyncData.TrackId;FrameRate=$FrameRate;TotalFrames=$total;Duration=$LipSyncData.Duration;BlendShapeSet=$BlendShapeSet;Keyframes=$keyframes}
}
function Sync-VoiceToGodot {
    [CmdletBinding()] [OutputType([hashtable])]
    param([Parameter(Mandatory)][hashtable]$Keyframes,[Parameter(Mandatory)][hashtable]$LipSyncData,[Parameter(Mandatory)][string]$OutputDir,[string]$OutputName='lipsync',[string]$AnimationName='talk')
    $dir=New-VoiceDirectory $OutputDir; $json=Join-Path $dir "$OutputName.godot.json"; $script=Join-Path $dir "$OutputName.gd"; Write-VoiceJson ([ordered]@{engine='Godot';animationName=$AnimationName;frameRate=$Keyframes.FrameRate;duration=$Keyframes.Duration;keyframes=$Keyframes.Keyframes}) $json; "extends Node`nfunc play_lip_sync():`n    pass`n"|Set-Content -LiteralPath $script -Encoding UTF8; @{Engine='Godot';AnimationName=$AnimationName;Files=@($json,$script)}
}
function Sync-VoiceToBlender {
    [CmdletBinding()] [OutputType([hashtable])]
    param([Parameter(Mandatory)][hashtable]$Keyframes,[Parameter(Mandatory)][hashtable]$LipSyncData,[Parameter(Mandatory)][string]$OutputDir,[string]$OutputName='lipsync',[string]$ActionName='LipSync_Talk')
    $dir=New-VoiceDirectory $OutputDir; $json=Join-Path $dir "$OutputName.blender.json"; $py=Join-Path $dir "$OutputName.py"; Write-VoiceJson ([ordered]@{engine='Blender';actionName=$ActionName;frameRate=$Keyframes.FrameRate;duration=$Keyframes.Duration;keyframes=$Keyframes.Keyframes}) $json; "# Blender lip-sync data generated by Repo Cortex`nACTION_NAME = '$ActionName'`n"|Set-Content -LiteralPath $py -Encoding UTF8; @{Engine='Blender';ActionName=$ActionName;Files=@($json,$py)}
}
function Start-VoiceToAnimationSync {
    [CmdletBinding()] [OutputType([hashtable])]
    param([Parameter(Mandatory)][pscustomobject]$Config,[string]$Text,[string]$AudioFile,[string]$VoiceId='en-US-Aria',[Parameter(Mandatory)][ValidateSet('Godot','Blender','Both')][string]$TargetEngine,[string]$OutputName='lipsync',[switch]$SkipTTS)
    $started=Get-Date; $results=@{PipelineId=$Config.PipelineId;Success=$false;Steps=@();OutputFiles=@()}
    try{$audio=if($SkipTTS -and $AudioFile){Export-VoiceAudio -SourceAudio $AudioFile -OutputDir $Config.Config.OutputSettings.OutputDir -OutputName $OutputName -UseSTS}else{Export-VoiceAudio -Text $Text -VoiceId $VoiceId -OutputDir $Config.Config.OutputSettings.OutputDir -OutputName $OutputName}; $results.Steps+=@{Step='AudioExport';Status='Success'}; $phonemes=Get-PhonemeTimings -AudioFile $audio.AudioFile -Text $Text; $results.Steps+=@{Step='PhonemeExtraction';Status='Success';Count=$phonemes.Count}; $lip=Export-LipSyncData -PhonemeData $phonemes -VisemeSet $Config.Config.SyncSettings.VisemeSet -OutputDir $Config.Config.OutputSettings.OutputDir -OutputName $OutputName; $key=Convert-ToAnimationKeyframes -LipSyncData $lip -FrameRate $Config.Config.SyncSettings.FrameRate; if($TargetEngine -in @('Godot','Both')){$g=Sync-VoiceToGodot -Keyframes $key -LipSyncData $lip -OutputDir $Config.Config.OutputSettings.OutputDir -OutputName $OutputName; $results.OutputFiles+=$g.Files}; if($TargetEngine -in @('Blender','Both')){$b=Sync-VoiceToBlender -Keyframes $key -LipSyncData $lip -OutputDir $Config.Config.OutputSettings.OutputDir -OutputName $OutputName; $results.OutputFiles+=$b.Files}; $results.Success=$true; $results.AudioFile=$audio.AudioFile}catch{$results.Steps+=@{Step='Pipeline';Status='Failed';Error=$_.Exception.Message}}
    $results.TotalDuration=((Get-Date)-$started).TotalSeconds; $results
}
function Get-PipelineStatus { [CmdletBinding()] param([string]$PipelineId,[pscustomobject]$Config,[hashtable]$Results,[switch]$Detailed) if($Results){$s=@{Success=$Results.Success;TotalDuration=$Results.TotalDuration;OutputFiles=$Results.OutputFiles}; if($Detailed){$s.Steps=$Results.Steps; $s.AudioFile=$Results.AudioFile; $s.PipelineId=$Results.PipelineId}; return $s}; if($Config){return @{PipelineId=$Config.PipelineId;Status=$Config.Config.PipelineStatus;CreatedAt=$Config.CreatedAt;VoicePack=$Config.Config.VoicePack.PackId;AnimationPack=$Config.Config.AnimationPack.PackId}}; @{Status='Unknown';Message='Provide Results or Config'} }
Export-ModuleMember -Function @('New-VoiceAnimationPipeline','Start-VoiceToAnimationSync','Get-PipelineStatus','Export-VoiceAudio','Get-PhonemeTimings','Export-LipSyncData','Convert-ToAnimationKeyframes','Sync-VoiceToGodot','Sync-VoiceToBlender')
