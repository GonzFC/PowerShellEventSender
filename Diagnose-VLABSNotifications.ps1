#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Comprehensive diagnostic script for VLABS Notifications troubleshooting

.DESCRIPTION
    This script performs extensive diagnostics to identify why Telegram notifications
    are not being sent from Windows Server Backup events.

    Checks performed:
    1. Scheduled tasks existence and configuration
    2. Task execution history
    3. Windows Server Backup events
    4. NotificationsServer connectivity
    5. Generated script syntax and execution
    6. Event Log errors
    7. Registry configuration
    8. Manual notification test

.NOTES
    Version: 1.0.0
    Author: VLABS Infrastructure
    Run as Administrator on the Windows Server experiencing notification issues

.EXAMPLE
    .\Diagnose-VLABSNotifications.ps1

    Runs all diagnostic checks and displays results
#>

[CmdletBinding()]
param()

# ============================================================================
# CONFIGURATION
# ============================================================================

$Script:RegistryPath = "HKLM:\SOFTWARE\VLABS\Notifications"
$Script:ScriptPath = "C:\ProgramData\VLABS\Notifications"
$Script:LogPath = "C:\ProgramData\VLABS\Notifications\Logs"
$Script:DiagnosticLog = "$Script:LogPath\Diagnostic-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Ensure log directory exists
if (-not (Test-Path $Script:LogPath)) {
    New-Item -Path $Script:LogPath -ItemType Directory -Force | Out-Null
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Write-DiagnosticHeader {
    param([string]$Title)

    $separator = "=" * 80
    Write-Host ""
    Write-Host $separator -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host $separator -ForegroundColor Cyan
    Write-Host ""

    Add-Content -Path $Script:DiagnosticLog -Value "`n$separator`n  $Title`n$separator`n"
}

function Write-DiagnosticResult {
    param(
        [string]$Message,
        [ValidateSet('Success', 'Warning', 'Error', 'Info')]
        [string]$Type = 'Info'
    )

    $colors = @{
        Success = 'Green'
        Warning = 'Yellow'
        Error   = 'Red'
        Info    = 'White'
    }

    $symbols = @{
        Success = '[✓]'
        Warning = '[!]'
        Error   = '[✗]'
        Info    = '[i]'
    }

    Write-Host "$($symbols[$Type]) $Message" -ForegroundColor $colors[$Type]
    Add-Content -Path $Script:DiagnosticLog -Value "$($symbols[$Type]) $Message"
}

# ============================================================================
# DIAGNOSTIC CHECKS
# ============================================================================

function Test-ScheduledTasks {
    Write-DiagnosticHeader "1. Scheduled Tasks Check"

    $tasks = Get-ScheduledTask -TaskName "VLABS*" -ErrorAction SilentlyContinue

    if (-not $tasks) {
        Write-DiagnosticResult "No VLABS scheduled tasks found!" -Type Error
        Write-DiagnosticResult "Run the setup wizard to create tasks" -Type Warning
        return $false
    }

    Write-DiagnosticResult "Found $($tasks.Count) VLABS scheduled task(s)" -Type Success

    foreach ($task in $tasks) {
        Write-Host "`n  Task: $($task.TaskName)" -ForegroundColor Yellow
        Write-DiagnosticResult "    State: $($task.State)" -Type Info
        Write-DiagnosticResult "    Last Run: $($task.LastRunTime)" -Type Info
        Write-DiagnosticResult "    Last Result: $($task.LastTaskResult)" -Type Info

        # Check if task is enabled
        if ($task.State -ne 'Ready') {
            Write-DiagnosticResult "    WARNING: Task is not in Ready state!" -Type Warning
        }

        # Get detailed task info
        $taskInfo = Get-ScheduledTaskInfo -TaskName $task.TaskName -ErrorAction SilentlyContinue
        if ($taskInfo) {
            Write-DiagnosticResult "    Next Run: $($taskInfo.NextRunTime)" -Type Info
            Write-DiagnosticResult "    Number of Missed Runs: $($taskInfo.NumberOfMissedRuns)" -Type Info
        }

        # Check action details
        $taskDetail = Export-ScheduledTask -TaskName $task.TaskName
        $taskXml = [xml]$taskDetail

        $action = $taskXml.Task.Actions.Exec
        Write-DiagnosticResult "    Execute: $($action.Command)" -Type Info
        Write-DiagnosticResult "    Arguments: $($action.Arguments)" -Type Info

        # Check if PowerShell path is absolute
        if ($action.Command -eq "PowerShell.exe") {
            Write-DiagnosticResult "    BUG FOUND: Using relative PowerShell.exe path!" -Type Error
            Write-DiagnosticResult "    Should be: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Type Warning
        } else {
            Write-DiagnosticResult "    PowerShell path is absolute (good)" -Type Success
        }

        # Check triggers
        $triggers = $taskXml.Task.Triggers.EventTrigger
        if ($triggers) {
            Write-DiagnosticResult "    Event Trigger Configured: Yes" -Type Success
            $subscription = $triggers.Subscription
            if ($subscription -match 'EventID=(\d+)') {
                Write-DiagnosticResult "    Monitoring Event IDs: $($matches[1])" -Type Info
            }
        } else {
            Write-DiagnosticResult "    Event Trigger Configured: No!" -Type Error
        }
    }

    return $true
}

function Test-TaskExecutionHistory {
    Write-DiagnosticHeader "2. Task Execution History (Last 7 Days)"

    $startTime = (Get-Date).AddDays(-7)

    try {
        $events = Get-WinEvent -FilterHashtable @{
            LogName   = 'Microsoft-Windows-TaskScheduler/Operational'
            StartTime = $startTime
        } -ErrorAction SilentlyContinue | Where-Object {
            $_.Message -like "*VLABS*"
        } | Select-Object -First 50

        if (-not $events) {
            Write-DiagnosticResult "No VLABS task execution events found in last 7 days" -Type Warning
            Write-DiagnosticResult "This suggests tasks are NOT being triggered!" -Type Error
            return $false
        }

        Write-DiagnosticResult "Found $($events.Count) task execution events" -Type Success

        # Group by event ID
        $eventGroups = $events | Group-Object Id

        foreach ($group in $eventGroups) {
            $eventId = $group.Name
            $count = $group.Count

            $description = switch ($eventId) {
                100 { "Task Started" }
                102 { "Task Completed Successfully" }
                103 { "Task Failed" }
                107 { "Task Triggered (Time)" }
                108 { "Task Triggered (Event)" }
                110 { "Task Triggered (Registration)" }
                200 { "Action Started" }
                201 { "Action Completed" }
                default { "Event ID $eventId" }
            }

            Write-DiagnosticResult "  Event $eventId ($description): $count occurrences" -Type Info
        }

        # Show recent executions
        Write-Host "`n  Recent Executions:" -ForegroundColor Yellow
        $events | Select-Object -First 10 | ForEach-Object {
            Write-DiagnosticResult "    $($_.TimeCreated): [ID:$($_.Id)] $($_.Message.Split("`n")[0])" -Type Info
        }

        # Check for failures
        $failures = $events | Where-Object { $_.Id -eq 103 }
        if ($failures) {
            Write-DiagnosticResult "`n  FAILURES DETECTED: $($failures.Count) failed executions!" -Type Error
            $failures | Select-Object -First 3 | ForEach-Object {
                Write-DiagnosticResult "    $($_.TimeCreated): $($_.Message)" -Type Error
            }
        }

        return $true
    }
    catch {
        Write-DiagnosticResult "Error checking task history: $($_.Exception.Message)" -Type Error
        return $false
    }
}

function Test-BackupEvents {
    Write-DiagnosticHeader "3. Windows Server Backup Events (Last 30 Days)"

    $startTime = (Get-Date).AddDays(-30)

    try {
        $events = Get-WinEvent -FilterHashtable @{
            LogName   = 'Microsoft-Windows-Backup'
            StartTime = $startTime
        } -MaxEvents 100 -ErrorAction SilentlyContinue

        if (-not $events) {
            Write-DiagnosticResult "No backup events found in last 30 days" -Type Warning
            Write-DiagnosticResult "Verify Windows Server Backup is running" -Type Warning
            return $false
        }

        Write-DiagnosticResult "Found $($events.Count) backup events" -Type Success

        # Group by event ID
        $eventGroups = $events | Group-Object Id

        foreach ($group in $eventGroups) {
            $eventId = $group.Name
            $count = $group.Count

            $description = switch ($eventId) {
                4  { "Backup Succeeded" }
                5  { "Backup Failed" }
                14 { "Backup Operation Completed" }
                2013 { "Low Disk Space" }
                default { "Event ID $eventId" }
            }

            $typeColor = if ($eventId -eq 4) { 'Success' } elseif ($eventId -eq 5) { 'Error' } else { 'Info' }
            Write-DiagnosticResult "  Event $eventId ($description): $count occurrences" -Type $typeColor
        }

        # Show recent Event 14 (should trigger tasks)
        $event14s = $events | Where-Object { $_.Id -eq 14 } | Select-Object -First 5
        if ($event14s) {
            Write-Host "`n  Recent Event 14 (Backup Operation Completed):" -ForegroundColor Yellow
            $event14s | ForEach-Object {
                Write-DiagnosticResult "    $($_.TimeCreated)" -Type Info
            }
        } else {
            Write-DiagnosticResult "`n  No Event 14 found - tasks won't trigger!" -Type Error
        }

        # Show recent Event 5 (failures)
        $event5s = $events | Where-Object { $_.Id -eq 5 } | Select-Object -First 3
        if ($event5s) {
            Write-Host "`n  Recent Event 5 (Backup Failed):" -ForegroundColor Yellow
            $event5s | ForEach-Object {
                Write-DiagnosticResult "    $($_.TimeCreated): $($_.Message.Substring(0, [Math]::Min(100, $_.Message.Length)))..." -Type Error
            }
        }

        return $true
    }
    catch {
        Write-DiagnosticResult "Error checking backup events: $($_.Exception.Message)" -Type Error
        return $false
    }
}

function Test-RegistryConfiguration {
    Write-DiagnosticHeader "4. Registry Configuration"

    if (-not (Test-Path $Script:RegistryPath)) {
        Write-DiagnosticResult "Registry path not found: $Script:RegistryPath" -Type Error
        Write-DiagnosticResult "Run the setup wizard to configure" -Type Warning
        return $false
    }

    $config = Get-ItemProperty -Path $Script:RegistryPath -ErrorAction SilentlyContinue

    if ($config.NotificationsServerIP) {
        Write-DiagnosticResult "NotificationsServer IP: $($config.NotificationsServerIP)" -Type Success
    } else {
        Write-DiagnosticResult "NotificationsServer IP: NOT CONFIGURED" -Type Error
        return $false
    }

    Write-DiagnosticResult "WSBackup Enabled: $([bool]$config.WSBackupEnabled)" -Type Info
    Write-DiagnosticResult "DiskSpace Enabled: $([bool]$config.DiskSpaceEnabled)" -Type Info

    return $true
}

function Test-NotificationsServer {
    Write-DiagnosticHeader "5. NotificationsServer Connectivity"

    $config = Get-ItemProperty -Path $Script:RegistryPath -ErrorAction SilentlyContinue
    if (-not $config.NotificationsServerIP) {
        Write-DiagnosticResult "No server IP configured" -Type Error
        return $false
    }

    $serverIP = $config.NotificationsServerIP
    $serverPort = 8089

    Write-DiagnosticResult "Testing connection to $serverIP`:$serverPort" -Type Info

    # Test health endpoint
    try {
        $healthUri = "http://${serverIP}:${serverPort}/health"
        $response = Invoke-RestMethod -Uri $healthUri -TimeoutSec 5 -ErrorAction Stop

        Write-DiagnosticResult "Server Status: $($response.status)" -Type Success
        Write-DiagnosticResult "Server Version: $($response.version)" -Type Info
        Write-DiagnosticResult "Uptime: $($response.uptime_seconds) seconds" -Type Info
        Write-DiagnosticResult "Notifications Sent Today: $($response.notifications_sent_today)" -Type Info

        if ($response.last_notification) {
            Write-DiagnosticResult "Last Notification: $($response.last_notification)" -Type Info
        } else {
            Write-DiagnosticResult "Last Notification: None (This is the problem!)" -Type Warning
        }
    }
    catch {
        Write-DiagnosticResult "Cannot reach server: $($_.Exception.Message)" -Type Error
        return $false
    }

    # Test notify endpoint with dry run
    Write-Host "`n  Testing /api/v1/notify endpoint..." -ForegroundColor Yellow
    try {
        $notifyUri = "http://${serverIP}:${serverPort}/api/v1/notify"
        $testPayload = @{
            type     = "telegram"
            channels = @("SuccessfulBackups")
            subject  = "DIAGNOSTIC TEST - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            body     = "This is a diagnostic test from $env:COMPUTERNAME`n`nIf you see this, the API is working!"
        } | ConvertTo-Json -Depth 3

        Write-DiagnosticResult "Sending test notification..." -Type Info
        Invoke-RestMethod -Uri $notifyUri -Method Post -Body $testPayload -ContentType "application/json" -TimeoutSec 10 -ErrorAction Stop | Out-Null

        Write-DiagnosticResult "Test notification sent successfully!" -Type Success
        Write-DiagnosticResult "CHECK TELEGRAM: You should see a diagnostic test message" -Type Warning
    }
    catch {
        Write-DiagnosticResult "Test notification failed: $($_.Exception.Message)" -Type Error
        Write-DiagnosticResult "Response: $($_.ErrorDetails.Message)" -Type Error
        return $false
    }

    return $true
}

function Test-GeneratedScripts {
    Write-DiagnosticHeader "6. Generated PowerShell Scripts"

    if (-not (Test-Path $Script:ScriptPath)) {
        Write-DiagnosticResult "Script directory not found: $Script:ScriptPath" -Type Error
        return $false
    }

    $scripts = Get-ChildItem -Path $Script:ScriptPath -Filter "*.ps1" -ErrorAction SilentlyContinue

    if (-not $scripts) {
        Write-DiagnosticResult "No generated scripts found" -Type Warning
        return $false
    }

    Write-DiagnosticResult "Found $($scripts.Count) generated script(s)" -Type Success

    foreach ($script in $scripts) {
        Write-Host "`n  Script: $($script.Name)" -ForegroundColor Yellow
        Write-DiagnosticResult "    Path: $($script.FullName)" -Type Info
        Write-DiagnosticResult "    Size: $($script.Length) bytes" -Type Info
        Write-DiagnosticResult "    Modified: $($script.LastWriteTime)" -Type Info

        # Check syntax
        try {
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $script.FullName -Raw), [ref]$null)
            Write-DiagnosticResult "    Syntax: Valid" -Type Success
        }
        catch {
            Write-DiagnosticResult "    Syntax: INVALID - $($_.Exception.Message)" -Type Error
        }

        # Check for known issues
        $content = Get-Content $script.FullName -Raw

        if ($content -match 'Write-EventLog.*-Source\s+"WSH"') {
            Write-DiagnosticResult "    BUG FOUND: Uses Event Log source 'WSH' (likely not registered!)" -Type Error
        }

        if ($content -match 'exit 0' -or $content -match 'exit\s+0') {
            Write-DiagnosticResult "    WARNING: Contains 'exit 0' - may exit silently" -Type Warning
        }

        if ($content -notmatch 'Out-File.*-Append' -and $content -notmatch 'Add-Content') {
            Write-DiagnosticResult "    WARNING: No file logging found - errors are invisible!" -Type Error
        }
    }

    return $true
}

