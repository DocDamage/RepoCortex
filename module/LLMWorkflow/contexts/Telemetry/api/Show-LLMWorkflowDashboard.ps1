Set-StrictMode -Version Latest

function Invoke-LLMWorkflowDashboardMain {
    [CmdletBinding()]
    param()

    $isInteractive = Test-InteractiveShell
    $useAnsi = Test-AnsiSupport
    $useColors = $isInteractive

    # Non-interactive mode: just run checks and output plain text
    if (-not $isInteractive) {
        $result = Invoke-DashboardCheck -ProjectRoot $ProjectRoot -Provider $Provider -CheckContext:$CheckContext -TimeoutSec $TimeoutSec -OnCheckComplete { param($c, $t, $n, $s, $d, $l) }
        Write-PlainTextReport -Checks $result.Checks -ProjectPath $result.ProjectPath -Provider $Provider -ProviderResolved $result.ProviderResolved
        $failed = @($result.Checks | Where-Object { (Get-DashboardCheckStatus -Check $_) -eq "FAIL" })
        if ($failed.Count -gt 0) { return 1 }
        return 0
    }

    # Interactive dashboard mode
    $checkResults = @{}
    $autoRefresh = $false
    $lastCheckTime = $null
    $running = $true
    $firstRun = $true

    while ($running) {
        # Clear screen for refresh
        if (-not $firstRun) {
            Clear-Host
        }
        $firstRun = $false
        
        # Draw header
        Write-DashboardHeader -UseAnsi:$useAnsi -UseColors:$useColors
        Write-Host ""
        
        # Run checks if needed
        if ($lastCheckTime -eq $null -or $autoRefresh) {
            $checkResults = @{}
            $completedCount = 0
            
            $onComplete = {
                param($current, $total, $name, $status, $detail, $latency)
                $script:completedCount = $current
                $script:checkResults[$name] = @{
                    Status = $status
                    Detail = $detail
                    LatencyMs = $latency
                }
            }
            
            # Show progress before detailed results
            if ($useAnsi -or $useColors) {
                Write-Host "Running checks..." -ForegroundColor Cyan
            }
        }
        
        # Execute checks
        $result = Invoke-DashboardCheck -ProjectRoot $ProjectRoot -Provider $Provider -CheckContext:$CheckContext -TimeoutSec $TimeoutSec -OnCheckComplete $onComplete
        $lastCheckTime = Get-Date
        
        # Display results
        Write-Host ""
        foreach ($check in $result.Checks) {
            $statusStr = Get-DashboardCheckStatus -Check $check
            Write-CheckResult -Name $check.Name -Status $statusStr -Detail $check.Detail -LatencyMs ($check.LatencyMs, 0 | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum) -UseAnsi:$useAnsi -UseColors:$useColors
        }
        
        # Calculate summary
        $statuses = @($result.Checks | ForEach-Object { Get-DashboardCheckStatus -Check $_ })
        $passCount = @($statuses | Where-Object { $_ -eq "OK" }).Count
        $warnCount = @($statuses | Where-Object { $_ -eq "WARN" }).Count
        $failCount = @($statuses | Where-Object { $_ -eq "FAIL" }).Count
        
        # Status message
        $statusMsg = "Last updated: $($lastCheckTime.ToString('HH:mm:ss'))"
        if ($autoRefresh) {
            $statusMsg += " | Auto-refresh: ON ($RefreshInterval sec)"
        } else {
            $statusMsg += " | Auto-refresh: OFF"
        }
        if ($result.ProviderResolved) {
            $statusMsg += " | Provider: $($result.ProviderResolved.Profile.Name)"
        }
        
        Write-Host ""
        Write-DashboardFooter -UseAnsi:$useAnsi -UseColors:$useColors -StatusMessage $statusMsg -PassCount $passCount -WarnCount $warnCount -FailCount $failCount
        
        # Wait for user input
        if ($autoRefresh -and $RefreshInterval -gt 0) {
            $timeout = $RefreshInterval * 1000
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $keyPressed = $false
            
            while ($stopwatch.ElapsedMilliseconds -lt $timeout -and -not $keyPressed) {
                if ($Host.UI.RawUI.KeyAvailable) {
                    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                    $keyPressed = $true
                    
                    switch ($key.Character.ToString().ToUpper()) {
                        "Q" { $running = $false }
                        "R" { $lastCheckTime = $null; break }
                        "A" { $autoRefresh = -not $autoRefresh }
                    }
                }
                Start-Sleep -Milliseconds 100
            }
            $stopwatch.Stop()
        } else {
            # Manual mode - wait for key press
            Write-Host ""
            Write-Host "Press a key..." -ForegroundColor Gray -NoNewline
            
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            
            switch ($key.Character.ToString().ToUpper()) {
                "Q" { $running = $false }
                "R" { $lastCheckTime = $null }
                "A" { $autoRefresh = -not $autoRefresh }
            }
        }
    }

    # Exit code
    $failed = @($result.Checks | Where-Object { (Get-DashboardCheckStatus -Check $_) -eq "FAIL" })
    if ($failed.Count -gt 0) { return 1 }
    return 0
}

if ($MyInvocation.InvocationName -ne '.') {
    $dashboardResult = Invoke-LLMWorkflowDashboardMain
    # exit() would terminate the calling shell if this script is dot-sourced.
    # Use return to safely propagate the exit code in all contexts.
    return $dashboardResult
}

#endregion
