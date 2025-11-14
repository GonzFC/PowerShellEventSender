# USAGE GUIDE - PowerShell Event Sender

Complete guide for using the VLABS Notifications Configuration Wizard.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [First-Time Configuration](#first-time-configuration)
4. [Managing Configurations](#managing-configurations)
5. [Understanding Event Triggers](#understanding-event-triggers)
6. [Testing and Verification](#testing-and-verification)
7. [Common Scenarios](#common-scenarios)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Components

**Windows Environment:**
- Windows Server 2012 R2 or later
- Windows 10/11 Pro (with Event Log support)
- PowerShell 5.1 or later

**NotificationsServer:**
- Running on your LAN
- Accessible from the Windows machine
- Configured with Telegram bot and channels

**Network:**
- Windows machine can reach NotificationsServer IP
- Port 8089 accessible (default)
- No firewall blocking HTTP requests

**Permissions:**
- Local Administrator rights
- Ability to create Scheduled Tasks
- Network access for SYSTEM account

### Checking Prerequisites

```powershell
# Check PowerShell version
$PSVersionTable.PSVersion

# Check if running as Administrator
([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Test NotificationsServer connectivity (replace with your IP)
Invoke-RestMethod -Uri "http://172.16.8.66:8089/health" -TimeoutSec 5
```

---

## Installation

### Step 1: Download the Script

1. Download `Setup-VLABSNotifications.ps1` to your Windows machine
2. Recommended location: `C:\Scripts\` or `C:\IT\`

### Step 2: Unblock the Script

Windows may block scripts downloaded from the internet:

```powershell
Unblock-File -Path "C:\Scripts\Setup-VLABSNotifications.ps1"
```

### Step 3: Verify Script Integrity

Check that the script is not corrupted:

```powershell
Get-Content "C:\Scripts\Setup-VLABSNotifications.ps1" | Select-Object -First 10
```

You should see the script header with copyright and version information.

---

## First-Time Configuration

### Running the Wizard

1. **Open PowerShell as Administrator:**
   - Right-click on PowerShell
   - Select "Run as Administrator"

2. **Navigate to the script:**
   ```powershell
   cd C:\Scripts
   ```

3. **Run the wizard:**
   ```powershell
   .\Setup-VLABSNotifications.ps1
   ```

### Initial Setup Walkthrough

**Step 1: Main Menu**
```
=============================================
   VLABS Notifications Configuration Wizard
=============================================

Choose an option:

  1. Notify Windows Server Backup Status

  0. Update Configuration and Exit

Enter choice:
```

**Step 2: Select Option 1**

Enter `1` to configure Windows Server Backup notifications.

**Step 3: Enter NotificationsServer IP**
```
=== Windows Server Backup Notifications ===

Enter NotificationsServer IP address: 172.16.8.66
```

Enter your Mac's IP address where NotificationsServer is running.

**Step 4: Connectivity Test**
```
[i] Testing connection to NotificationsServer...
[✓] NotificationsServer is reachable and healthy
```

If the server is not reachable, you'll be asked if you want to continue anyway.

**Step 5: Task Creation**
```
[i] Creating new scheduled task 'VLABS - WSBackup Notifications'...
[i] Notification script saved to: C:\ProgramData\VLABS\Notifications\WSBackup-Notification.ps1
[✓] Scheduled task 'VLABS - WSBackup Notifications' configured successfully
[i] Task will trigger on Event ID 14 from Microsoft-Windows-Backup log
```

**Step 6: Test Notification**
```
Send test notification to verify configuration? (Y/n): Y

[i] Sending test notification...
[✓] Test notification sent successfully to 'SuccessfulBackups' channel
```

Check your Telegram channel to verify you received the test notification.

**Step 7: Completion**
```
[✓] Windows Server Backup notifications enabled successfully!

The scheduled task will now monitor for Event ID 14 (Backup completed)
and automatically send notifications to your Telegram channels.

Press Enter to continue
```

---

## Managing Configurations

### Viewing Current Configuration

The wizard displays your current configuration at the top of the main menu:

```
Current NotificationsServer IP: 172.16.8.66

Choose an option:

  1. Notify Windows Server Backup Status [ENABLED]

  0. Update Configuration and Exit
```

### Updating Server IP Address

To change the NotificationsServer IP:

1. Run the wizard
2. Select option `0` (Update Configuration and Exit)
3. Enter new IP address or press Enter to keep current

**Example:**
```
=== Update Configuration ===

Current NotificationsServer IP: 172.16.8.66
Enter new IP address (or press Enter to keep current): 192.168.1.100

[i] Testing connection to new IP...
[✓] NotificationsServer is reachable and healthy
[i] Updating scheduled tasks with new IP...
[✓] Configuration updated successfully!
```

All enabled scheduled tasks will be automatically updated with the new IP.

### Reconfiguring Windows Server Backup Notifications

To update Windows Server Backup notification settings:

1. Run the wizard
2. Select option `1`
3. Confirm or change the server IP
4. The scheduled task will be updated

**Note:** The wizard is idempotent - running it multiple times is safe and will update existing tasks.

### Disabling Notifications

To disable Windows Server Backup notifications:

```powershell
# Remove the scheduled task
Unregister-ScheduledTask -TaskName "VLABS - WSBackup Notifications" -Confirm:$false

# Or use Task Scheduler GUI
# taskschd.msc → Find the task → Delete
```

---

## Understanding Event Triggers

### Windows Server Backup Events

The scheduled task monitors specific Windows Event Log events:

**Event ID 14 - Backup Operation Completed**
- **Log:** Microsoft-Windows-Backup
- **Source:** Microsoft-Windows-Backup
- **Meaning:** A backup operation has finished (success or failure)

**Event ID 4 - Backup Succeeded**
- **Log:** Microsoft-Windows-Backup
- **Source:** Microsoft-Windows-Backup
- **Meaning:** Backup completed successfully

### How the Logic Works

```
┌─────────────────────────────────────┐
│  Event ID 14 occurs                 │
│  (Backup operation completed)       │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Scheduled Task triggers             │
│  PowerShell script executes          │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Script checks for Event ID 4        │
│  (within last 10 minutes)            │
└──────────────┬──────────────────────┘
               │
       ┌───────┴────────┐
       │                │
       ▼                ▼
   Event 4          No Event 4
   Found            Found
       │                │
       ▼                ▼
  ┌─────────┐      ┌─────────┐
  │ Success │      │ Failure │
  └────┬────┘      └────┬────┘
       │                │
       ▼                ▼
   Send to          Send to
   "Successful      "Failed
    Backups"        Backups"
   Channel          Channel
```

### Viewing Events Manually

To check backup events manually:

```powershell
# View recent Event ID 14 (backup completed)
Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Backup'
    ID = 14
    StartTime = (Get-Date).AddDays(-7)
}

# View recent Event ID 4 (successful backup)
Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Backup'
    ID = 4
    StartTime = (Get-Date).AddDays(-7)
}

# View backup errors
Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Backup'
    Level = 2,3  # Error and Warning
    StartTime = (Get-Date).AddDays(-7)
}
```

---

## Testing and Verification

### Manual Task Execution

Test the scheduled task without waiting for an event:

```powershell
# Trigger the task manually
Start-ScheduledTask -TaskName "VLABS - WSBackup Notifications"

# Check task status
Get-ScheduledTask -TaskName "VLABS - WSBackup Notifications" | Select-Object State, LastRunTime, LastTaskResult

# View task history
Get-ScheduledTaskInfo -TaskName "VLABS - WSBackup Notifications"
```

**Note:** Manual execution may not work perfectly because the script expects a recent Event ID 14 to have occurred.

### Simulating a Backup Event

To fully test the workflow, perform an actual backup:

```powershell
# Using Windows Server Backup (if configured)
wbadmin start backup -backupTarget:E: -include:C: -allCritical -quiet

# Or trigger a scheduled backup
# This will generate real Event ID 14 and 4 events
```

### Verifying Task Creation

```powershell
# Check if task exists
Get-ScheduledTask -TaskName "VLABS - WSBackup Notifications"

# View task details
Get-ScheduledTask -TaskName "VLABS - WSBackup Notifications" | Format-List *

# Export task XML for inspection
Export-ScheduledTask -TaskName "VLABS - WSBackup Notifications" | Out-File -FilePath "C:\Temp\task-export.xml"
```

### Checking Notification Script

```powershell
# View the auto-generated script
Get-Content "C:\ProgramData\VLABS\Notifications\WSBackup-Notification.ps1"

# Test the script manually (requires recent Event 14)
& "C:\ProgramData\VLABS\Notifications\WSBackup-Notification.ps1"
```

### Verifying Registry Configuration

```powershell
# View stored configuration
Get-ItemProperty -Path "HKLM:\SOFTWARE\VLABS\Notifications"

# Output:
# NotificationsServerIP : 172.16.8.66
# WSBackupEnabled       : 1
```

---

## Common Scenarios

### Scenario 1: Successful Backup

**Timeline:**
1. Windows Server Backup runs at 2:00 AM
2. Backup completes successfully at 2:15 AM
3. Event ID 14 is logged (backup completed)
4. Event ID 4 is logged (backup successful)
5. Scheduled task triggers on Event ID 14
6. Script detects Event ID 4 (success)
7. Notification sent to "SuccessfulBackups" channel

**Telegram Message:**
```
✅ Backup Successful - WSSERVER

Windows Server Backup completed successfully

Server: WSSERVER
Time: 2025-11-14 02:15:32
Status: Success

Details:
The backup operation to E:\Backups\ completed successfully.
```

### Scenario 2: Failed Backup

**Timeline:**
1. Windows Server Backup runs at 2:00 AM
2. Backup fails at 2:05 AM (disk full, network error, etc.)
3. Event ID 14 is logged (backup completed)
4. No Event ID 4 (no success event)
5. Error events logged (Level 2 or 3)
6. Scheduled task triggers on Event ID 14
7. Script detects NO Event ID 4 (failure)
8. Script collects error event details
9. Notification sent to "FailedBackups" channel

**Telegram Message:**
```
❌ Backup Failed - WSSERVER

Windows Server Backup failed

Server: WSSERVER
Time: 2025-11-14 02:05:18
Status: Failed

Error Details:
02:05:15 - The backup operation stopped before completing.
02:05:16 - The backup disk is full. Free up space and retry.
```

### Scenario 3: Multiple Windows Servers

If you manage multiple Windows servers:

1. **Run wizard on each server**
2. **Use the same NotificationsServer IP**
3. **Each server will have its own scheduled task**
4. **Notifications will identify the server by hostname**

All servers will send to the same Telegram channels, but each message will include `$env:COMPUTERNAME` so you know which server sent it.

**Example Messages:**
```
✅ Backup Successful - DC01
✅ Backup Successful - FILESERVER
❌ Backup Failed - SQLSERVER
```

---

## Troubleshooting

### Task Not Triggering

**Problem:** Scheduled task doesn't run when backup completes.

**Diagnosis:**
```powershell
# Check task state
Get-ScheduledTask -TaskName "VLABS - WSBackup Notifications" | Select-Object State

# View task history in Task Scheduler
taskschd.msc
# Navigate to: Task Scheduler Library → Find task → History tab
```

**Solutions:**
1. **Enable Task History:**
   - Open Task Scheduler
   - Click "Enable All Tasks History" in right panel

2. **Verify Event Trigger:**
   ```powershell
   Export-ScheduledTask -TaskName "VLABS - WSBackup Notifications" | Select-String -Pattern "EventID"
   ```
   Should show: `<Select Path="Microsoft-Windows-Backup">*[System[(EventID=14)]]</Select>`

3. **Check Event Log:**
   ```powershell
   # Verify Event 14 is actually being logged
   Get-WinEvent -FilterHashtable @{
       LogName = 'Microsoft-Windows-Backup'
       ID = 14
       StartTime = (Get-Date).AddHours(-1)
   }
   ```

### Notification Not Received

**Problem:** Task runs but no Telegram notification received.

**Diagnosis:**
```powershell
# Check last run result
Get-ScheduledTaskInfo -TaskName "VLABS - WSBackup Notifications" | Select-Object LastTaskResult

# View Application Event Log for errors
Get-WinEvent -FilterHashtable @{
    LogName = 'Application'
    ProviderName = 'WSH'
    StartTime = (Get-Date).AddHours(-1)
} -ErrorAction SilentlyContinue
```

**Solutions:**

1. **Test Server Connectivity:**
   ```powershell
   Invoke-RestMethod -Uri "http://172.16.8.66:8089/health"
   ```

2. **Send Manual Test:**
   ```powershell
   Invoke-RestMethod -Uri "http://172.16.8.66:8089/api/v1/notify" `
       -Method Post -ContentType "application/json" `
       -Body (@{type="telegram";channels=@("SuccessfulBackups");subject="Test";body="Manual test"} | ConvertTo-Json)
   ```

3. **Check Firewall:**
   ```powershell
   # Allow outbound HTTP from PowerShell
   New-NetFirewallRule -DisplayName "VLABS Notifications" -Direction Outbound -Action Allow -Protocol TCP -RemotePort 8089
   ```

4. **Verify Channels Exist:**
   - Check NotificationsServer catalog.yaml
   - Ensure "SuccessfulBackups" and "FailedBackups" channels are defined
   - Verify bots are added as admins to channels

### Script Execution Errors

**Problem:** PowerShell script has syntax or runtime errors.

**Diagnosis:**
```powershell
# Test script manually
& "C:\ProgramData\VLABS\Notifications\WSBackup-Notification.ps1"

# Check execution policy
Get-ExecutionPolicy

# View script content for syntax issues
Get-Content "C:\ProgramData\VLABS\Notifications\WSBackup-Notification.ps1"
```

**Solutions:**

1. **Fix Execution Policy:**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
   ```
   Note: The task uses `-ExecutionPolicy Bypass` by default

2. **Recreate Script:**
   - Run the wizard again
   - It will regenerate the script with correct syntax

3. **Check Event Data:**
   ```powershell
   # Ensure events exist for the script to process
   Get-WinEvent -FilterHashtable @{
       LogName = 'Microsoft-Windows-Backup'
       ID = 14
       StartTime = (Get-Date).AddMinutes(-10)
   }
   ```

### Registry Configuration Issues

**Problem:** Configuration not saving or loading correctly.

**Diagnosis:**
```powershell
# Check registry path
Test-Path "HKLM:\SOFTWARE\VLABS\Notifications"

# View current values
Get-ItemProperty -Path "HKLM:\SOFTWARE\VLABS\Notifications"
```

**Solutions:**

1. **Recreate Registry Key:**
   ```powershell
   # Remove and recreate
   Remove-Item -Path "HKLM:\SOFTWARE\VLABS\Notifications" -Recurse -Force

   # Run wizard again
   .\Setup-VLABSNotifications.ps1
   ```

2. **Manually Set Values:**
   ```powershell
   New-Item -Path "HKLM:\SOFTWARE\VLABS\Notifications" -Force
   Set-ItemProperty -Path "HKLM:\SOFTWARE\VLABS\Notifications" -Name "NotificationsServerIP" -Value "172.16.8.66"
   Set-ItemProperty -Path "HKLM:\SOFTWARE\VLABS\Notifications" -Name "WSBackupEnabled" -Value 1
   ```

### SYSTEM Account Network Access

**Problem:** Scheduled task runs as SYSTEM, which may not have network access.

**Diagnosis:**
```powershell
# Run test as SYSTEM using PsExec (Sysinternals)
psexec -s -i powershell.exe
# Then test from that session:
Invoke-RestMethod -Uri "http://172.16.8.66:8089/health"
```

**Solutions:**

1. **Enable Network Access for SYSTEM:**
   - Usually works by default on workgroup or domain-joined machines
   - Ensure proxy settings don't block SYSTEM

2. **Change Task User:**
   ```powershell
   # Use Task Scheduler GUI to change user to a service account
   # or create a dedicated user for notifications
   ```

---

## Advanced Usage

### Custom Event Triggers

To add monitoring for other events, modify the script to create additional tasks with different event triggers.

### Multiple Notification Servers

If you have multiple NotificationsServers (dev, prod, etc.), you can:
- Run the wizard multiple times with different IPs
- Manually edit the generated script to choose server based on conditions

### Logging and Debugging

Enable detailed logging in the notification script:

```powershell
# Edit: C:\ProgramData\VLABS\Notifications\WSBackup-Notification.ps1
# Add at the top:
Start-Transcript -Path "C:\Logs\VLABS-Notifications.log" -Append

# Add at the end:
Stop-Transcript
```

---

## Best Practices

1. **Test After Setup:** Always send a test notification after configuring
2. **Monitor Task History:** Periodically check Task Scheduler history
3. **Keep Server IP Updated:** If NotificationsServer IP changes, update immediately
4. **Backup Configuration:** Export scheduled tasks before making changes
5. **Document Changes:** Keep notes on when you run the wizard
6. **Regular Testing:** Manually trigger tasks monthly to verify they still work

---

## Next Steps

- Read [ARCHITECTURE.md](ARCHITECTURE.md) for technical details
- Review [PowerShell-Integration.md](../Integration%20Documentation/PowerShell-Integration.md) for API reference
- Check parent [README.md](../README.md) for NotificationsServer documentation

---

**Last Updated:** November 14, 2025