function Test-ManualScriptExecution {
    Write-DiagnosticHeader "7. Manual Script Execution Test"

    $wsbackupScript = "$Script:ScriptPath\WSBackup-Notification.ps1"

    if (-not (Test-Path $wsbackupScript)) {
        Write-DiagnosticResult "WSBackup script not found: $wsbackupScript" -Type Warning
        Write-DiagnosticResult "Skipping manual execution test" -Type Info
        return $false
    }

    Write-DiagnosticResult "Attempting to execute WSBackup notification script..." -Type Info
    Write-DiagnosticResult "This will check for recent backup events and send notification if found" -Type Info

    try {
        $output = & PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File $wsbackupScript 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-DiagnosticResult "Script executed successfully (exit code 0)" -Type Success
        } else {
            Write-DiagnosticResult "Script exited with code: $LASTEXITCODE" -Type Warning
        }

        if ($output) {
            Write-Host "`n  Script Output:" -ForegroundColor Yellow
            $output | ForEach-Object {
                Write-DiagnosticResult "    $_" -Type Info
            }
        } else {
            Write-DiagnosticResult "    No output (script may exit silently)" -Type Warning
        }
    }
    catch {
        Write-DiagnosticResult "Script execution failed: $($_.Exception.Message)" -Type Error
        return $false
    }

    return $true
}

