Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Structured logging and diagnostics for LLMWorkflow.
.DESCRIPTION
    Provides JSONL-based structured logging with correlation IDs,
    enabling end-to-end traceability across contexts.
#>

$script:CurrentCorrelationId = [guid]::NewGuid().ToString('N')

function Write-LLMLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Error','Warning','Information','Verbose','Debug')]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message,

        [string]$CorrelationId = $script:CurrentCorrelationId,
        [string]$Context = 'General',
        [hashtable]$Data,
        [string]$ProjectRoot = '.'
    )

    $entry = [ordered]@{
        timestamp = (Get-Date -Format 'o')
        level = $Level
        message = $Message
        correlationId = $CorrelationId
        context = $Context
    }
    if ($Data) {
        $entry.data = $Data
    }

    try {
        $logRoot = Join-Path (Resolve-Path $ProjectRoot -ErrorAction Ignore).Path '.llm-workflow/logs'
        if (-not (Test-Path -LiteralPath $logRoot)) {
            New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
        }
        $logFile = Join-Path $logRoot ("llmworkflow-{0:yyyyMMdd}.jsonl" -f (Get-Date))
        ($entry | ConvertTo-Json -Compress) | Add-Content -Path $logFile -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    catch {
        # Fallback to verbose stream if disk logging fails
        Write-Verbose "[LOG FALLBACK] [$Level] $Message"
    }

    # Also emit to appropriate stream
    switch ($Level) {
        'Error'       { Write-Error -Message $Message -ErrorAction Continue }
        'Warning'     { Write-Warning -Message $Message }
        'Information' { Write-Information -MessageData $Message -InformationAction Continue }
        'Verbose'     { Write-Verbose -Message $Message }
        'Debug'       { Write-Debug -Message $Message }
    }
}

function New-LLMCorrelationId {
    [CmdletBinding()]
    [OutputType([string])]
    param()
    $script:CurrentCorrelationId = [guid]::NewGuid().ToString('N')
    return $script:CurrentCorrelationId
}

function Get-LLMCorrelationId {
    [CmdletBinding()]
    [OutputType([string])]
    param()
    return $script:CurrentCorrelationId
}
