# Changelog

All notable changes to the PowerShell Event Sender project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Windows Update event monitoring
- Service status change notifications
- Disk space alert monitoring
- Security event notifications
- Multiple NotificationsServer support
- HTTPS/TLS support
- API authentication

## [0.1.0] - 2025-11-14

### Added
- Initial release of PowerShell Event Sender
- Interactive configuration wizard (`Setup-VLABSNotifications.ps1`)
- Windows Server Backup monitoring support
  - Event ID 14 (Backup operation completed) trigger
  - Event ID 4 (Successful backup) verification
  - Success notifications to `SuccessfulBackups` channel
  - Failure notifications to `FailedBackups` channel
  - Detailed error reporting in failure notifications
- Registry-based configuration storage (`HKLM:\SOFTWARE\VLABS\Notifications`)
- Automated Windows Scheduled Task creation with event triggers
- Dynamic PowerShell script generation
- NotificationsServer REST API integration
- Server connectivity testing
- Test notification capability
- Idempotent wizard design (safe to run multiple times)
- Comprehensive documentation:
  - README.md - Project overview and quick start
  - USAGE.md - Detailed usage guide
  - ARCHITECTURE.md - Technical architecture documentation
- MIT License
- Git ignore configuration

### Features
- Menu-driven wizard interface
- Color-coded console messages
- IP address configuration with validation
- Automatic task updates on configuration changes
- Event log querying with time windows
- Backup status determination (success/failure)
- Server name and timestamp inclusion in notifications
- Error logging to Windows Event Log
- Task execution as SYSTEM account with elevated privileges

### Security
- Registry-based configuration (Admin-only write)
- Protected script storage location (`C:\ProgramData\VLABS\Notifications`)
- LAN-only communication model
- No credentials stored on Windows machines

### Documentation
- Quick start guide
- Detailed installation walkthrough
- Configuration management instructions
- Event trigger explanation
- Testing and verification procedures
- Troubleshooting guide
- Architecture diagrams and data flow
- Security model documentation
- Extension guide for adding new event types

[Unreleased]: https://github.com/yourusername/PowerShellEventSender/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/yourusername/PowerShellEventSender/releases/tag/v0.1.0
