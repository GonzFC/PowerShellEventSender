# Contributing to PowerShell Event Sender

Thank you for your interest in contributing to the PowerShell Event Sender project! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Guidelines](#development-guidelines)
- [Submitting Changes](#submitting-changes)
- [Adding New Event Types](#adding-new-event-types)

---

## Code of Conduct

This project is part of the VLABS infrastructure suite and is maintained for personal and educational purposes. We welcome contributions that:

- Improve functionality
- Enhance documentation
- Fix bugs
- Add new event monitoring capabilities
- Improve security
- Optimize performance

Please be respectful and constructive in all interactions.

---

## Getting Started

### Prerequisites

- **Windows Environment:** Windows Server 2012 R2+ or Windows 10/11 for testing
- **PowerShell:** 5.1 or later
- **Administrator Access:** Required for testing scheduled tasks
- **NotificationsServer:** Access to a running NotificationsServer instance
- **Git:** For version control

### Setting Up Development Environment

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/PowerShellEventSender.git
   cd PowerShellEventSender
   ```

2. **Read the documentation:**
   - [README.md](README.md) - Overview and quick start
   - [ARCHITECTURE.md](ARCHITECTURE.md) - Technical details
   - [USAGE.md](USAGE.md) - Usage guide

3. **Set up NotificationsServer:**
   - Follow the parent project documentation
   - Ensure you have access to test Telegram channels

4. **Test the wizard:**
   ```powershell
   # Run as Administrator
   .\Setup-VLABSNotifications.ps1
   ```

---

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue with:

- **Clear title:** Describe the issue concisely
- **Description:** Detailed explanation of the problem
- **Steps to reproduce:** How to recreate the issue
- **Expected behavior:** What should happen
- **Actual behavior:** What actually happens
- **Environment:** Windows version, PowerShell version
- **Logs:** Relevant error messages or task scheduler logs

**Example:**
```
Title: Scheduled task not triggering on Event ID 14

Description: After running the wizard and configuring Windows Server
Backup notifications, the scheduled task is created but does not trigger
when a backup completes.

Steps to reproduce:
1. Run Setup-VLABSNotifications.ps1 as Administrator
2. Configure option 1 (Windows Server Backup)
3. Complete a Windows Server Backup
4. Check Event Viewer - Event ID 14 is logged
5. Check Task Scheduler - Task did not run

Expected: Task should trigger and send notification
Actual: Task remains idle

Environment: Windows Server 2019, PowerShell 5.1
Logs: [attach task scheduler history screenshot]
```

### Suggesting Enhancements

For feature requests or enhancements:

- **Use case:** Describe why this feature is needed
- **Proposed solution:** How should it work?
- **Alternatives:** Other approaches considered
- **Impact:** Who benefits from this feature?

### Pull Requests

We welcome pull requests for:

- Bug fixes
- New event monitoring types
- Documentation improvements
- Code optimizations
- Security enhancements

---

## Development Guidelines

### PowerShell Coding Standards

**Style Guide:**

1. **Use Verb-Noun naming:** `Get-Configuration`, `New-ScheduledTask`
2. **CamelCase for functions:** `function Invoke-WSBackupConfiguration`
3. **Comment-based help:** Include `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`
4. **Error handling:** Use `try/catch` and `-ErrorAction` appropriately
5. **Indentation:** 4 spaces (no tabs)

**Example:**
```powershell
function Test-NotificationsServer {
    <#
    .SYNOPSIS
        Test connectivity to NotificationsServer

    .DESCRIPTION
        Attempts to connect to the NotificationsServer health endpoint
        and verifies it is responding correctly.

    .PARAMETER ServerIP
        The IP address of the NotificationsServer

    .EXAMPLE
        Test-NotificationsServer -ServerIP "172.16.8.66"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ServerIP
    )

    try {
        $uri = "http://${ServerIP}:8089/health"
        $response = Invoke-RestMethod -Uri $uri -TimeoutSec 5 -ErrorAction Stop

        return ($response.status -eq "healthy")
    }
    catch {
        Write-Warning "Cannot reach server: $($_.Exception.Message)"
        return $false
    }
}
```

### Documentation Standards

**Markdown Files:**

- Use clear headings and structure
- Include code examples with syntax highlighting
- Provide both simple and advanced examples
- Keep line length reasonable (80-100 characters preferred)
- Use tables for structured data
- Include diagrams where helpful (ASCII art or mermaid)

**Code Comments:**

- Explain **why**, not **what**
- Document complex logic
- Keep comments up-to-date with code changes

### Testing

**Manual Testing Checklist:**

Before submitting a pull request, test:

- ✅ Wizard runs without errors
- ✅ Configuration saves to registry correctly
- ✅ Scheduled task is created properly
- ✅ Event trigger works (test with real events)
- ✅ Notifications are sent successfully
- ✅ Test notification function works
- ✅ Server connectivity test works
- ✅ Idempotency (can run wizard multiple times)
- ✅ Configuration updates work
- ✅ Error handling behaves correctly

**Test on Multiple Environments:**

If possible, test on:
- Windows Server 2019/2022
- Windows 10/11
- Different PowerShell versions (5.1, 7.x)

---

## Submitting Changes

### Workflow

1. **Fork the repository**
2. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```
   Or for bug fixes:
   ```bash
   git checkout -b fix/bug-description
   ```

3. **Make your changes:**
   - Follow coding standards
   - Add/update documentation
   - Test thoroughly

4. **Commit your changes:**
   ```bash
   git add .
   git commit -m "Add feature: descriptive message"
   ```

   **Commit Message Format:**
   ```
   <type>: <subject>

   <body>

   <footer>
   ```

   **Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

   **Example:**
   ```
   feat: Add Windows Update event monitoring

   - Add menu option for Windows Update notifications
   - Create New-WindowsUpdateNotificationTask function
   - Generate script for Event ID 19 (update installed)
   - Update documentation with new event type

   Closes #12
   ```

5. **Push to your fork:**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Open a Pull Request:**
   - Clear title describing the change
   - Reference related issues
   - Describe what changed and why
   - Include testing performed

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Code refactoring
- [ ] Security enhancement

## Changes Made
- List of specific changes

## Testing Performed
- Describe testing done
- Include test environment details

## Related Issues
Closes #issue_number

## Screenshots (if applicable)
```

---

## Adding New Event Types

To add a new event monitoring type (e.g., Service Status, Disk Space):

### 1. Update the Menu

Edit `Setup-VLABSNotifications.ps1`:

```powershell
function Show-MainMenu {
    # ... existing menu items ...
    Write-Host "  2. Monitor Service Status Changes" -ForegroundColor White
}
```

### 2. Create Configuration Function

```powershell
function Invoke-ServiceMonitorConfiguration {
    <#
    .SYNOPSIS
        Configure service status monitoring
    #>

    # Get service name from user
    $serviceName = Read-Host "Enter service name to monitor"

    # Validate service exists
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if (-not $service) {
        Write-ColorMessage "Service '$serviceName' not found" -Type Error
        return
    }

    # Create scheduled task
    New-ServiceMonitorTask -ServerIP $Script:Config.NotificationsServerIP -ServiceName $serviceName

    # Save configuration
    Set-ItemProperty -Path $Script:RegistryPath -Name "ServiceMonitorEnabled" -Value 1
    Set-ItemProperty -Path $Script:RegistryPath -Name "ServiceMonitorName" -Value $serviceName

    Save-Configuration
}
```

### 3. Create Task Function

```powershell
function New-ServiceMonitorTask {
    param(
        [string]$ServerIP,
        [string]$ServiceName
    )

    $taskName = "VLABS - Service Monitor - $ServiceName"

    # Create notification script
    $scriptBlock = @"
# Service Monitor Notification Script
`$ServerIP = "$ServerIP"
`$ServiceName = "$ServiceName"

# Check service status
`$service = Get-Service -Name `$ServiceName -ErrorAction SilentlyContinue

if (`$service -and `$service.Status -ne "Running") {
    # Send alert
    Invoke-RestMethod -Uri "http://`${ServerIP}:8089/api/v1/notify" ``
        -Method Post ``
        -ContentType "application/json" ``
        -Body (@{
            type = "telegram"
            channels = @("ServiceAlerts")
            subject = "🔴 Service Down - `$ServiceName"
            body = "Service: `$ServiceName`nStatus: `$(`$service.Status)`nServer: `$env:COMPUTERNAME"
        } | ConvertTo-Json)
}
"@

    # Save script
    $scriptPath = "$env:ProgramData\VLABS\Notifications\ServiceMonitor-$ServiceName.ps1"
    $scriptBlock | Out-File -FilePath $scriptPath -Encoding UTF8 -Force

    # Create scheduled task with event trigger
    # Event ID 7036 from System log (Service Control Manager)
    # ... (similar to WSBackup task creation)
}
```

### 4. Update Documentation

- Add to README.md features list
- Update USAGE.md with new scenario
- Document in ARCHITECTURE.md
- Update CHANGELOG.md

### 5. Test Thoroughly

- Test task creation
- Verify event trigger
- Confirm notifications are sent
- Test on multiple Windows versions

### 6. Submit Pull Request

Follow the submission guidelines above.

---

## Questions?

If you have questions about contributing:

- Check existing issues and pull requests
- Review the documentation
- Open a discussion issue

---

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to PowerShell Event Sender!
