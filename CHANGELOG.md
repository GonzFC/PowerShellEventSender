# Changelog

All notable changes to the PowerShell Event Sender project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Windows Update event monitoring
- Service status change notifications
- Security event notifications
- Multiple NotificationsServer support
- HTTPS/TLS support
- API authentication

## [0.2.0] - 2025-11-14

### Added
- **Disk Space Monitoring**: Complete disk space alert system
  - Hybrid trigger: Time-based (every 6 hours) + Event-based (Event ID 2013)
  - Monitors local fixed HDD/SSD drives only
  - Intelligent drive filtering: Excludes USB, network mapped, iSCSI, and optical drives
  - Threshold: <20% free space
  - Registry-based throttling: One notification per 6 hours per drive
  - Notification includes: Drive letter, label, GB free/total, percent free
  - Uses `LowDiskSpace` transport
  - New scheduled task: "VLABS - Disk Space Notifications"
  - New menu option: "2. Notify Low Disk Space Alerts"

### Changed
- Configuration storage now includes `DiskSpaceEnabled` flag
- Main menu updated to show disk space monitoring status
- Script version: 0.1.2 → 0.2.0

### Technical Details
- **Drive Detection Logic**: Uses Get-PhysicalDisk to filter by MediaType (HDD/SSD only)
- **BusType Filtering**: Excludes USB, iSCSI, and Virtual bus types
- **Throttling Implementation**: Registry values at `HKLM:\SOFTWARE\VLABS\Notifications\DiskSpace`
- **Event ID 2013 Reliability**: Hybrid approach ensures monitoring even if Event 2013 fails to fire
- **Script Location**: `C:\ProgramData\VLABS\Notifications\DiskSpace-Notification.ps1`

### Documentation
- Added disk space monitoring section to README.md
- Updated feature list and usage examples
- Documented hybrid trigger strategy and reliability considerations

## [0.1.2] - 2025-11-14

### Added
- **Event ID 5 Detection**: Explicit detection of backup failure events
  - Scheduled task now triggers on Event ID 5 (Backup failed) in addition to Event ID 14
  - Script explicitly checks for Event ID 5 to confirm failures
  - Extracts detailed error information directly from Event ID 5 message
  - Added inconclusive state handling (exits without notification if neither Event 4 nor 5 found)

### Changed
- Improved failure detection logic from implicit (no Event 4 = failure) to explicit (Event 5 = failure)
- Enhanced error reporting with Event ID 5 details plus additional error context
- Updated scheduled task trigger XML to monitor `EventID=14 or EventID=5`
- User-facing messages now mention both Event ID 14 and Event ID 5 monitoring

### Fixed
- False positive failure notifications when backup status is inconclusive
- Missing detailed error information from actual failure events

### Documentation
- Updated README.md with Event ID 5 detection details
- Updated ARCHITECTURE.md flow diagrams to show Event ID 5 logic
- Updated scheduled task trigger documentation

## [0.1.1] - 2025-11-14

### Changed
- **Updated for Transports Architecture**: Aligned with NotificationsServer API v1.0.0
  - Updated variable names from `$channel` to `$transport` for clarity
  - Added Transports architecture explanation in script header
  - Updated all user-facing messages to reference "transports" instead of "channels"
  - Updated README.md with "Understanding Transports" section
  - Updated ARCHITECTURE.md with Transport Mapping Strategy
  - API compatibility note added: Requires NotificationsServer API v1.0.0+

### Documentation
- Enhanced script header with detailed Transports explanation
- Added inline comments explaining API parameter backward compatibility
- Updated all examples to reflect Transport terminology

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
