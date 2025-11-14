# ARCHITECTURE - PowerShell Event Sender

Technical architecture and implementation details for the VLABS PowerShell Event Sender system.

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Component Architecture](#component-architecture)
3. [Data Flow](#data-flow)
4. [Windows Scheduled Tasks](#windows-scheduled-tasks)
5. [Event Trigger Mechanism](#event-trigger-mechanism)
6. [Configuration Storage](#configuration-storage)
7. [Script Generation](#script-generation)
8. [Integration with NotificationsServer](#integration-with-notificationsserver)
9. [Security Model](#security-model)
10. [Extending the System](#extending-the-system)

---

## System Overview

### Purpose

The PowerShell Event Sender bridges Windows Event Log events with Telegram notifications via the NotificationsServer. It enables automated, real-time monitoring and alerting for Windows system events.

### Design Principles

1. **Idempotency** - Safe to run configuration wizard multiple times
2. **Simplicity** - User-friendly wizard interface, minimal manual configuration
3. **Reliability** - Event-driven architecture ensures notifications aren't missed
4. **Maintainability** - Clear separation of configuration, generation, and execution
5. **Extensibility** - Easy to add new event types and notification scenarios

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Windows Server/Client                     │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Setup-VLABSNotifications.ps1 (Wizard)             │    │
│  │  • Interactive configuration                        │    │
│  │  • Registry management                              │    │
│  │  • Scheduled task creation                          │    │
│  │  • Script generation                                │    │
│  └─────────────────┬──────────────────────────────────┘    │
│                    │                                         │
│                    ▼                                         │
│  ┌────────────────────────────────────────────────────┐    │
│  │  HKLM:\SOFTWARE\VLABS\Notifications (Registry)     │    │
│  │  • NotificationsServerIP: "172.16.8.66"            │    │
│  │  • WSBackupEnabled: 1                              │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Windows Scheduled Tasks                           │    │
│  │  • VLABS - WSBackup Notifications                  │    │
│  │    - Trigger: Event ID 14                          │    │
│  │    - Action: Execute PowerShell script             │    │
│  └─────────────────┬──────────────────────────────────┘    │
│                    │                                         │
│                    ▼                                         │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Generated Scripts (C:\ProgramData\VLABS\...)      │    │
│  │  • WSBackup-Notification.ps1                       │    │
│  │    - Event log query                               │    │
│  │    - Status determination                          │    │
│  │    - REST API call                                 │    │
│  └─────────────────┬──────────────────────────────────┘    │
│                    │                                         │
└────────────────────┼─────────────────────────────────────────┘
                     │
                     │ HTTP POST
                     │ http://172.16.8.66:8089/api/v1/notify
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                NotificationsServer (macOS)                   │
│  • Receives REST API call                                   │
│  • Resolves transport to bot + channel                      │
│  • Sends message via Telegram Bot API                       │
└─────────────────────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    Telegram Transports                       │
│  • SuccessfulBackups (transport = bot + channel)            │
│  • FailedBackups (transport = bot + channel)                │
└─────────────────────────────────────────────────────────────┘
```

---

## Component Architecture

### 1. Setup-VLABSNotifications.ps1 (Wizard)

**Purpose:** Interactive configuration and management tool.

**Responsibilities:**
- User interaction and menu display
- Configuration validation
- Registry read/write
- Scheduled task creation/update
- PowerShell script generation
- Testing and verification

**Key Functions:**

| Function | Purpose |
|----------|---------|
| `Initialize-Configuration` | Load config from registry |
| `Save-Configuration` | Persist config to registry |
| `Test-NotificationsServer` | Verify server connectivity |
| `Send-TestNotification` | Test end-to-end workflow |
| `New-WSBackupNotificationTask` | Create/update scheduled task |
| `Show-MainMenu` | Display interactive menu |
| `Invoke-WSBackupConfiguration` | Configure backup monitoring |

**Code Structure:**
```powershell
# Configuration section
$Script:RegistryPath = "HKLM:\SOFTWARE\VLABS\Notifications"
$Script:Config = @{}

# Helper functions (initialization, testing, etc.)
function Initialize-Configuration { }
function Save-Configuration { }
function Test-NotificationsServer { }
function Send-TestNotification { }

# Scheduled task functions
function New-WSBackupNotificationTask { }
function Remove-WSBackupNotificationTask { }

# Menu functions
function Show-MainMenu { }
function Invoke-WSBackupConfiguration { }

# Main program
function Main { }
Main
```

### 2. Generated Notification Scripts

**Purpose:** Event-driven scripts executed by scheduled tasks.

**Location:** `C:\ProgramData\VLABS\Notifications\`

**Example:** `WSBackup-Notification.ps1`

**Responsibilities:**
- Query Windows Event Log for triggering event
- Determine event status (success/failure)
- Collect relevant event details
- Format notification message
- Send REST API request to NotificationsServer
- Error logging

**Script Structure:**
```powershell
# Configuration (injected by wizard)
$ServerIP = "172.16.8.66"
$ServerPort = 8089
$NotifyUri = "http://${ServerIP}:${ServerPort}/api/v1/notify"

# Event retrieval
$events = Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Backup'
    ID = 14
    StartTime = (Get-Date).AddMinutes(-5)
}

# Status determination
$successEvent = Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Backup'
    ID = 4
    StartTime = (Get-Date).AddMinutes(-10)
}

# Notification payload creation
if ($successEvent) {
    # Success path
} else {
    # Failure path
}

# API call
Invoke-RestMethod -Uri $NotifyUri -Method Post -Body $payload -ContentType "application/json"
```

### 3. Windows Scheduled Tasks

**Purpose:** Event-driven automation engine.

**Task Properties:**

| Property | Value |
|----------|-------|
| Name | `VLABS - WSBackup Notifications` |
| Trigger | Event-based (Event ID 14 and 5 from Microsoft-Windows-Backup) |
| Action | Execute PowerShell script |
| User | SYSTEM |
| Run Level | Highest |
| Settings | Allow start on batteries, start when available |

**Event IDs Monitored:**
- **Event ID 14**: Backup operation completed (may be success or failure)
- **Event ID 5**: Backup failed (immediate failure notification)

**XML Structure:**
```xml
<Task>
  <Triggers>
    <EventTrigger>
      <Enabled>true</Enabled>
      <Subscription>
        <QueryList>
          <Query Id="0" Path="Microsoft-Windows-Backup">
            <Select Path="Microsoft-Windows-Backup">
              *[System[(EventID=14 or EventID=5)]]
            </Select>
          </Query>
        </QueryList>
      </Subscription>
    </EventTrigger>
  </Triggers>
  <Actions>
    <Exec>
      <Command>PowerShell.exe</Command>
      <Arguments>-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\ProgramData\VLABS\Notifications\WSBackup-Notification.ps1"</Arguments>
    </Exec>
  </Actions>
  <Principals>
    <Principal>
      <UserId>S-1-5-18</UserId> <!-- SYSTEM -->
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
</Task>
```

---

## Data Flow

### Complete Event-to-Notification Flow

```
┌──────────────────────────────────────────────────────────────┐
│ 1. Windows Event Occurs                                      │
│    • Windows Server Backup completes                         │
│    • Event ID 14 logged to Microsoft-Windows-Backup          │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│ 2. Task Scheduler Detects Event                              │
│    • Event subscription matches (ID=14)                       │
│    • Scheduled task "VLABS - WSBackup Notifications" triggered│
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│ 3. PowerShell Script Executes                                │
│    • Script: WSBackup-Notification.ps1                       │
│    • User: SYSTEM                                            │
│    • Privileges: Elevated                                    │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│ 4. Event Log Query                                           │
│    • Query for Event ID 14 (last 5 minutes)                  │
│    • Query for Event ID 4 - Success (last 10 minutes)        │
│    • Query for Event ID 5 - Failure (last 10 minutes)        │
│    • Query for additional error events (if Event 5 found)    │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│ 5. Status Determination                                      │
│    ┌────────────────────────────┐                            │
│    │ Event ID 4 found?          │                            │
│    └─────┬───────────────┬──────┘                            │
│          │ YES           │ NO                                │
│          ▼               ▼                                    │
│    ┌─────────┐    ┌──────────────────┐                      │
│    │ Success │    │ Event ID 5 found?│                      │
│    └─────┬───┘    └─────┬──────┬─────┘                      │
│          │              │ YES  │ NO                          │
│          │              ▼      ▼                             │
│          │         ┌─────────┐ Exit                          │
│          │         │ Failure │ (Inconclusive)                │
│          │         └─────┬───┘                               │
│          │               │                                   │
│          ▼               ▼                                   │
│    Transport:       Transport:                               │
│    SuccessfulBackups   FailedBackups                        │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│ 6. Notification Payload Creation                             │
│    {                                                         │
│      "type": "telegram",                                     │
│      "channels": ["SuccessfulBackups"],  # References transport
│      "subject": "✅ Backup Successful - WSSERVER",           │
│      "body": "Windows Server Backup completed..."            │
│    }                                                         │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│ 7. REST API Call                                             │
│    POST http://172.16.8.66:8089/api/v1/notify               │
│    Content-Type: application/json                            │
│    Body: {notification payload}                              │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│ 8. NotificationsServer Processing                            │
│    • Validates request                                       │
│    • Resolves transport to bot + channel                     │
│    • Calls Telegram Bot API with resolved credentials        │
│    • Returns response                                        │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│ 9. Telegram Delivery                                         │
│    • Bot sends message to channel                            │
│    • User receives notification on mobile/desktop            │
└──────────────────────────────────────────────────────────────┘
```

---

## Windows Scheduled Tasks

### Event Trigger Subscription

Event triggers use XPath queries to filter events:

**Query Structure:**
```xml
<QueryList>
  <Query Id="0" Path="Microsoft-Windows-Backup">
    <Select Path="Microsoft-Windows-Backup">
      *[System[(EventID=14)]]
    </Select>
  </Query>
</QueryList>
```

**XPath Breakdown:**
- `Path`: Event log name
- `EventID`: The event ID to trigger on
- `*[System[...]]`: Match any event with specific system properties

### Advanced Event Filters

For more complex scenarios, you can filter by multiple criteria:

**Example: Specific Event Level**
```xml
*[System[(EventID=14) and (Level=2)]]
```

**Example: Event Source**
```xml
*[System[(EventID=14) and (Provider[@Name='Microsoft-Windows-Backup'])]]
```

**Example: Time Window**
```xml
*[System[(EventID=14) and TimeCreated[timediff(@SystemTime) &lt;= 300000]]]
```
(Triggers within 5 minutes of event)

### Task Creation Process

1. **Create Basic Task:**
   ```powershell
   $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "..."
   $trigger = New-ScheduledTaskTrigger -AtStartup  # Placeholder
   $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
   $settings = New-ScheduledTaskSettingsSet ...
   Register-ScheduledTask -TaskName "..." -Action $action -Trigger $trigger -Principal $principal -Settings $settings
   ```

2. **Export Task XML:**
   ```powershell
   $taskXml = [xml](Export-ScheduledTask -TaskName "...")
   ```

3. **Modify XML (Add Event Trigger):**
   ```powershell
   $eventTrigger = $taskXml.CreateElement("EventTrigger", $taskXml.Task.NamespaceURI)
   # Add Subscription, Enabled, etc.
   $taskXml.Task.Triggers.AppendChild($eventTrigger)
   ```

4. **Re-register Task:**
   ```powershell
   Unregister-ScheduledTask -TaskName "..." -Confirm:$false
   Register-ScheduledTask -TaskName "..." -Xml $taskXml.OuterXml
   ```

This approach is necessary because `New-ScheduledTaskTrigger` doesn't support event-based triggers directly in PowerShell.

---

## Event Trigger Mechanism

### Windows Event Log Structure

**Relevant Event IDs for Windows Server Backup:**

| Event ID | Level | Description | When It Occurs |
|----------|-------|-------------|----------------|
| 4 | Information | Backup succeeded | Backup completes successfully |
| 5 | Information | Backup failed | Backup fails (general failure) |
| 8 | Warning | Volume not included | Some volumes weren't backed up |
| 14 | Information | Backup operation completed | Any backup finishes (success or failure) |
| 49 | Error | Backup stopped | Backup was manually stopped or crashed |
| 517 | Error | Backup deletion failed | Failed to delete old backup |

**Key Insight:** Event ID 14 is logged for BOTH successful and failed backups. We must check for Event ID 4 to determine success.

### Event Query Logic

**Primary Query (in scheduled task trigger):**
```powershell
Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Backup'
    ID = 14
    StartTime = (Get-Date).AddMinutes(-5)
}
```

**Success Verification Query (in notification script):**
```powershell
$successEvent = Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Backup'
    ID = 4
    StartTime = (Get-Date).AddMinutes(-10)
}
```

**Error Collection Query (in notification script):**
```powershell
$errorEvents = Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Backup'
    Level = 2,3  # Error (2) and Warning (3)
    StartTime = (Get-Date).AddMinutes(-10)
} -MaxEvents 5
```

### Time Windows

- **Event ID 14 Query:** Last 5 minutes (must be recent)
- **Event ID 4 Query:** Last 10 minutes (allows for slight timing differences)
- **Error Query:** Last 10 minutes (collect context)

These windows ensure we capture the relevant events even if there's a slight delay between Event 14 and Event 4 being logged.

---

## Configuration Storage

### Registry Structure

**Path:** `HKLM:\SOFTWARE\VLABS\Notifications`

**Schema:**

| Value Name | Type | Description | Example |
|------------|------|-------------|---------|
| `NotificationsServerIP` | REG_SZ (String) | IP address of NotificationsServer | `172.16.8.66` |
| `WSBackupEnabled` | REG_DWORD (Integer) | Whether backup monitoring is enabled | `1` (enabled), `0` (disabled) |

**Why Registry?**
- Persistent across reboots
- Centralized configuration location
- Standard Windows practice
- Easy to query from PowerShell
- Supports future expansion

**Access Control:**
- Located in `HKLM` (Local Machine)
- Requires Administrator to write
- Readable by all users
- SYSTEM account has full access

### Configuration Read/Write

**Read Configuration:**
```powershell
$config = Get-ItemProperty -Path "HKLM:\SOFTWARE\VLABS\Notifications" -ErrorAction SilentlyContinue

if ($config) {
    $serverIP = $config.NotificationsServerIP
    $wsBackupEnabled = [bool]$config.WSBackupEnabled
}
```

**Write Configuration:**
```powershell
# Ensure path exists
if (-not (Test-Path "HKLM:\SOFTWARE\VLABS\Notifications")) {
    New-Item -Path "HKLM:\SOFTWARE\VLABS\Notifications" -Force
}

# Set values
Set-ItemProperty -Path "HKLM:\SOFTWARE\VLABS\Notifications" -Name "NotificationsServerIP" -Value "172.16.8.66" -Type String
Set-ItemProperty -Path "HKLM:\SOFTWARE\VLABS\Notifications" -Name "WSBackupEnabled" -Value 1 -Type DWord
```

---

## Script Generation

### Dynamic Script Creation

The wizard generates PowerShell scripts dynamically to include current configuration:

**Template Approach:**
```powershell
$scriptBlock = @"
# Auto-generated script
`$ServerIP = "$ServerIP"
`$ServerPort = $Script:NotificationsServerPort

# Script logic...
"@

$scriptBlock | Out-File -FilePath $scriptPath -Encoding UTF8 -Force
```

**Variable Injection:**
- `$ServerIP`: Injected from configuration
- `$ServerPort`: Injected from wizard constant
- Script logic: Static template

**Benefits:**
- Configuration embedded in script (self-contained)
- No runtime dependencies on registry for script execution
- Easy to update by regenerating script

**Location:** `C:\ProgramData\VLABS\Notifications\`

**Naming Convention:**
- `WSBackup-Notification.ps1` - Windows Server Backup
- Future: `ServiceStatus-Notification.ps1`, `DiskSpace-Notification.ps1`, etc.

---

## Integration with NotificationsServer

### API Communication

**Endpoint:** `POST /api/v1/notify`

**Request Format:**
```json
{
  "type": "telegram",
  "channels": ["SuccessfulBackups"],
  "subject": "✅ Backup Successful - WSSERVER",
  "body": "Windows Server Backup completed successfully\n\nServer: WSSERVER\nTime: 2025-11-14 02:15:32\nStatus: Success"
}
```

**PowerShell Implementation:**
```powershell
$payload = @{
    type = "telegram"
    channels = @("SuccessfulBackups")
    subject = "✅ Backup Successful - $env:COMPUTERNAME"
    body = $bodyText
} | ConvertTo-Json -Depth 3

Invoke-RestMethod -Uri "http://${ServerIP}:${ServerPort}/api/v1/notify" `
    -Method Post `
    -Body $payload `
    -ContentType "application/json" `
    -TimeoutSec 10 `
    -ErrorAction Stop
```

### Error Handling

**Network Errors:**
```powershell
try {
    Invoke-RestMethod -Uri $NotifyUri -Method Post -Body $payload -ContentType "application/json" -TimeoutSec 10 -ErrorAction Stop
} catch {
    # Log to Windows Event Log
    Write-EventLog -LogName Application -Source "WSH" -EventId 1001 -EntryType Error -Message "Failed to send notification: $($_.Exception.Message)"
}
```

**Why Silent Failure?**
- Notification failures shouldn't affect system operations
- Logged to Event Log for diagnostics
- Task Scheduler shows last run result

### Response Handling

**Successful Response Example:**
```
STATUS: SUCCESS
ID: 20251114-021532-a1b2c3d4
TYPE: telegram
RECIPIENTS: -1003351266067
SENT_AT: 2025-11-14T02:15:33 CST
```

**Note:** Response is currently ignored (fire-and-forget), but could be logged for auditing.

---

## Security Model

### Trust Boundaries

```
┌─────────────────────────────────────┐
│ Windows Machine (Trusted Zone)      │
│ • Administrator configures          │
│ • SYSTEM executes tasks             │
│ • Scripts run with elevated privs   │
└──────────────┬──────────────────────┘
               │
               │ Trusted LAN
               │ (No authentication)
               │
               ▼
┌─────────────────────────────────────┐
│ NotificationsServer (Trusted Zone)  │
│ • LAN-only access                   │
│ • No authentication required        │
│ • Telegram API credentials stored   │
└─────────────────────────────────────┘
```

### Security Assumptions

1. **Trusted LAN:** Network is secure, no malicious actors
2. **Physical Security:** Servers are physically secured
3. **Administrator Trust:** Admins who configure are trusted
4. **SYSTEM Account:** Safe to run as SYSTEM (standard practice)

### Security Considerations

**Sensitive Data:**
- ✅ **No credentials in scripts:** Server IP only
- ✅ **No Telegram tokens on Windows:** Stored on NotificationsServer
- ⚠️ **Event data may be sensitive:** Backup paths, server names
- ⚠️ **Registry readable by all users:** IP address is visible

**Network Security:**
- ⚠️ **HTTP, not HTTPS:** Unencrypted traffic (LAN-only assumed safe)
- ⚠️ **No API authentication:** Anyone on LAN can send notifications
- ✅ **Firewall recommended:** Restrict NotificationsServer access to known IPs

**Privilege Escalation:**
- ✅ **SYSTEM account necessary:** Required for Event Log access
- ✅ **Script path protected:** C:\ProgramData requires Admin to modify
- ⚠️ **Code injection risk:** If script path is writable by non-admins

### Hardening Recommendations

**For Production Environments:**

1. **Network Isolation:**
   ```powershell
   # Allow only specific IPs to reach NotificationsServer
   New-NetFirewallRule -DisplayName "VLABS Notifications - Outbound" `
       -Direction Outbound -Action Allow -Protocol TCP -RemotePort 8089 `
       -RemoteAddress 172.16.8.66
   ```

2. **Script Path Permissions:**
   ```powershell
   # Ensure only Administrators can modify scripts
   $acl = Get-Acl "C:\ProgramData\VLABS\Notifications"
   $acl.SetAccessRuleProtection($true, $false)
   $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
   $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
   $acl.SetAccessRule($adminRule)
   $acl.SetAccessRule($systemRule)
   Set-Acl "C:\ProgramData\VLABS\Notifications" $acl
   ```

3. **HTTPS Support:**
   - Add HTTPS support to NotificationsServer
   - Update scripts to use `https://` URLs
   - Implement certificate validation

4. **API Authentication:**
   - Add API key to NotificationsServer
   - Store API key in Windows Credential Manager
   - Retrieve in script and include in requests

---

## Extending the System

### Adding New Event Types

**Example: Service Status Monitoring**

1. **Add Menu Option:**
   ```powershell
   function Show-MainMenu {
       Write-Host "  2. Notify Service Status Changes" -ForegroundColor White
   }
   ```

2. **Create Configuration Function:**
   ```powershell
   function Invoke-ServiceStatusConfiguration {
       # Prompt for service name
       $serviceName = Read-Host "Enter service name to monitor"

       # Create scheduled task
       New-ServiceStatusNotificationTask -ServerIP $Script:Config.NotificationsServerIP -ServiceName $serviceName

       # Save to registry
       Set-ItemProperty -Path $Script:RegistryPath -Name "ServiceMonitorEnabled" -Value 1
       Set-ItemProperty -Path $Script:RegistryPath -Name "ServiceMonitorName" -Value $serviceName
   }
   ```

3. **Create Task Function:**
   ```powershell
   function New-ServiceStatusNotificationTask {
       param(
           [string]$ServerIP,
           [string]$ServiceName
       )

       $taskName = "VLABS - Service Monitor - $ServiceName"

       # Event trigger: Event ID 7036 (Service Control Manager)
       # "The [service] service entered the [state] state."

       # Script content...
   }
   ```

4. **Generate Notification Script:**
   ```powershell
   $scriptBlock = @"
   `$ServerIP = "$ServerIP"
   `$ServiceName = "$ServiceName"

   # Check service status
   `$service = Get-Service -Name `$ServiceName

   if (`$service.Status -ne "Running") {
       # Send alert
   }
   "@
   ```

### Event Types for Future Implementation

**Windows Update:**
- Event Log: Microsoft-Windows-WindowsUpdateClient
- Event ID: 19 (update installed), 20 (update failed)
- Channels: UpdatesSuccess, UpdatesFailed

**Disk Space:**
- Event Log: System
- Event ID: 2013 (disk full warning)
- Channels: DiskSpaceAlerts

**Security Events:**
- Event Log: Security
- Event ID: 4625 (failed login), 4720 (user created)
- Channels: SecurityAlerts

**Application Crashes:**
- Event Log: Application
- Event ID: 1000 (application error)
- Channels: ApplicationErrors

### Transport Mapping Strategy

**Recommendation:** Use different Telegram transports for different event types.

**Understanding Transports:**
A transport is a named combination of a Telegram bot and channel. The NotificationsServer
manages the bot tokens and channel IDs, while clients (like this PowerShell script) simply
reference transport names.

**Example Configuration on NotificationsServer:**

```yaml
# catalog.yaml on NotificationsServer
bots:
  VLABS_Notifications_bot:
    token: "1234567890:ABCdefGHIjklMNOpqrsTUVwxyz"
    username: "@VLABS_Notifications_bot"

channels:
  VLABS-BK-Successful-Notification:
    id: "-1003351266067"
    type: private

  VLABS-BK-Failed-Notification:
    id: "-1003338758947"
    type: private

transports:
  SuccessfulBackups:
    bot: VLABS_Notifications_bot
    channel: VLABS-BK-Successful-Notification

  FailedBackups:
    bot: VLABS_Notifications_bot
    channel: VLABS-BK-Failed-Notification
```

**From PowerShell, you reference the transport name:**
```powershell
channels = @("SuccessfulBackups")  # This resolves to bot + channel on server
```

---

## Performance Considerations

### Resource Usage

**Wizard Script:**
- Runs on-demand (manual execution)
- Minimal resource usage
- No background processes

**Scheduled Tasks:**
- Idle until event occurs
- Negligible overhead when not running
- PowerShell execution: ~5-10 seconds per notification

**Event Log Queries:**
- Efficient with proper time windows
- Indexed by Event ID and timestamp
- Minimal performance impact

### Scalability

**Single Server:**
- Can handle hundreds of event types
- Each event type = one scheduled task
- No performance concerns for typical usage

**Multiple Servers:**
- Each server runs independently
- All send to same NotificationsServer
- Network bandwidth: negligible (small JSON payloads)

### Optimization Tips

1. **Narrow Time Windows:** Use smallest necessary time windows for event queries
2. **Limit MaxEvents:** Only retrieve needed events (e.g., `-MaxEvents 1`)
3. **Error Handling:** Use `-ErrorAction SilentlyContinue` to avoid unnecessary errors
4. **Async Notifications:** Current fire-and-forget approach is optimal

---

## Testing and Validation

### Unit Testing (Manual)

**Test Registry Functions:**
```powershell
# Test configuration save/load
Initialize-Configuration
$Script:Config.NotificationsServerIP = "192.168.1.100"
Save-Configuration
Initialize-Configuration
# Verify: $Script:Config.NotificationsServerIP should be "192.168.1.100"
```

**Test Server Connectivity:**
```powershell
Test-NotificationsServer -ServerIP "172.16.8.66"
# Should return $true if server is reachable
```

**Test Notification Sending:**
```powershell
Send-TestNotification -ServerIP "172.16.8.66" -Transport "SuccessfulBackups"
# Check Telegram for test message
```

### Integration Testing

**Test Event Trigger:**
```powershell
# Manually trigger scheduled task
Start-ScheduledTask -TaskName "VLABS - WSBackup Notifications"

# Check last run status
Get-ScheduledTaskInfo -TaskName "VLABS - WSBackup Notifications" | Select LastRunTime, LastTaskResult
```

**Test Event Log Query:**
```powershell
# Create test event (as admin)
Write-EventLog -LogName Application -Source "WSH" -EventId 14 -EntryType Information -Message "Test event"

# Query for test event
Get-WinEvent -FilterHashtable @{
    LogName = 'Application'
    ID = 14
    StartTime = (Get-Date).AddMinutes(-1)
}
```

### End-to-End Testing

**Scenario: Full Backup Workflow**

1. **Configure Windows Server Backup** (if not already)
2. **Run Wizard:** Configure notifications
3. **Perform Backup:** Manual or scheduled
4. **Verify Events:** Check Event Viewer for Event 14 and 4
5. **Check Task History:** Verify scheduled task ran
6. **Confirm Telegram:** Check for notification in channel

---

## Troubleshooting Guide for Developers

### Common Development Issues

**Issue: Scheduled task creates but doesn't trigger**

**Diagnosis:**
```powershell
# Export and inspect task XML
Export-ScheduledTask -TaskName "VLABS - WSBackup Notifications" | Out-File "C:\Temp\task.xml"
# Check for EventTrigger element and correct EventID
```

**Solution:** Verify event trigger XML is correctly formatted and event ID matches.

---

**Issue: Script generates but has syntax errors**

**Diagnosis:**
```powershell
# Test script syntax without execution
Get-Command "C:\ProgramData\VLABS\Notifications\WSBackup-Notification.ps1" -Syntax
```

**Solution:** Check for proper escaping of variables in `@"..."@` here-string.

---

**Issue: Registry configuration not persisting**

**Diagnosis:**
```powershell
# Check if path exists and is writable
Test-Path "HKLM:\SOFTWARE\VLABS\Notifications"
Get-Acl "HKLM:\SOFTWARE\VLABS\Notifications" | Format-List
```

**Solution:** Ensure running as Administrator. Registry path must be created before setting properties.

---

## Future Enhancements

### Planned Features

1. **Webhook Support:** Allow custom webhooks instead of just NotificationsServer
2. **Email Notifications:** Direct email sending (in addition to Telegram)
3. **Event Filtering:** More granular control over which events trigger notifications
4. **Custom Templates:** User-defined notification message templates
5. **Dashboard:** Web interface for configuration and status monitoring
6. **Multi-Server Management:** Centralized management of multiple Windows servers

### API Enhancements

**Request Authentication:**
```json
{
  "type": "telegram",
  "channels": ["SuccessfulBackups"],
  "subject": "...",
  "body": "...",
  "auth_token": "..."
}
```

**Rich Notifications:**
```json
{
  "type": "telegram",
  "channels": ["SuccessfulBackups"],
  "subject": "...",
  "body": "...",
  "metadata": {
    "severity": "info",
    "source": "WSBackup",
    "timestamp": "2025-11-14T02:15:32Z",
    "tags": ["backup", "windows-server", "automated"]
  }
}
```

---

## Conclusion

The PowerShell Event Sender provides a robust, extensible architecture for bridging Windows events with Telegram notifications. Its design emphasizes:

- **Simplicity:** Easy to configure and use
- **Reliability:** Event-driven, no polling required
- **Security:** Appropriate for LAN environments
- **Extensibility:** Easy to add new event types
- **Maintainability:** Clear code structure and documentation

For implementation questions or feature requests, refer to the parent NotificationsServer project documentation.

---

**Last Updated:** November 14, 2025
**Version:** 0.1.0
