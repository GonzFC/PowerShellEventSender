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
- Code signing (for v1.0.0)

## [0.3.0] - 2025-11-16

### Added
- **One-Liner GitHub Deployment**: Install/update with single PowerShell command
  - Command: `irm https://github.com/GonzFC/PowerShellEventSender/releases/latest/download/Install-Run-VLABS_NotificationsClient.ps1 | iex`
  - Uses GitHub Releases for distribution (like Chris Titus Tech Windows Utility)
  - Always downloads latest version automatically
- **Automatic Version Checking**: Script checks GitHub API for updates on every run
  - Function: `Test-GitHubVersion`
  - Displays update notification if newer version available
  - Shows one-liner command to update
  - Gracefully handles GitHub API unavailability
  - Shows "You are running the latest version" when up to date
- **Uninstall Instructions**: New menu option to view removal steps
  - Menu option 9: "Uninstall - View Instructions"
  - Function: `Show-UninstallInstructions`
  - Lists all VLABS scheduled tasks currently installed
  - Provides step-by-step removal instructions
  - Notes that registry config is harmless to leave
- **AIQD Methodology**: Documented development approach
  - New file: `AIQD_Methodology.md`
  - Structured process: Acknowledge, Investigate, Question, Advice, Document
  - Applied to all significant changes going forward
- **Release Guide**: Complete release workflow documentation
  - New file: `RELEASE_GUIDE.md`
  - Step-by-step GitHub Release creation
  - Version numbering standards
  - Security considerations
  - Best practices and checklists

### Changed
- **Script Renamed**: `Setup-VLABSNotifications.ps1` → `Install-Run-VLABS_NotificationsClient.ps1`
  - More descriptive name indicating client role
  - Clearer that it's for installation and running
- **Deployment Model**: Transformed from download-first to web-hosted one-liner execution
  - No manual file downloads required
  - No need to navigate to script location
  - Idempotent - safe to run repeatedly
  - Always gets latest version from GitHub
- **README.md**: Completely restructured Quick Start section
  - One-liner installation prominently featured
  - Manual installation (inspect-first) option provided
  - Security notes about `| iex` execution
  - Updated usage examples with v0.3.0 output
- **Script Header**: Enhanced with one-liner deployment instructions
  - Shows both one-liner and inspect-first approaches
  - Updated version to 0.3.0
  - Added repository URL
  - Added license information

### Technical Details
- **Version Configuration**: Added script-level version tracking
  - Variable: `$Script:Version = "0.3.0"`
  - Used for version comparison with GitHub
- **GitHub Integration**:
  - Repository: `GonzFC/PowerShellEventSender`
  - API endpoint: `https://api.github.com/repos/GonzFC/PowerShellEventSender/releases/latest`
  - Download endpoint: `/releases/latest/download/Install-Run-VLABS_NotificationsClient.ps1`
- **Version Check Display**: Fancy bordered notification box
  - Shows current version vs latest version
  - Color-coded (Yellow border, Green latest version)
  - Includes one-liner command to update
  - Links to changelog
  - 2-second pause to ensure user sees message
- **Main Function Flow**: Added version check before configuration load
  - Order: Admin check → Version check → Load config → Menu loop
  - Non-blocking - continues if GitHub unreachable

### Documentation
- Updated all references to script name throughout documentation
- Added comprehensive release workflow guide
- Documented AIQD methodology for future development
- Updated usage examples to reflect one-liner deployment
- Enhanced security notes about remote execution

### Deployment
- **Breaking Change**: Users should update bookmarks/documentation to new script name
- **Migration**: Old downloaded scripts still work, but one-liner is now preferred method
- **Backward Compatibility**: All features from v0.2.0 preserved
- **Update Path**: Simply run the one-liner - automatically gets v0.3.0

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
