# Troubleshooting Guide

**For when Telegram notifications are not being sent**

---

## Quick Diagnostic

If Windows Server Backup notifications are not appearing in Telegram, run the comprehensive diagnostic script:

### Step 1: Download and Run Diagnostic

```powershell
# On Windows Server, as Administrator:
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
iwr -useb https://raw.githubusercontent.com/GonzFC/PowerShellEventSender/main/Diagnose-VLABSNotifications.ps1 | iex
```

Or download and inspect first:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$script = (iwr 'https://raw.githubusercontent.com/GonzFC/PowerShellEventSender/main/Diagnose-VLABSNotifications.ps1' -UseBasicParsing).Content
$script | Out-File "$env:TEMP\Diagnose.ps1"
notepad "$env:TEMP\Diagnose.ps1"  # Review the script
& "$env:TEMP\Diagnose.ps1"         # Run as Administrator
```

### Step 2: Review Diagnostic Results

The script will check:

1. ✅ **Scheduled Tasks** - Are they created and enabled?
2. ✅ **Task Execution History** - Did they run when backups completed?
3. ✅ **Backup Events** - Are Event IDs 4, 5, 14 being logged?
4. ✅ **Registry Configuration** - Is server IP configured?
5. ✅ **NotificationsServer** - Is it reachable? (Sends test notification!)
6. ✅ **Generated Scripts** - Syntax valid? Known bugs present?
7. ✅ **Event Log Source** - Is "WSH" registered?
8. ✅ **Manual Execution** - Does script run successfully when triggered manually?

### Step 3: Check Diagnostic Log

Full diagnostic log saved to:
```
C:\ProgramData\VLABS\Notifications\Logs\Diagnostic-YYYYMMDD-HHMMSS.log
```

---

## Common Issues & Fixes

### Issue 1: PowerShell.exe Relative Path

**Symptoms:**
- Diagnostic shows: `BUG FOUND: Using relative PowerShell.exe path!`
- Tasks appear configured but never execute

**Cause:**
- Task action uses `PowerShell.exe` instead of full path
- When running as SYSTEM, relative path may not resolve

**Fix:**
Run the setup wizard again to recreate tasks with fixed path.

---

### Issue 2: Event Log Source Not Registered

**Symptoms:**
- Diagnostic shows: `Event Log source 'WSH' is NOT registered!`
- Scripts execute but errors are invisible
- No error entries in Event Viewer

**Cause:**
- Generated scripts try to write to Event Log using source "WSH"
- Source was never registered, so `Write-EventLog` silently fails
- All error logging is lost

**Fix:**
Wait for updated script version with file-based logging instead of Event Log.

---

### Issue 3: No File Logging

**Symptoms:**
- Diagnostic shows: `WARNING: No file logging found - errors are invisible!`
- Cannot debug what's happening when script runs

**Cause:**
- Generated scripts don't write to log files
- Only attempt Event Log (which fails if source not registered)

**Fix:**
Wait for updated script version with comprehensive file logging.

---

### Issue 4: Task Not Triggering

**Symptoms:**
- Diagnostic shows no task execution events
- Backup events (Event ID 14) exist but task doesn't run

**Cause:**
- Event trigger may be misconfigured
- Task may be disabled
- Event subscription query may be incorrect

**Fix:**
1. Check Task Scheduler manually
2. Look for "VLABS - WSBackup Notifications" task
3. Check History tab for trigger events
4. Verify task is "Ready" state
5. Run wizard again to recreate task

---

### Issue 5: Silent Exit Conditions

**Symptoms:**
- Task executes (shows in history) but no notification
- Exit code 0 (success) but nothing happened

**Cause:**
- Script exits silently if no recent Event 4 or Event 5 found
- Time windows (5-10 minutes) may be too short
- Event logs may be older than script expects

**Fix:**
Check generated script time windows:
```powershell
notepad "C:\ProgramData\VLABS\Notifications\WSBackup-Notification.ps1"
```

Look for:
```powershell
StartTime = (Get-Date).AddMinutes(-5)   # Event 14 window
StartTime = (Get-Date).AddMinutes(-10)  # Event 4/5 window
```

Consider expanding to `-30` minutes for testing.

---

### Issue 6: NotificationsServer Unreachable

**Symptoms:**
- Diagnostic shows: `Cannot reach server`
- Health check fails

**Cause:**
- Server not running
- Firewall blocking port 8089
- Wrong IP address configured

**Fix:**
1. Verify server is running: `docker ps` or check process
2. Test from Windows Server: `Invoke-RestMethod -Uri "http://[ServerIP]:8089/health"`
3. Check firewall rules
4. Verify IP address in registry: `HKLM:\SOFTWARE\VLABS\Notifications`

---

### Issue 7: Transport Names Mismatch

**Symptoms:**
- Diagnostic test notification succeeds
- Manual script execution sends notification
- But automated notifications don't arrive

**Cause:**
- Transport names in script don't match NotificationsServer configuration
- Scripts use: `SuccessfulBackups`, `FailedBackups`, `LowDiskSpace`
- Server may have different transport names

**Fix:**
Check NotificationsServer transport configuration:
```bash
# On NotificationsServer
cat transports.json
```

Verify these transports exist:
- `SuccessfulBackups`
- `FailedBackups`
- `LowDiskSpace`

---

## Manual Testing

### Test 1: Manual Task Trigger

```powershell
# Trigger the WSBackup task manually
$task = Get-ScheduledTask -TaskName "VLABS - WSBackup Notifications"
Start-ScheduledTask -InputObject $task

