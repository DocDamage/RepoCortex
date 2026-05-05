Set-StrictMode -Version Latest

function Write-DashboardHeader {
    [CmdletBinding()]
    param([switch]$UseAnsi, [switch]$UseColors)
    
    if ($UseAnsi) {
        $a = $script:Ansi
        Write-Host "$($a.Bold)$($a.Cyan)========================================$($a.Reset)"
        Write-Host "$($a.Bold)$($a.Cyan)   $($script:ProductBrandName) Dashboard $($a.BrightYellow)v$($script:DashboardVersion)$($a.Reset)"
        Write-Host "$($a.Dim)   $($script:ProductModuleName) operations telemetry$($a.Reset)"
        Write-Host "$($a.Bold)$($a.Cyan)========================================$($a.Reset)"
    } elseif ($UseColors) {
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "   $($script:ProductBrandName) Dashboard v$($script:DashboardVersion)" -ForegroundColor Cyan
        Write-Host "   $($script:ProductModuleName) operations telemetry" -ForegroundColor Gray
        Write-Host "========================================" -ForegroundColor Cyan
    } else {
        Write-Output "========================================"
        Write-Output "   $($script:ProductBrandName) Dashboard v$($script:DashboardVersion)"
        Write-Output "   $($script:ProductModuleName) operations telemetry"
        Write-Output "========================================"
    }
}

function Write-DashboardFooter {
    [CmdletBinding()]
    param(
        [switch]$UseAnsi,
        [switch]$UseColors,
        [string]$StatusMessage = "",
        [int]$PassCount = 0,
        [int]$WarnCount = 0,
        [int]$FailCount = 0
    )
    
    if ($UseAnsi) {
        $a = $script:Ansi
        Write-Host "$($a.Bold)========================================$($a.Reset)"
        Write-Host "$($a.Bold)Summary:$($a.Reset) " -NoNewline
        Write-Host "$($a.Green)[OK: $PassCount]$($a.Reset) " -NoNewline
        if ($WarnCount -gt 0) { Write-Host "$($a.Yellow)[WARN: $WarnCount]$($a.Reset) " -NoNewline }
        if ($FailCount -gt 0) { Write-Host "$($a.Red)[FAIL: $FailCount]$($a.Reset) " -NoNewline }
        Write-Host ""
        if ($StatusMessage) { Write-Host "$($a.Dim)$StatusMessage$($a.Reset)" }
        Write-Host "$($a.Bold)========================================$($a.Reset)"
        Write-Host "$($a.Dim)Controls: [R]erun  [Q]uit  [A]uto-refresh$($a.Reset)"
    } elseif ($UseColors) {
        Write-Host "========================================" -ForegroundColor White
        Write-Host "Summary: " -NoNewline
        Write-Host "[OK: $PassCount]" -ForegroundColor Green -NoNewline
        if ($WarnCount -gt 0) { Write-Host " [WARN: $WarnCount]" -ForegroundColor Yellow -NoNewline }
        if ($FailCount -gt 0) { Write-Host " [FAIL: $FailCount]" -ForegroundColor Red -NoNewline }
        Write-Host ""
        if ($StatusMessage) { Write-Host $StatusMessage -ForegroundColor Gray }
        Write-Host "========================================" -ForegroundColor White
        Write-Host "Controls: [R]erun  [Q]uit  [A]uto-refresh" -ForegroundColor Gray
    } else {
        Write-Output "========================================"
        Write-Output "Summary: [OK: $PassCount] [WARN: $WarnCount] [FAIL: $FailCount]"
        if ($StatusMessage) { Write-Output $StatusMessage }
        Write-Output "========================================"
        Write-Output "Controls: [R]erun  [Q]uit  [A]uto-refresh"
    }
}

