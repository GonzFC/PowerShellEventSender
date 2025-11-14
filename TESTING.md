# Testing Guide

Quick guide to test the PowerShell Event Sender before deployment.

---

## Pre-Deployment Testing

### 1. Syntax Validation

Before running the wizard, verify the PowerShell script syntax:

```powershell
# Test syntax (no admin required)
.\Test-Syntax.ps1
```

**Expected output:**
```
Testing PowerShell syntax...

✓ Syntax check PASSED

The script is syntactically valid and ready to use.

Next steps:
  1. Run PowerShell as Administrator
  2. Execute: .\Setup-VLABSNotifications.ps1
```

If this test fails, please report the issue with the error details.

---

### 2. NotificationsServer Connectivity

Verify you can reach the NotificationsServer from your Windows machine:

```powershell
# Replace with your NotificationsServer IP
$ServerIP = "172.16.8.66"

# Test health endpoint
Invoke-RestMethod -Uri "http://${ServerIP}:8089/health" -TimeoutSec 5
```

**Expected output:**
```
status
------
healthy
```

---

### 3. Test Notification (Manual)

Send a test notification without running the wizard:

```powershell
$ServerIP = "172.16.8.66"

$body = @{
    type = "telegram"
    channels = @("SuccessfulBackups")
    subject = "Test from Windows"
    body = "Manual test notification`n`nServer: $env:COMPUTERNAME`nTime: $(Get-Date)"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://${ServerIP}:8089/api/v1/notify" `
    -Method Post `
    -Body $body `
    -ContentType "application/json"
```

Check your Telegram channel for the test message.

---

## Post-Configuration Testing

After running the wizard:

### 1. Verify Registry Configuration

```powershell
Get-ItemProperty -Path "HKLM:\SOFTWARE\VLABS\Notifications"
```

**Expected output:**
```
NotificationsServerIP : 172.16.8.66
WSBackupEnabled       : 1
```

---

### 2. Verify Scheduled Task

```powershell
# Check task exists
Get-ScheduledTask -TaskName "VLABS - WSBackup Notifications"

# Check task details
Get-ScheduledTask -TaskName "VLABS - WSBackup Notifications" | Format-List *
```

**Key properties to verify:**
- State: Ready
- TaskName: VLABS - WSBackup Notifications
- Triggers: Event-based (Event ID 14)

---

### 3. Verify Generated Script

```powershell
# View the generated notification script
Get-Content "C:\ProgramData\VLABS\Notifications\WSBackup-Notification.ps1"
```

**Verify:**
- Server IP is correct
- Port is 8089
- No syntax errors
- Emojis are present (✅ and ❌)

---

### 4. Manual Task Trigger

Test the scheduled task manually:

```powershell
# Start the task
Start-ScheduledTask -TaskName "VLABS - WSBackup Notifications"

# Check last run status
Get-ScheduledTaskInfo -TaskName "VLABS - WSBackup Notifications" | Select-Object LastRunTime, LastTaskResult
```

**Note:** Manual execution may not send notifications if there's no recent Event ID 14 in the log.

---

### 5. View Task History

Check execution history in Task Scheduler GUI:

1. Open Task Scheduler: `taskschd.msc`
2. Navigate to: Task Scheduler Library
3. Find: "VLABS - WSBackup Notifications"
4. Click: History tab
5. Enable history if disabled: Action → Enable All Tasks History

---

## End-to-End Testing

### Windows Server Backup Test

The complete test requires a Windows Server Backup operation:

**Option 1: Scheduled Backup**

Wait for your next scheduled backup to complete and verify:
1. Backup completes
2. Event ID 14 is logged
3. Scheduled task triggers
4. Notification received in Telegram

**Option 2: Manual Backup**

```powershell
# Example: Run a manual backup (adjust parameters for your environment)
wbadmin start backup -backupTarget:E: -include:C:\ImportantData -allCritical -quiet
```

Then check:
1. Event Viewer for Event ID 14 and 4
2. Task Scheduler history
3. Telegram channel for notification

---

## Event Log Verification

### Check for Backup Events

```powershell
# View recent Event ID 14 (Backup completed)
Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Backup'
    ID = 14
    StartTime = (Get-Date).AddHours(-24)
}

# View recent Event ID 4 (Successful backup)
Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Backup'
    ID = 4
    StartTime = (Get-Date).AddHours(-24)
}

# View backup errors
Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Backup'
    Level = 2,3  # Error and Warning
    StartTime = (Get-Date).AddHours(-24)
}
```

---

## Simulating Events (Advanced)

To test without waiting for a real backup, you can create test events:

**⚠️ WARNING:** This creates fake events in your event log. Use only in test environments.

```powershell
# This requires creating a custom event source
# Not recommended for production - use real backups instead
```

For testing, it's better to:
1. Use the wizard's built-in test notification feature
2. Run an actual backup operation
3. Check existing backup events in the log

---

## Troubleshooting Tests

### Test Network from SYSTEM Account

The scheduled task runs as SYSTEM. Test network access as SYSTEM:

```powershell
# Using PsExec (Sysinternals)
# Download from: https://docs.microsoft.com/sysinternals/downloads/psexec

psexec -s -i powershell.exe

# In the SYSTEM PowerShell session, test connectivity:
Invoke-RestMethod -Uri "http://172.16.8.66:8089/health"
```

---

### View Application Event Log

Check for notification errors:

```powershell
Get-WinEvent -FilterHashtable @{
    LogName = 'Application'
    ProviderName = 'WSH'
    StartTime = (Get-Date).AddHours(-1)
} -ErrorAction SilentlyContinue
```

---

### Export Task for Inspection

Export task definition to XML for detailed inspection:

```powershell
Export-ScheduledTask -TaskName "VLABS - WSBackup Notifications" | Out-File "C:\Temp\task-export.xml"

# View the XML
notepad "C:\Temp\task-export.xml"
```

Check for:
- EventTrigger element
- Subscription query for Event ID 14
- Correct PowerShell execution command

---

## Test Checklist

Before deploying to production, verify:

- [ ] Syntax test passes (`Test-Syntax.ps1`)
- [ ] NotificationsServer is reachable
- [ ] Manual test notification received in Telegram
- [ ] Registry configuration saved correctly
- [ ] Scheduled task created successfully
- [ ] Generated script has correct IP and port
- [ ] Task history logging enabled
- [ ] Test notification from wizard works
- [ ] (Optional) End-to-end test with actual backup

---

## Getting Help

If tests fail:

1. Check [USAGE.md](USAGE.md) troubleshooting section
2. Review [ARCHITECTURE.md](ARCHITECTURE.md) for technical details
3. Check NotificationsServer logs: `~/NotificationsServer/logs/current.log`
4. Verify Telegram bot is added as admin to channels

---

**Last Updated:** November 14, 2025
