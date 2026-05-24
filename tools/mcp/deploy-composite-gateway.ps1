<#
.SYNOPSIS
    Deploys the Repo Cortex MCP composite gateway.
.DESCRIPTION
    PowerShell 5.1-safe gateway deployment/config helper. Loads JSON without PS7-only switches, writes runtime config, and performs optional health checks.
#>
[CmdletBinding()]
param(
    [ValidateSet('stdio','http')][string]$Transport='http',
    [ValidateRange(1,65535)][int]$Port=8080,
    [string]$Host='localhost',
    [string]$ConfigPath='',
    [switch]$AutoLoadRoutes,
    [switch]$EnablePackServers,
    [switch]$SkipHealthCheck,
    [switch]$InstallService,
    [string]$ServiceName='llm-workflow-mcp-gateway',
    [ValidateSet('DEBUG','INFO','WARN','ERROR')][string]$LogLevel='INFO'
)
$ErrorActionPreference='Stop'
$script:ScriptRoot=if(-not [string]::IsNullOrWhiteSpace($PSScriptRoot)){$PSScriptRoot}else{Split-Path -Parent $PSCommandPath}
function ConvertTo-GatewayHashtable { [CmdletBinding()] param([Parameter(Mandatory)]$InputObject) if($null -eq $InputObject){return $null}; if($InputObject -is [hashtable]){return $InputObject}; if($InputObject -is [System.Collections.IDictionary]){$h=@{}; foreach($k in $InputObject.Keys){$h[$k]=ConvertTo-GatewayHashtable $InputObject[$k]}; return $h}; if($InputObject -is [System.Collections.IEnumerable] -and -not($InputObject -is [string])){return @($InputObject|ForEach-Object{ConvertTo-GatewayHashtable $_})}; if($InputObject.GetType().Name -eq 'PSCustomObject'){$h=@{}; foreach($p in $InputObject.PSObject.Properties){$h[$p.Name]=ConvertTo-GatewayHashtable $p.Value}; return $h}; $InputObject }
function Read-GatewayJson { [CmdletBinding()] param([Parameter(Mandatory)][string]$Path) ConvertTo-GatewayHashtable (Get-Content -LiteralPath $Path -Raw -ErrorAction Stop|ConvertFrom-Json) }
function Write-GatewayJson { [CmdletBinding()] param([Parameter(Mandatory)]$Data,[Parameter(Mandatory)][string]$Path) $parent=Split-Path -Parent $Path; if($parent -and -not(Test-Path -LiteralPath $parent)){New-Item -ItemType Directory -Path $parent -Force|Out-Null}; $Data|ConvertTo-Json -Depth 20|Set-Content -LiteralPath $Path -Encoding UTF8 }
function Write-GatewayLog { [CmdletBinding()] param([ValidateSet('INFO','WARN','ERROR','DEBUG','SUCCESS')][string]$Level,[string]$Message) $line='[{0}] [Gateway-{1}] {2}' -f ([DateTime]::UtcNow.ToString('o')),$Level,$Message; if($Level -eq 'ERROR'){Write-Error $line}elseif($Level -eq 'WARN'){Write-Warning $line}else{Write-Output $line} }
function Get-DefaultGatewayConfig {
    [CmdletBinding()] [OutputType([hashtable])] param()
    @{gateway=@{name='RepoCortex-MCP-Gateway';version='1.0.0';transport=$Transport;port=$Port;host=$Host;logLevel=$LogLevel;serviceName=$ServiceName};routes=@(@{packId='godot-engine';prefix='godot_';endpoint='stdio';enabled=$false;rateLimit=100;priority=1},@{packId='blender-engine';prefix='blender_';endpoint='stdio';enabled=$false;rateLimit=100;priority=1},@{packId='rpgmaker-mz';prefix='rpgmaker_';endpoint='stdio';enabled=$false;rateLimit=100;priority=1},@{packId='common-tools';prefix='common_';endpoint='stdio';enabled=$true;rateLimit=200;priority=2});circuitBreaker=@{enabled=$true;threshold=5;timeoutSeconds=30};rateLimiting=@{enabled=$true;defaultRateLimit=100}}
}
function Import-GatewayConfig {
    [CmdletBinding()] [OutputType([hashtable])] param()
    if(-not [string]::IsNullOrWhiteSpace($ConfigPath)){if(Test-Path -LiteralPath $ConfigPath){Write-GatewayLog INFO "Loading gateway configuration from: $ConfigPath"; return Read-GatewayJson $ConfigPath}; throw "Configuration file not found: $ConfigPath"}
    $envConfig=[Environment]::GetEnvironmentVariable('MCP_GATEWAY_CONFIG','Process'); if($envConfig -and (Test-Path -LiteralPath $envConfig)){Write-GatewayLog INFO "Loading gateway configuration from env: $envConfig"; return Read-GatewayJson $envConfig}
    foreach($path in @((Join-Path $script:ScriptRoot '..\..\.llm-workflow\mcp-gateway.json'),(Join-Path $script:ScriptRoot 'gateway-config.json'),(Join-Path $env:USERPROFILE '.llm-workflow\mcp-gateway.json'))){if($path -and (Test-Path -LiteralPath $path)){Write-GatewayLog INFO "Loading gateway configuration from: $path"; return Read-GatewayJson $path}}
    Write-GatewayLog INFO 'Using default gateway configuration'; Get-DefaultGatewayConfig
}
function Initialize-PackRoutes { [CmdletBinding()] param([Parameter(Mandatory)][hashtable]$Config) if(-not $AutoLoadRoutes){return $Config}; foreach($route in @($Config.routes)){if($EnablePackServers -or $route.packId -eq 'common-tools'){$route.enabled=$true}}; $Config }
function Save-GatewayRuntimeConfig { [CmdletBinding()] param([Parameter(Mandatory)][hashtable]$Config) $runtimePath=Join-Path (Join-Path (Resolve-Path -LiteralPath '.').Path '.llm-workflow') 'mcp-gateway.runtime.json'; Write-GatewayJson $Config $runtimePath; $runtimePath }
function Test-GatewayHealth { [CmdletBinding()] param([hashtable]$Config) if($Config.gateway.transport -ne 'http'){return @{healthy=$true;mode='stdio'}}; try{$uri='http://{0}:{1}/health' -f $Config.gateway.host,$Config.gateway.port; $response=Invoke-RestMethod -Uri $uri -Method GET -TimeoutSec 5; @{healthy=($response.status -eq 'healthy' -or $response.ok -eq $true);uri=$uri;response=$response}}catch{@{healthy=$false;uri=('http://{0}:{1}/health' -f $Config.gateway.host,$Config.gateway.port);error=$_.Exception.Message}} }
$config=Import-GatewayConfig
$config.gateway.transport=$Transport; $config.gateway.port=$Port; $config.gateway.host=$Host; $config.gateway.logLevel=$LogLevel; $config=Initialize-PackRoutes -Config $config
$runtimeConfig=Save-GatewayRuntimeConfig -Config $config
$result=[ordered]@{success=$true;runtimeConfig=$runtimeConfig;transport=$Transport;host=$Host;port=$Port;serviceInstalled=$false;health=$null;routes=$config.routes}
if($InstallService){Write-GatewayLog WARN 'Service installation is not performed by this script in CI-safe mode. Use platform-specific deployment tooling.'; $result.serviceInstalled=$false}
if(-not $SkipHealthCheck){$result.health=Test-GatewayHealth -Config $config; if(-not $result.health.healthy){Write-GatewayLog WARN "Gateway health check did not pass: $($result.health.error)"}}
Write-GatewayLog SUCCESS "Gateway runtime configuration written to $runtimeConfig"
$result