function Write-CheckResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [Parameter(Mandatory=$true)]
        [ValidateSet("OK", "WARN", "FAIL", "PENDING")]
        [string]$Status,
        [string]$Detail = "",
        [int]$LatencyMs = 0,
        [switch]$UseAnsi,
        [switch]$UseColors,
        [int]$MaxNameWidth = 25
    )
    
    $paddedName = $Name.PadRight($MaxNameWidth)
    
    if ($UseAnsi) {
        $a = $script:Ansi
        switch ($Status) {
            "OK" {
                Write-Host "[$($a.Green)OK$($a.Reset)]   $paddedName " -NoNewline
            }
            "WARN" {
                Write-Host "[$($a.Yellow)WARN$($a.Reset)]  $paddedName " -NoNewline
            }
            "FAIL" {
                Write-Host "[$($a.Red)FAIL$($a.Reset)]  $paddedName " -NoNewline
            }
            "PENDING" {
                Write-Host "[$($a.Dim)....$($a.Reset)]  $paddedName " -NoNewline
            }
        }
        Write-Host "$($a.Dim)$Detail$($a.Reset)" -NoNewline
        if ($LatencyMs -gt 0) {
            Write-Host " $($a.Cyan)($($LatencyMs)ms)$($a.Reset)"
        } else {
            Write-Host ""
        }
    } elseif ($UseColors) {
        switch ($Status) {
            "OK" {
                Write-Host "[OK]   $paddedName " -NoNewline -ForegroundColor Green
            }
            "WARN" {
                Write-Host "[WARN] $paddedName " -NoNewline -ForegroundColor Yellow
            }
            "FAIL" {
                Write-Host "[FAIL] $paddedName " -NoNewline -ForegroundColor Red
            }
            "PENDING" {
                Write-Host "[....] $paddedName " -NoNewline -ForegroundColor Gray
            }
        }
        Write-Host $Detail -NoNewline -ForegroundColor Gray
        if ($LatencyMs -gt 0) {
            Write-Host " ($($LatencyMs)ms)" -ForegroundColor Cyan
        } else {
            Write-Host ""
        }
    } else {
        $statusStr = switch ($Status) {
            "OK" { "[OK]" }
            "WARN" { "[WARN]" }
            "FAIL" { "[FAIL]" }
            "PENDING" { "[....]" }
        }
        $latencyStr = if ($LatencyMs -gt 0) { " ($($LatencyMs)ms)" } else { "" }
        Write-Output "$statusStr $paddedName $Detail$latencyStr"
    }
}

function Write-ProgressBar {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [int]$Current,
        [Parameter(Mandatory=$true)]
        [int]$Total,
        [switch]$UseAnsi,
        [switch]$UseColors,
        [int]$Width = 40
    )
    
    $percent = if ($Total -gt 0) { [int](($Current / $Total) * 100) } else { 0 }
    $filled = [int](($Current / $Total) * $Width)
    $empty = $Width - $filled
    
    $bar = "[" + ("#" * $filled) + ("-" * $empty) + "]"
    
    if ($UseAnsi) {
        $a = $script:Ansi
        Write-Host "Progress: $bar " -NoNewline
        Write-Host "$($a.Bold)$($percent)%$($a.Reset)" -NoNewline
        Write-Host " ($Current/$Total)"
    } elseif ($UseColors) {
        Write-Host "Progress: $bar " -NoNewline
        Write-Host "$percent%" -NoNewline -ForegroundColor White
        Write-Host " ($Current/$Total)"
    } else {
        Write-Output "Progress: $bar $percent% ($Current/$Total)"
    }
}

function Write-PlainTextReport {
    [CmdletBinding()]
    param(
        [array]$Checks,
        [string]$ProjectPath,
        [string]$Provider,
        [hashtable]$ProviderResolved
    )
    
    Write-Output "[llm-workflow-doctor] project=$ProjectPath"
    Write-Output "[llm-workflow-doctor] provider.requested=$Provider"
    if ($ProviderResolved -and $ProviderResolved.Profile) {
        Write-Output "[llm-workflow-doctor] provider.resolved=$($ProviderResolved.Profile.Name)"
    }
    
    foreach ($check in $Checks) {
        $status = Get-DashboardCheckStatus -Check $check
        if ($check.LatencyMs -ne $null -and $check.LatencyMs -gt 0) {
            Write-Output ("[{0}] {1}: {2} ({3}ms)" -f $status, $check.Name, $check.Detail, $check.LatencyMs)
        } else {
            Write-Output ("[{0}] {1}: {2}" -f $status, $check.Name, $check.Detail)
        }
    }
    
    $failed = @($Checks | Where-Object { (Get-DashboardCheckStatus -Check $_) -eq "FAIL" })
    if ($failed.Count -eq 0) {
        Write-Output "[llm-workflow-doctor] all checks passed"
    } else {
        Write-Warning ("[llm-workflow-doctor] failed checks: {0}" -f ($failed.Name -join ", "))
    }
}

