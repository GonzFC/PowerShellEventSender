# PowerShell Event Sender for Windows

**Automated Windows Event-to-Telegram notification system** for Windows Server environments.

Monitor Windows events and automatically send notifications to Telegram channels via the NotificationsServer.

---

## Overview

This PowerShell wizard helps you configure **Windows Scheduled Tasks** that monitor Windows events (like Windows Server Backup completion) and automatically send notifications to your Telegram channels through the NotificationsServer.

### Key Features

- **Idempotent Configuration** - Safe to run multiple times, updates existing settings
- **Interactive Wizard** - User-friendly menu-driven interface
- **Automated Event Monitoring** - Responds to Windows events automatically
- **Windows Server Backup Support** - Built-in support for backup success/failure notifications
- **Extensible Design** - Easy to add more event types and notification scenarios

---

## Requirements

- **Windows Server** 2012 R2 or later (or Windows 10/11 with Event Log support)
- **Administrator Rights** - Required to create Scheduled Tasks
- **PowerShell 5.1+** - Included in modern Windows
- **NotificationsServer** - Running on your LAN (see parent project)
- **Network Access** - Windows machine must reach the NotificationsServer IP

---

## Quick Start

### 1. Download the Script

Save `Setup-VLABSNotifications.ps1` to your Windows machine.

### 2. Test Syntax (Optional but Recommended)

```powershell
# Verify script syntax before running
.\Test-Syntax.ps1
```

### 3. Run as Administrator

```powershell
# Right-click PowerShell and select "Run as Administrator"
cd C:\Path\To\Script
.\Setup-VLABSNotifications.ps1
```

### 4. Follow the Wizard

The wizard will guide you through:
1. Choosing a notification type (Windows Server Backup, etc.)
2. Configuring the NotificationsServer IP address
3. Creating/updating the Scheduled Task
4. Testing the configuration

---

## Current Features

### Windows Server Backup Notifications

Monitors Windows Server Backup events and sends notifications:

**Successful Backup:**
- Triggers on: Event ID 14 (Backup operation completed)
- Verifies: Event ID 4 (Successful backup) exists
- Sends to: `SuccessfulBackups` Telegram channel

**Failed Backup:**
- Triggers on: Event ID 14 (Backup operation completed)
- Checks: No Event ID 4 found (indicates failure)
- Sends to: `FailedBackups` Telegram channel

---

## How It Works

### Architecture

1. **Wizard Script** (`Setup-VLABSNotifications.ps1`)
   - Interactive menu for configuration
   - Idempotent - safe to run multiple times
   - Stores configuration persistently

2. **Scheduled Tasks**
   - Triggered by Windows Event Log events
   - Runs PowerShell script in response to events
   - Queries event log for additional context
   - Sends notification via NotificationsServer API

3. **NotificationsServer Integration**
   - Uses REST API (`POST /api/v1/notify`)
   - Sends to catalog-managed Telegram channels
   - Includes timestamp, server name, and event details

### Event Flow Example

```
[Windows Event Occurs]
    ↓
[Event ID 14: Backup Operation Completed]
    ↓
[Scheduled Task Triggers]
    ↓
[PowerShell Script Executes]
    ↓
[Checks for Event ID 4 (Success Indicator)]
    ↓
[Sends Notification to NotificationsServer]
    ↓
[NotificationsServer sends to Telegram]
    ↓
[You receive notification on your phone!]
```

---

## Configuration Storage

The wizard stores configuration in the Windows Registry:

**Location:** `HKLM:\SOFTWARE\VLABS\Notifications`

**Keys:**
- `NotificationsServerIP` - IP address of the NotificationsServer
- `WSBackupEnabled` - Whether Windows Server Backup monitoring is enabled

This allows the wizard to remember your settings and update configurations without re-prompting for unchanged values.

---

## Scheduled Task Details

### Task Name
`VLABS - WSBackup Notifications`

### Trigger
- **Event Log:** Microsoft-Windows-Backup
- **Event ID:** 14 (Backup operation completed)

### Action
Executes PowerShell script that:
1. Queries Event Log for recent Event ID 4 (success) or errors
2. Determines backup status (success/failure)
3. Sends notification to appropriate Telegram channel

### Security
- Runs as: SYSTEM
- Highest privileges: Yes
- Required for Event Log access and network communication

---

## Usage Examples

### First-Time Setup

```powershell
PS C:\> .\Setup-VLABSNotifications.ps1

=== VLABS Notifications Configuration Wizard ===

Choose an option:
1. Notify Windows Server Backup Status
0. Update Configuration and Exit

Enter choice: 1

Enter NotificationsServer IP address: 172.16.8.66

Creating scheduled task "VLABS - WSBackup Notifications"...
Task created successfully!

Testing notification...
✓ Test notification sent to SuccessfulBackups channel
```

### Updating Configuration