# Check result
Start-Sleep -Seconds 5
Get-ScheduledTaskInfo -TaskName "VLABS - WSBackup Notifications" | Select LastRunTime, LastTaskResult
```

### Test 2: Direct Script Execution

```powershell
# Run the generated script directly
& "C:\ProgramData\VLABS\Notifications\WSBackup-Notification.ps1"

# Check for output or errors
```

### Test 3: Direct API Call

```powershell
# Test NotificationsServer API directly
$serverIP = (Get-ItemProperty "HKLM:\SOFTWARE\VLABS\Notifications").NotificationsServerIP

$payload = @{
    type = "telegram"
    channels = @("SuccessfulBackups")
    subject = "Manual Test from PowerShell"
    body = "Testing direct API call from $env:COMPUTERNAME"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://${serverIP}:8089/api/v1/notify" -Method Post -Body $payload -ContentType "application/json"
```

If this works, the problem is in the generated script or task execution.

---

## Checking Task Scheduler History

1. Open Task Scheduler: `taskschd.msc`
2. Navigate to Task Scheduler Library
3. Find "VLABS - WSBackup Notifications"
4. Click "History" tab (enable if disabled)
5. Look for events:
   - Event ID 108: Task triggered by event
   - Event ID 100: Task started
   - Event ID 200: Action started
   - Event ID 201: Action completed
   - Event ID 102: Task completed successfully

If you see Event 108 but no 100, the task triggered but didn't start - likely PowerShell path issue.

---

## Viewing Backup Events

```powershell
# Recent backup events
Get-WinEvent -LogName Microsoft-Windows-Backup -MaxEvents 20 |
    Select TimeCreated, Id, LevelDisplayName, Message |
    Format-Table -AutoSize

# Filter for specific event IDs
Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Backup'
    ID = 14,5,4
    StartTime = (Get-Date).AddDays(-7)
} | Select TimeCreated, Id, Message
```

---

## Getting Help

If diagnostic doesn't identify the issue:

1. **Save diagnostic log:**
   ```
   C:\ProgramData\VLABS\Notifications\Logs\Diagnostic-*.log
   ```

2. **Export task configuration:**
   ```powershell
   Export-ScheduledTask -TaskName "VLABS - WSBackup Notifications" |
       Out-File "C:\Temp\task-config.xml"
   ```

3. **Copy generated script:**
   ```powershell
   Copy-Item "C:\ProgramData\VLABS\Notifications\WSBackup-Notification.ps1" `
             -Destination "C:\Temp\"
   ```

4. **Create GitHub issue** with:
   - Diagnostic log
   - Task configuration XML
   - Generated script
   - Description of issue

---

## Known Bugs (Being Fixed)

### v0.3.2 Known Issues:

1. **PowerShell.exe Relative Path** (HIGH)
   - Generated tasks use `PowerShell.exe` instead of full path
   - May cause silent execution failures
   - **Workaround:** Manual task XML editing (advanced)

2. **Event Log Source Not Registered** (HIGH)
   - Scripts attempt to log to Event Log using unregistered source "WSH"
   - Error logging fails silently
   - **Workaround:** None - errors are invisible

3. **No File-Based Logging** (CRITICAL)
   - Generated scripts have no file logging
   - Cannot debug execution issues
   - **Workaround:** Manually add logging to generated script

4. **Silent Exit Conditions** (MEDIUM)
   - Scripts exit without logging in several scenarios
   - Difficult to distinguish "didn't run" from "ran but found nothing"
   - **Workaround:** Check Task Scheduler history

These will be fixed in v0.4.0.

---

## Prevention

To avoid notification issues:

1. ✅ **Test after setup:**
   - Send test notification from wizard
   - Manually trigger task after creation
   - Verify Telegram message received

2. ✅ **Monitor Task Scheduler:**
   - Enable task history
   - Check for execution events after backups
   - Look for error codes

3. ✅ **Run diagnostic monthly:**
   - Ensures configuration still valid
   - Catches issues early

4. ✅ **Keep NotificationsServer updated:**
   - Check server logs
   - Verify transports configured
   - Test health endpoint

---

**Last Updated:** November 16, 2025
**Version:** 1.0.0
**For:** PowerShell Event Sender v0.3.2+
