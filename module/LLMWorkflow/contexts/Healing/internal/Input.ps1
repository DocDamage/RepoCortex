Set-StrictMode -Version Latest

function Read-SecureInput {
    <#
    .SYNOPSIS
        Reads user input with masking (for API keys).
    #>
    [CmdletBinding()]
    param(
        [string]$Prompt = "Enter value: "
    )
    
    Write-Host $Prompt -NoNewline
    $secure = Read-Host -AsSecureString
    
    # PowerShell 7+ cross-platform plain-text conversion
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        return (ConvertFrom-SecureString -AsPlainText $secure)
    }
    
    # Windows PowerShell 5.1 fallback using BSTR (Windows-only)
    if ($PSVersionTable.PSVersion.Major -lt 6 -and $env:OS -eq 'Windows_NT') {
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        try {
            return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        } finally {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        }
    }
    
    throw "SecureString plaintext conversion requires PowerShell 7+ on non-Windows platforms."
}

function Invoke-WhatIfMessage {
    <#
    .SYNOPSIS
        Displays a WhatIf message and returns whether to proceed.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [switch]$Force
    )
    
    if ($Force) {
        return $true
    }
    
    Write-Host "[WHATIF] Would perform: $Message" -ForegroundColor Cyan
    return $false
}

#===============================================================================
# Issue Detection Functions (Test-LLMWorkflowIssue)
#===============================================================================