```powershell
PS C:\> .\Setup-VLABSNotifications.ps1

=== VLABS Notifications Configuration Wizard ===

Current NotificationsServer IP: 172.16.8.66

Choose an option:
1. Notify Windows Server Backup Status [ENABLED]
0. Update Configuration and Exit

Enter choice: 0

Enter new IP address (or press Enter to keep 172.16.8.66): 192.168.1.100

Configuration updated!
```

---

## Troubleshooting

### Task Not Triggering

1. **Verify Event Source:**
   ```powershell
   Get-WinEvent -LogName Microsoft-Windows-Backup -MaxEvents 10
   ```

2. **Check Task Status:**
   ```powershell
   Get-ScheduledTask -TaskName "VLABS - WSBackup Notifications"
   ```

3. **View Task History:**
   - Open Task Scheduler (taskschd.msc)
   - Navigate to Task Scheduler Library
   - Find "VLABS - WSBackup Notifications"
   - Check History tab

### Notification Not Received

1. **Test Connectivity:**
   ```powershell
   Invoke-RestMethod -Uri "http://172.16.8.66:8089/health"
   ```

2. **Send Test Notification:**
   ```powershell
   Invoke-RestMethod -Uri "http://172.16.8.66:8089/api/v1/notify" `
       -Method Post -ContentType "application/json" `
       -Body (@{type="telegram";channels=@("SuccessfulBackups");subject="Test";body="Test message"} | ConvertTo-Json)
   ```

3. **Check Server Logs:**
   ```bash
   # On the Mac running NotificationsServer
   tail -f ~/NotificationsServer/logs/current.log
   ```

### Permission Issues

- Ensure you ran PowerShell as Administrator
- Verify SYSTEM account has network access
- Check Windows Firewall settings

---

## Project Structure

```
PowerShellEventSender/
├── README.md                          # This file
├── Setup-VLABSNotifications.ps1      # Main wizard script
├── Test-Syntax.ps1                   # Syntax validation script
├── USAGE.md                          # Detailed usage guide
├── TESTING.md                        # Testing guide
└── ARCHITECTURE.md                   # Technical architecture details
```

---

## Extending the System

### Adding New Event Types

The wizard is designed to be extensible. To add new event monitoring:

1. Add new menu option in the wizard
2. Create corresponding scheduled task creation function
3. Implement event handling logic
4. Store configuration in registry

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed implementation guidance.

### Supported Event Sources

Currently supported:
- ✅ Windows Server Backup (Microsoft-Windows-Backup)

Planned:
- 🔄 Windows Update events
- 🔄 Service status changes
- 🔄 Disk space alerts
- 🔄 Security events
- 🔄 Custom application events

---

## Integration with NotificationsServer

This project is a **client component** of the NotificationsServer ecosystem.

**Parent Project:** [NotificationsServer](../README.md)

**Communication Method:**
- Protocol: HTTP REST API
- Endpoint: `POST http://{SERVER_IP}:8089/api/v1/notify`
- Format: JSON
- Authentication: None (LAN-only, trusted network)

**API Usage Example:**
```json
{
  "type": "telegram",
  "channels": ["SuccessfulBackups"],
  "subject": "WSSERVER - Backup Successful",
  "body": "Backup completed at 2025-11-14 02:00:00\nStatus: Success\nDuration: 5m 32s"
}
```

See [PowerShell-Integration.md](../Integration%20Documentation/PowerShell-Integration.md) for complete API documentation.

---

## Security Considerations

### Network Security

- **LAN-Only:** NotificationsServer should only be accessible on trusted LAN
- **No Authentication:** API has no authentication (by design for simplicity)
- **Firewall:** Consider restricting access to known client IPs

### Sensitive Data

- **No Secrets in Tasks:** Scheduled tasks are visible to administrators
- **Event Data:** Backup status is generally non-sensitive
- **IP Storage:** Server IP stored in registry (HKLM, admin-only)

### Privilege Requirements

- **Administrator Rights:** Required for scheduled task creation
- **SYSTEM Account:** Tasks run as SYSTEM for event log access
- **Network Access:** SYSTEM must have outbound HTTP access

---

## Version History

**0.1.0** - Initial Release
- Windows Server Backup monitoring
- Interactive wizard
- Idempotent configuration
- Registry-based storage

---

## Related Documentation

**Parent Project:**
- [NotificationsServer README](../README.md)
- [PowerShell Integration Guide](../Integration%20Documentation/PowerShell-Integration.md)
- [Catalog Guide](../CATALOG_GUIDE.md)

**This Project:**
- [USAGE.md](USAGE.md) - Detailed usage instructions
- [TESTING.md](TESTING.md) - Testing and validation guide
- [ARCHITECTURE.md](ARCHITECTURE.md) - Technical design and implementation

---

## Support

For issues, questions, or suggestions:
1. Check the [troubleshooting section](#troubleshooting)
2. Review NotificationsServer logs
3. Test network connectivity
4. Verify scheduled task configuration

---

## License

Personal use. Part of the VLABS infrastructure automation suite.

**Last Updated:** November 14, 2025
