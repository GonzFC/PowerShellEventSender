---
name: Bug Report
about: Report a bug or issue with PowerShell Event Sender
title: '[BUG] '
labels: bug
assignees: ''
---

## Description

A clear and concise description of the bug.

## Steps to Reproduce

1.
2.
3.
4.

## Expected Behavior

What you expected to happen.

## Actual Behavior

What actually happened.

## Environment

- **Windows Version:** (e.g., Windows Server 2019, Windows 11 Pro)
- **PowerShell Version:** (run `$PSVersionTable.PSVersion`)
- **NotificationsServer Version:**
- **NotificationsServer IP:**
- **Wizard Version:** (see CHANGELOG.md)

## Logs and Screenshots

**Task Scheduler History:**
```
Paste relevant task scheduler history or screenshots
```

**Event Viewer Logs:**
```
Paste relevant event log entries
```

**PowerShell Error Output:**
```
Paste any error messages
```

**Screenshots:**
(If applicable, add screenshots to help explain the problem)

## Configuration

**Registry Settings:**
```powershell
# Output of:
Get-ItemProperty -Path "HKLM:\SOFTWARE\VLABS\Notifications"
```

**Scheduled Task Details:**
```powershell
# Output of:
Get-ScheduledTask -TaskName "VLABS - WSBackup Notifications" | Format-List *
```

## Additional Context

Add any other context about the problem here.

## Attempted Solutions

What have you tried to fix the issue?