function Test-EventLogSource {
    Write-DiagnosticHeader "8. Event Log Source Registration"

    $sourceName = "WSH"

    try {
        $sourceExists = [System.Diagnostics.EventLog]::SourceExists($sourceName)

        if ($sourceExists) {
            Write-DiagnosticResult "Event Log source '$sourceName' is registered" -Type Success

            # Get the log it's registered to
            $logName = [System.Diagnostics.EventLog]::LogNameFromSourceName($sourceName, ".")
            Write-DiagnosticResult "  Registered to log: $logName" -Type Info
        } else {
            Write-DiagnosticResult "Event Log source '$sourceName' is NOT registered!" -Type Error
            Write-DiagnosticResult "This is why error logging fails silently!" -Type Warning
            Write-DiagnosticResult "Generated scripts cannot log errors to Event Log" -Type Error
        }
    }
    catch {
        Write-DiagnosticResult "Error checking Event Log source: $($_.Exception.Message)" -Type Error
        return $false
    }

    return $sourceExists
}

function Show-Recommendations {
    Write-DiagnosticHeader "9. Recommendations & Next Steps"

    Write-DiagnosticResult "Based on the diagnostic results above, here are the issues found:" -Type Info
    Write-Host ""

    $recommendations = @()

    # Check if PowerShell path bug exists
    $tasks = Get-ScheduledTask -TaskName "VLABS*" -ErrorAction SilentlyContinue
    if ($tasks) {
        $taskDetail = Export-ScheduledTask -TaskName $tasks[0].TaskName
        if ($taskDetail -match '<Command>PowerShell\.exe</Command>') {
            $recommendations += @{
                Issue       = "PowerShell.exe uses relative path"
                Impact      = "HIGH - Task may fail to execute"
                Fix         = "Update task action to use: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
                AutoFixable = $true
            }
        }
    }

    # Check Event Log source
    if (-not [System.Diagnostics.EventLog]::SourceExists("WSH")) {
        $recommendations += @{
            Issue       = "Event Log source 'WSH' not registered"
            Impact      = "HIGH - Error logging fails silently"
            Fix         = "Register source OR switch to file-based logging"
            AutoFixable = $true
        }
    }

    # Check for file logging
    $wsbackupScript = "$Script:ScriptPath\WSBackup-Notification.ps1"
    if (Test-Path $wsbackupScript) {
        $content = Get-Content $wsbackupScript -Raw
        if ($content -notmatch 'Out-File.*-Append' -and $content -notmatch 'Add-Content') {
            $recommendations += @{
                Issue       = "No file-based logging in generated scripts"
                Impact      = "CRITICAL - Cannot debug failures"
                Fix         = "Add transcript logging to generated scripts"
                AutoFixable = $true
            }
        }
    }

    if ($recommendations.Count -eq 0) {
        Write-DiagnosticResult "No critical issues found!" -Type Success
        Write-DiagnosticResult "Configuration appears correct" -Type Success
        Write-Host ""
        Write-DiagnosticResult "If notifications still don't work, check:" -Type Info
        Write-DiagnosticResult "  1. Telegram bot and channel configuration on NotificationsServer" -Type Info
        Write-DiagnosticResult "  2. Transport names match (SuccessfulBackups, FailedBackups)" -Type Info
        Write-DiagnosticResult "  3. Wait for next backup event and check Task Scheduler history" -Type Info
    } else {
        Write-DiagnosticResult "FOUND $($recommendations.Count) ISSUE(S) THAT NEED FIXING:" -Type Error
        Write-Host ""

        $i = 1
        foreach ($rec in $recommendations) {
            Write-Host "  Issue $i`: $($rec.Issue)" -ForegroundColor Red
            Write-Host "  Impact: $($rec.Impact)" -ForegroundColor Yellow
            Write-Host "  Fix: $($rec.Fix)" -ForegroundColor Green
            Write-Host ""
            $i++
        }

        Write-DiagnosticResult "Run the wizard again to recreate tasks with fixes" -Type Warning
        Write-DiagnosticResult "Or wait for the updated script version with these bugs fixed" -Type Info
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

function Main {
    Clear-Host
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  VLABS Notifications - Comprehensive Diagnostic Tool" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  This diagnostic will identify why Telegram notifications are failing" -ForegroundColor White
    Write-Host "  Diagnostic log: $Script:DiagnosticLog" -ForegroundColor Gray
    Write-Host ""

    # Initialize log
    Add-Content -Path $Script:DiagnosticLog -Value "VLABS Notifications Diagnostic - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Add-Content -Path $Script:DiagnosticLog -Value "Computer: $env:COMPUTERNAME"
    Add-Content -Path $Script:DiagnosticLog -Value "User: $env:USERNAME"
    Add-Content -Path $Script:DiagnosticLog -Value "PowerShell Version: $($PSVersionTable.PSVersion)"

    # Run all diagnostic checks
    Test-ScheduledTasks
    Test-TaskExecutionHistory
    Test-BackupEvents
    Test-RegistryConfiguration
    Test-NotificationsServer
    Test-GeneratedScripts
    Test-EventLogSource
    Test-ManualScriptExecution
    Show-Recommendations

    # Final summary
    Write-DiagnosticHeader "Diagnostic Complete"
    Write-DiagnosticResult "Full diagnostic log saved to: $Script:DiagnosticLog" -Type Success
    Write-Host ""
    Write-Host "  Review the results above to identify the issue(s)" -ForegroundColor Yellow
    Write-Host "  Most common problems:" -ForegroundColor White
    Write-Host "    1. PowerShell.exe relative path in task action" -ForegroundColor Gray
    Write-Host "    2. Event Log source not registered (silent error failures)" -ForegroundColor Gray
    Write-Host "    3. Scripts exit silently without logging" -ForegroundColor Gray
    Write-Host "    4. Task not triggering on backup events" -ForegroundColor Gray
    Write-Host ""

    Read-Host "Press Enter to exit"
}

# Run main function
Main
