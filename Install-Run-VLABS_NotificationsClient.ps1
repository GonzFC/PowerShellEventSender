<#
.SYNOPSIS
    VLABS Notifications Client - One-Liner Installation & Configuration Wizard

.DESCRIPTION
    Interactive wizard to configure Windows Event-to-Telegram notifications
    via the NotificationsServer. Creates and manages Windows Scheduled Tasks
    that monitor events and send notifications automatically.

    ONE-LINER DEPLOYMENT:
    Run directly from GitHub without downloading (PowerShell 5.1+):

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iwr -useb https://raw.githubusercontent.com/GonzFC/PowerShellEventSender/main/Install-Run-VLABS_NotificationsClient.ps1 | iex

    Or download and inspect first:

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $script = (iwr 'https://raw.githubusercontent.com/GonzFC/PowerShellEventSender/main/Install-Run-VLABS_NotificationsClient.ps1' -UseBasicParsing).Content
        $script | Out-File -FilePath "$env:TEMP\VLABS-Install.ps1"
        notepad "$env:TEMP\VLABS-Install.ps1"  # Inspect the code
        & "$env:TEMP\VLABS-Install.ps1"        # Run after inspection

    NOTE: TLS 1.2 enforcement is required because PowerShell 5.1 defaults to TLS 1.0,
    but GitHub requires TLS 1.2 for secure connections.

    TRANSPORTS ARCHITECTURE:
    This script uses the NotificationsServer's Transports system. A "transport"
    is a named combination of a Telegram bot and channel configured on the server.

    Example Transports:
    - "SuccessfulBackups" -> Routes to success notification channel
    - "FailedBackups"     -> Routes to failure notification channel
    - "LowDiskSpace"      -> Routes to disk space alert channel

    The NotificationsServer manages the bot tokens and channel IDs. This script
    simply references transport names like "SuccessfulBackups" without needing
    to know the underlying bot/channel details.

.NOTES
    Version: 0.3.2
    Author: VLABS Infrastructure
    Requires: Administrator privileges, PowerShell 5.1+
    API Compatibility: NotificationsServer API v1.0.0+
    Repository: https://github.com/GonzFC/PowerShellEventSender
    License: MIT

.EXAMPLE
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iwr -useb https://raw.githubusercontent.com/GonzFC/PowerShellEventSender/main/Install-Run-VLABS_NotificationsClient.ps1 | iex

    One-liner: Downloads and runs the wizard directly from GitHub (PowerShell 5.1+).
    TLS 1.2 enforcement is required for GitHub connectivity.

.EXAMPLE
    .\Install-Run-VLABS_NotificationsClient.ps1

    Runs the interactive configuration wizard from a local copy.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param()

# ============================================================================
# CONFIGURATION
# ============================================================================

$Script:Version = "0.3.2"
$Script:RegistryPath = "HKLM:\SOFTWARE\VLABS\Notifications"
$Script:NotificationsServerPort = 8089
$Script:Config = @{}
$Script:GitHubRepo = "GonzFC/PowerShellEventSender"
$Script:GitHubApiUrl = "https://api.github.com/repos/$Script:GitHubRepo/releases/latest"

# Ensure TLS 1.2 is enabled for GitHub API calls and downloads
# PowerShell 5.1 defaults to TLS 1.0, but GitHub requires TLS 1.2
if ([Net.ServicePointManager]::SecurityProtocol -notmatch 'Tls12') {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Write-ColorMessage {
    <#
    .SYNOPSIS
        Write colored console messages
    #>
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Type = 'Info'
    )

    $colors = @{
        Info    = 'Cyan'
        Success = 'Green'
        Warning = 'Yellow'
        Error   = 'Red'
    }

    $symbols = @{
        Info    = '[i]'
        Success = '[✓]'
        Warning = '[!]'
        Error   = '[✗]'
    }

    Write-Host "$($symbols[$Type]) $Message" -ForegroundColor $colors[$Type]
}

function Test-GitHubVersion {
    <#
    .SYNOPSIS
        Check GitHub for newer version of this script
    #>

    try {
        # GitHub API call to get latest release
        $latestRelease = Invoke-RestMethod -Uri $Script:GitHubApiUrl -TimeoutSec 10 -ErrorAction Stop

        # Extract version from tag (e.g., "v0.3.0" -> "0.3.0")
        $latestVersion = $latestRelease.tag_name -replace '^v', ''

        # Compare versions
        if ($latestVersion -ne $Script:Version) {
            Write-Host ""
            Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
            Write-Host "║  " -NoNewline -ForegroundColor Yellow
            Write-Host "UPDATE AVAILABLE" -NoNewline -ForegroundColor Yellow
            Write-Host "                                              ║" -ForegroundColor Yellow
            Write-Host "║                                                              ║" -ForegroundColor Yellow
            Write-Host "║  Current Version:  " -NoNewline -ForegroundColor Yellow
            Write-Host "v$Script:Version" -NoNewline -ForegroundColor White
            Write-Host ("" + (" " * (40 - $Script:Version.Length))) -NoNewline
            Write-Host "║" -ForegroundColor Yellow
            Write-Host "║  Latest Version:   " -NoNewline -ForegroundColor Yellow
            Write-Host "v$latestVersion" -NoNewline -ForegroundColor Green
            Write-Host ("" + (" " * (40 - $latestVersion.Length))) -NoNewline
            Write-Host "║" -ForegroundColor Yellow
            Write-Host "║                                                              ║" -ForegroundColor Yellow
            Write-Host "║  " -NoNewline -ForegroundColor Yellow
            Write-Host "Run the one-liner again to get the latest version:" -NoNewline -ForegroundColor White
            Write-Host "          ║" -ForegroundColor Yellow
            Write-Host "║                                                              ║" -ForegroundColor Yellow
            Write-Host "║  " -NoNewline -ForegroundColor Yellow
            Write-Host "irm https://github.com/$Script:GitHubRepo" -NoNewline -ForegroundColor Cyan
            Write-Host "/" -NoNewline -ForegroundColor Cyan
            Write-Host "" -ForegroundColor Yellow
            Write-Host "║  " -NoNewline -ForegroundColor Yellow
            Write-Host "    /releases/latest/download/" -NoNewline -ForegroundColor Cyan
            Write-Host "" -ForegroundColor Yellow
            Write-Host "║  " -NoNewline -ForegroundColor Yellow
            Write-Host "    Install-Run-VLABS_NotificationsClient.ps1 | iex" -NoNewline -ForegroundColor Cyan
            Write-Host "       ║" -ForegroundColor Yellow
            Write-Host "║                                                              ║" -ForegroundColor Yellow
            Write-Host "║  " -NoNewline -ForegroundColor Yellow
            Write-Host "Changelog: " -NoNewline -ForegroundColor White
            Write-Host "https://github.com/$Script:GitHubRepo/releases" -NoNewline -ForegroundColor Cyan
            Write-Host " ║" -ForegroundColor Yellow
            Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
            Write-Host ""

            # Give user a moment to see the message
            Start-Sleep -Seconds 2
        }
        else {
            Write-ColorMessage "You are running the latest version (v$Script:Version)" -Type Success
        }
    }
    catch {
        # Silently fail - don't interrupt workflow if GitHub is unreachable
        Write-ColorMessage "Could not check for updates (GitHub unreachable)" -Type Warning
    }
}

function Initialize-Configuration {
    <#
    .SYNOPSIS
        Load configuration from registry or create defaults
    #>

    # Ensure registry path exists
    if (-not (Test-Path $Script:RegistryPath)) {
        New-Item -Path $Script:RegistryPath -Force | Out-Null
        Write-ColorMessage "Created registry path: $Script:RegistryPath" -Type Info
    }

    # Load existing configuration
    $regProperties = Get-ItemProperty -Path $Script:RegistryPath -ErrorAction SilentlyContinue

    if ($regProperties) {
        $Script:Config = @{
            NotificationsServerIP = $regProperties.NotificationsServerIP
            WSBackupEnabled = [bool]$regProperties.WSBackupEnabled
            DiskSpaceEnabled = [bool]$regProperties.DiskSpaceEnabled
        }
    } else {
        # Default configuration
        $Script:Config = @{
            NotificationsServerIP = $null
            WSBackupEnabled = $false
            DiskSpaceEnabled = $false
        }
    }
}

function Save-Configuration {
    <#
    .SYNOPSIS
        Save configuration to registry
    #>

    Set-ItemProperty -Path $Script:RegistryPath -Name "NotificationsServerIP" -Value $Script:Config.NotificationsServerIP -Type String
    Set-ItemProperty -Path $Script:RegistryPath -Name "WSBackupEnabled" -Value ([int]$Script:Config.WSBackupEnabled) -Type DWord
    Set-ItemProperty -Path $Script:RegistryPath -Name "DiskSpaceEnabled" -Value ([int]$Script:Config.DiskSpaceEnabled) -Type DWord

    Write-ColorMessage "Configuration saved to registry" -Type Success
}

function Test-NotificationsServer {
    <#
    .SYNOPSIS
        Test connectivity to NotificationsServer
    #>
    param(
        [string]$ServerIP
    )

    try {
        $uri = "http://${ServerIP}:$Script:NotificationsServerPort/health"
        $response = Invoke-RestMethod -Uri $uri -TimeoutSec 5 -ErrorAction Stop

        if ($response.status -eq "healthy") {
            Write-ColorMessage "NotificationsServer is reachable and healthy" -Type Success
            return $true
        }
    }
    catch {
        Write-ColorMessage "Cannot reach NotificationsServer at $ServerIP : $($_.Exception.Message)" -Type Warning
        return $false
    }

    return $false
}

function Send-TestNotification {
    <#
    .SYNOPSIS
        Send a test notification to verify configuration

    .NOTES
        The Transport parameter specifies a named combination of bot + channel
        configured on the NotificationsServer (e.g., "SuccessfulBackups").
    #>
    param(
        [string]$ServerIP,
        [string]$Transport = "SuccessfulBackups"
    )

    try {
        $uri = "http://${ServerIP}:$Script:NotificationsServerPort/api/v1/notify"
        $body = @{
            type = "telegram"
            channels = @($Transport)  # API parameter name is "channels" for backward compatibility
            subject = "Test from $env:COMPUTERNAME"
            body = "VLABS Notifications configuration test`n`nServer: $env:COMPUTERNAME`nTime: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`nStatus: Configuration successful"
        } | ConvertTo-Json

        $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType "application/json" -TimeoutSec 10 -ErrorAction Stop

        Write-ColorMessage "Test notification sent successfully to '$Transport' transport" -Type Success
        return $true
    }
    catch {
        Write-ColorMessage "Failed to send test notification: $($_.Exception.Message)" -Type Error
        return $false
    }
}

# ============================================================================
# SCHEDULED TASK FUNCTIONS
# ============================================================================

function New-WSBackupNotificationTask {
    <#
    .SYNOPSIS
        Create or update Windows Server Backup notification scheduled task
    #>
    param(
        [string]$ServerIP
    )

    $taskName = "VLABS - WSBackup Notifications"

    # Check if task exists
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

    if ($existingTask) {
        Write-ColorMessage "Updating existing scheduled task '$taskName'..." -Type Info
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    } else {
        Write-ColorMessage "Creating new scheduled task '$taskName'..." -Type Info
    }

    # PowerShell script that will be executed by the scheduled task
    $scriptBlock = @'
# VLABS - Windows Server Backup Notification Script
# Auto-generated by Setup-VLABSNotifications.ps1
# DO NOT EDIT MANUALLY - Use the wizard to update configuration

$ServerIP = "SERVERIP_PLACEHOLDER"
$ServerPort = SERVERPORT_PLACEHOLDER
$NotifyUri = "http://${ServerIP}:${ServerPort}/api/v1/notify"

# Get the triggering event
$events = Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Backup'
    ID = 14
    StartTime = (Get-Date).AddMinutes(-5)
} -MaxEvents 1 -ErrorAction SilentlyContinue

if (-not $events) {
    # No recent Event 14, exit
    exit 0
}

$event = $events[0]
$backupTime = $event.TimeCreated

# Check for Event ID 4 (successful backup) in the last 10 minutes
$successEvent = Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Backup'
    ID = 4
    StartTime = (Get-Date).AddMinutes(-10)
} -MaxEvents 1 -ErrorAction SilentlyContinue

# Check for Event ID 5 (failed backup) in the last 10 minutes
$failureEvent = Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Backup'
    ID = 5
    StartTime = (Get-Date).AddMinutes(-10)
} -MaxEvents 1 -ErrorAction SilentlyContinue

# Determine backup status and select transport
if ($successEvent) {
    # Successful backup - use SuccessfulBackups transport
    $transport = "SuccessfulBackups"
    $subject = "EMOJI_CHECK Backup Successful - $env:COMPUTERNAME"
    $status = "Success"

    # Extract backup details from Event 4
    $backupDetails = $successEvent.Message

    $body = "Windows Server Backup completed successfully`n`n"
    $body += "Server: $env:COMPUTERNAME`n"
    $body += "Time: $($backupTime.ToString('yyyy-MM-dd HH:mm:ss'))`n"
    $body += "Status: $status`n`n"
    $body += "Details:`n$backupDetails"
} elseif ($failureEvent) {
    # Failed backup (Event ID 5 detected) - use FailedBackups transport
    $transport = "FailedBackups"
    $subject = "EMOJI_X Backup Failed - $env:COMPUTERNAME"
    $status = "Failed"

    # Extract detailed error information from Event 5
    $failureDetails = $failureEvent.Message
    $failureTime = $failureEvent.TimeCreated

    # Also gather additional error events for context
    $errorEvents = Get-WinEvent -FilterHashtable @{
        LogName = 'Microsoft-Windows-Backup'
        Level = 2,3  # Error and Warning
        StartTime = (Get-Date).AddMinutes(-10)
    } -MaxEvents 5 -ErrorAction SilentlyContinue

    $additionalErrors = if ($errorEvents -and $errorEvents.Count -gt 1) {
        "`n`nAdditional Error Events:`n" + (($errorEvents | Where-Object { $_.Id -ne 5 } | ForEach-Object { "$($_.TimeCreated.ToString('HH:mm:ss')) [ID:$($_.Id)] - $($_.Message)" }) -join "`n`n")
    } else {
        ""
    }

    $body = "Windows Server Backup failed`n`n"
    $body += "Server: $env:COMPUTERNAME`n"
    $body += "Failure Time: $($failureTime.ToString('yyyy-MM-dd HH:mm:ss'))`n"
    $body += "Status: $status`n`n"
    $body += "Error Details (Event ID 5):`n$failureDetails"
    $body += $additionalErrors
} else {
    # Inconclusive - Event 14 fired but no Event 4 or 5 found
    # This might happen if backup is still in progress or status not yet logged
    # Exit without notification to avoid false alerts
    exit 0
}

# Send notification using transport
try {
    $payload = @{
        type = "telegram"
        channels = @($transport)  # API parameter name is "channels" but references transport name
        subject = $subject
        body = $body
    } | ConvertTo-Json -Depth 3

    Invoke-RestMethod -Uri $NotifyUri -Method Post -Body $payload -ContentType "application/json" -TimeoutSec 10 -ErrorAction Stop | Out-Null
} catch {
    # Log error to Windows Event Log
    Write-EventLog -LogName Application -Source "WSH" -EventId 1001 -EntryType Error -Message "Failed to send backup notification: $($_.Exception.Message)" -ErrorAction SilentlyContinue
}
'@

    # Replace placeholders with actual values
    $scriptBlock = $scriptBlock -replace 'SERVERIP_PLACEHOLDER', $ServerIP
    $scriptBlock = $scriptBlock -replace 'SERVERPORT_PLACEHOLDER', $Script:NotificationsServerPort
    $scriptBlock = $scriptBlock -replace 'EMOJI_CHECK', '✅'
    $scriptBlock = $scriptBlock -replace 'EMOJI_X', '❌'

    # Save script to a file
    $scriptPath = "$env:ProgramData\VLABS\Notifications\WSBackup-Notification.ps1"
    $scriptDir = Split-Path $scriptPath -Parent

    if (-not (Test-Path $scriptDir)) {
        New-Item -Path $scriptDir -ItemType Directory -Force | Out-Null
    }

    $scriptBlock | Out-File -FilePath $scriptPath -Encoding UTF8 -Force
    Write-ColorMessage "Notification script saved to: $scriptPath" -Type Info

    # Create scheduled task trigger (Event-based)
    # Trigger on Event ID 14 from Microsoft-Windows-Backup log
    $trigger = New-ScheduledTaskTrigger -AtStartup  # Placeholder, we'll use XML to set event trigger

    # Create action
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""

    # Create principal (run as SYSTEM with highest privileges)
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    # Create settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DontStopOnIdleEnd

    # Register task
    $task = Register-ScheduledTask -TaskName $taskName -Trigger $trigger -Action $action -Principal $principal -Settings $settings -Description "Monitors Windows Server Backup events and sends Telegram notifications via VLABS NotificationsServer"

    # Now update the task with proper event trigger using XML
    $taskXml = [xml](Export-ScheduledTask -TaskName $taskName)

    # Remove existing Triggers element
    $oldTriggers = $taskXml.Task.Triggers
    if ($oldTriggers) {
        $taskXml.Task.RemoveChild($oldTriggers) | Out-Null
    }

    # Create new Triggers element
    $triggersElement = $taskXml.CreateElement("Triggers", $taskXml.Task.NamespaceURI)

    # Create event trigger XML query for Event IDs 14 and 5
    # Event 14: Backup operation completed (success or failure)
    # Event 5: Backup failed (immediate failure notification)
    $eventTriggerXml = @"
<QueryList>
  <Query Id="0" Path="Microsoft-Windows-Backup">
    <Select Path="Microsoft-Windows-Backup">*[System[(EventID=14 or EventID=5)]]</Select>
  </Query>
</QueryList>
"@

    # Create EventTrigger element
    $eventTrigger = $taskXml.CreateElement("EventTrigger", $taskXml.Task.NamespaceURI)

    # Add Subscription element
    $subscription = $taskXml.CreateElement("Subscription", $taskXml.Task.NamespaceURI)
    $subscription.InnerText = $eventTriggerXml
    $eventTrigger.AppendChild($subscription) | Out-Null

    # Add Enabled element
    $enabled = $taskXml.CreateElement("Enabled", $taskXml.Task.NamespaceURI)
    $enabled.InnerText = "true"
    $eventTrigger.AppendChild($enabled) | Out-Null

    # Append event trigger to Triggers element
    $triggersElement.AppendChild($eventTrigger) | Out-Null

    # Append Triggers element to Task
    $taskXml.Task.AppendChild($triggersElement) | Out-Null

    # Re-register task with updated XML
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Register-ScheduledTask -TaskName $taskName -Xml $taskXml.OuterXml | Out-Null

    Write-ColorMessage "Scheduled task '$taskName' configured successfully" -Type Success
    Write-ColorMessage "Task will trigger on Event ID 14 (Backup completed) and Event ID 5 (Backup failed)" -Type Info

    return $true
}

function Remove-WSBackupNotificationTask {
    <#
    .SYNOPSIS
        Remove Windows Server Backup notification scheduled task
    #>

    $taskName = "VLABS - WSBackup Notifications"
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

    if ($task) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-ColorMessage "Scheduled task '$taskName' removed" -Type Success
    } else {
        Write-ColorMessage "Scheduled task '$taskName' not found" -Type Warning
    }
}

function New-DiskSpaceNotificationTask {
    <#
    .SYNOPSIS
        Create or update Disk Space notification scheduled task
    .DESCRIPTION
        Creates a scheduled task with hybrid triggers:
        - Time-based: Runs every 6 hours
        - Event-based: Triggers on Event ID 2013 (low disk space)
        Monitors local fixed HDD/SSD drives only, excludes USB/network/optical drives.
    #>
    param(
        [string]$ServerIP
    )

    $taskName = "VLABS - Disk Space Notifications"

    # Check if task exists
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

    if ($existingTask) {
        Write-ColorMessage "Updating existing scheduled task '$taskName'..." -Type Info
    } else {
        Write-ColorMessage "Creating scheduled task '$taskName'..." -Type Info
    }

    # Generate the notification script
    $scriptBlock = @'
# VLABS Disk Space Notification Script
# Monitors local fixed drives and sends low disk space alerts

$ServerIP = "SERVERIP_PLACEHOLDER"
$ServerPort = SERVERPORT_PLACEHOLDER
$NotifyUri = "http://${ServerIP}:${ServerPort}/api/v1/notify"
$ThresholdPercent = 20
$ThrottleHours = 6
$RegistryPath = "HKLM:\SOFTWARE\VLABS\Notifications\DiskSpace"

# Ensure registry path exists
if (-not (Test-Path $RegistryPath)) {
    New-Item -Path $RegistryPath -Force | Out-Null
}

# Get all local fixed HDD/SSD drives only
# Exclude: USB, Network mapped, iSCSI, optical drives
$volumes = Get-Volume | Where-Object {
    $_.DriveType -eq 'Fixed' -and
    $_.DriveLetter -ne $null -and
    $_.FileSystemType -ne $null
}

foreach ($volume in $volumes) {
    # Get physical disk info to filter by media type
    try {
        $partition = Get-Partition -DriveLetter $volume.DriveLetter -ErrorAction SilentlyContinue
        if (-not $partition) { continue }

        $disk = Get-Disk -Number $partition.DiskNumber -ErrorAction SilentlyContinue
        if (-not $disk) { continue }

        # Skip if not a local physical disk (HDD/SSD)
        # Exclude USB (BusType = USB), iSCSI (BusType = iSCSI)
        if ($disk.BusType -match 'USB|iSCSI|Virtual') { continue }

        # Get physical disk to check media type
        $physicalDisk = Get-PhysicalDisk -DeviceNumber $disk.Number -ErrorAction SilentlyContinue
        if (-not $physicalDisk) { continue }

        # Only HDD or SSD
        if ($physicalDisk.MediaType -notmatch 'HDD|SSD') { continue }

    } catch {
        # Skip drives that don't have physical disk info
        continue
    }

    # Calculate free space percentage
    if ($volume.Size -eq 0) { continue }
    $percentFree = [math]::Round(($volume.SizeRemaining / $volume.Size) * 100, 2)

    # Check if below threshold
    if ($percentFree -lt $ThresholdPercent) {
        # Check throttling - only notify once per 6 hours per drive
        $driveLetter = $volume.DriveLetter
        $lastNotifyValue = "LastNotify_$driveLetter"
        $lastNotify = Get-ItemProperty -Path $RegistryPath -Name $lastNotifyValue -ErrorAction SilentlyContinue

        $shouldNotify = $false
        if (-not $lastNotify) {
            $shouldNotify = $true
        } else {
            $lastTime = [DateTime]::ParseExact($lastNotify.$lastNotifyValue, 'yyyy-MM-dd HH:mm:ss', $null)
            $hoursSince = ((Get-Date) - $lastTime).TotalHours
            if ($hoursSince -ge $ThrottleHours) {
                $shouldNotify = $true
            }
        }

        if ($shouldNotify) {
            # Prepare notification details
            $driveLabel = if ($volume.FileSystemLabel) { $volume.FileSystemLabel } else { "No Label" }
            $sizeGB = [math]::Round($volume.Size / 1GB, 2)
            $freeGB = [math]::Round($volume.SizeRemaining / 1GB, 2)

            $subject = "EMOJI_WARNING Low Disk Space - $driveLetter`: - $env:COMPUTERNAME"
            $body = "Low disk space detected`n`n"
            $body += "Server: $env:COMPUTERNAME`n"
            $body += "Drive: $driveLetter`:`n"
            $body += "Label: $driveLabel`n"
            $body += "Free Space: $freeGB GB / $sizeGB GB`n"
            $body += "Percent Free: $percentFree%`n"
            $body += "Threshold: $ThresholdPercent%`n"
            $body += "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

            # Send notification
            try {
                $payload = @{
                    type = "telegram"
                    channels = @("LowDiskSpace")
                    subject = $subject
                    body = $body
                } | ConvertTo-Json -Depth 3

                Invoke-RestMethod -Uri $NotifyUri -Method Post -Body $payload -ContentType "application/json" -TimeoutSec 10 -ErrorAction Stop | Out-Null

                # Update last notification time
                Set-ItemProperty -Path $RegistryPath -Name $lastNotifyValue -Value (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -Force

            } catch {
                # Log error to Windows Event Log
                Write-EventLog -LogName Application -Source "WSH" -EventId 1002 -EntryType Error -Message "Failed to send disk space notification for $driveLetter`: $($_.Exception.Message)" -ErrorAction SilentlyContinue
            }
        }
    }
}
'@

    # Replace placeholders
    $scriptBlock = $scriptBlock -replace 'SERVERIP_PLACEHOLDER', $ServerIP
    $scriptBlock = $scriptBlock -replace 'SERVERPORT_PLACEHOLDER', $Script:NotificationsServerPort
    $scriptBlock = $scriptBlock -replace 'EMOJI_WARNING', '⚠️'

    # Save script to file
    $scriptPath = "$env:ProgramData\VLABS\Notifications\DiskSpace-Notification.ps1"
    $scriptDir = Split-Path $scriptPath -Parent

    if (-not (Test-Path $scriptDir)) {
        New-Item -Path $scriptDir -ItemType Directory -Force | Out-Null
    }

    $scriptBlock | Out-File -FilePath $scriptPath -Encoding UTF8 -Force
    Write-ColorMessage "Notification script saved to: $scriptPath" -Type Info

    # Create scheduled task with hybrid triggers
    $trigger = New-ScheduledTaskTrigger -AtStartup  # Placeholder, will be replaced with XML

    # Create action
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""

    # Create principal (run as SYSTEM with highest privileges)
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    # Create settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DontStopOnIdleEnd

    # Register task
    $task = Register-ScheduledTask -TaskName $taskName -Trigger $trigger -Action $action -Principal $principal -Settings $settings -Description "Monitors disk space on local fixed drives and sends Telegram notifications via VLABS NotificationsServer"

    # Now update the task with hybrid triggers using XML
    $taskXml = [xml](Export-ScheduledTask -TaskName $taskName)

    # Remove existing Triggers element
    $oldTriggers = $taskXml.Task.Triggers
    if ($oldTriggers) {
        $taskXml.Task.RemoveChild($oldTriggers) | Out-Null
    }

    # Create new Triggers element
    $triggersElement = $taskXml.CreateElement("Triggers", $taskXml.Task.NamespaceURI)

    # TRIGGER 1: Time-based (every 6 hours)
    $calendarTrigger = $taskXml.CreateElement("CalendarTrigger", $taskXml.Task.NamespaceURI)

    $startBoundary = $taskXml.CreateElement("StartBoundary", $taskXml.Task.NamespaceURI)
    $startBoundary.InnerText = (Get-Date).ToString("yyyy-MM-dd'T'HH:mm:ss")
    $calendarTrigger.AppendChild($startBoundary) | Out-Null

    $enabled = $taskXml.CreateElement("Enabled", $taskXml.Task.NamespaceURI)
    $enabled.InnerText = "true"
    $calendarTrigger.AppendChild($enabled) | Out-Null

    $scheduleByDay = $taskXml.CreateElement("ScheduleByDay", $taskXml.Task.NamespaceURI)
    $daysInterval = $taskXml.CreateElement("DaysInterval", $taskXml.Task.NamespaceURI)
    $daysInterval.InnerText = "1"
    $scheduleByDay.AppendChild($daysInterval) | Out-Null
    $calendarTrigger.AppendChild($scheduleByDay) | Out-Null

    $repetition = $taskXml.CreateElement("Repetition", $taskXml.Task.NamespaceURI)
    $interval = $taskXml.CreateElement("Interval", $taskXml.Task.NamespaceURI)
    $interval.InnerText = "PT6H"  # Every 6 hours
    $repetition.AppendChild($interval) | Out-Null
    $stopAtDurationEnd = $taskXml.CreateElement("StopAtDurationEnd", $taskXml.Task.NamespaceURI)
    $stopAtDurationEnd.InnerText = "false"
    $repetition.AppendChild($stopAtDurationEnd) | Out-Null
    $calendarTrigger.AppendChild($repetition) | Out-Null

    $triggersElement.AppendChild($calendarTrigger) | Out-Null

    # TRIGGER 2: Event-based (Event ID 2013 - Low Disk Space)
    $eventTriggerXml = @"
<QueryList>
  <Query Id="0" Path="System">
    <Select Path="System">*[System[Provider[@Name='Srv'] and EventID=2013]]</Select>
  </Query>
</QueryList>
"@

    $eventTrigger = $taskXml.CreateElement("EventTrigger", $taskXml.Task.NamespaceURI)

    $subscription = $taskXml.CreateElement("Subscription", $taskXml.Task.NamespaceURI)
    $subscription.InnerText = $eventTriggerXml
    $eventTrigger.AppendChild($subscription) | Out-Null

    $eventEnabled = $taskXml.CreateElement("Enabled", $taskXml.Task.NamespaceURI)
    $eventEnabled.InnerText = "true"
    $eventTrigger.AppendChild($eventEnabled) | Out-Null

    $triggersElement.AppendChild($eventTrigger) | Out-Null

    # Append Triggers element to Task
    $taskXml.Task.AppendChild($triggersElement) | Out-Null

    # Re-register task with updated XML
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Register-ScheduledTask -TaskName $taskName -Xml $taskXml.OuterXml | Out-Null

    Write-ColorMessage "Scheduled task '$taskName' configured successfully" -Type Success
    Write-ColorMessage "Hybrid triggers configured:" -Type Info
    Write-ColorMessage "  - Time-based: Every 6 hours" -Type Info
    Write-ColorMessage "  - Event-based: Event ID 2013 (Srv - Low Disk Space)" -Type Info

    return $true
}

function Remove-DiskSpaceNotificationTask {
    <#
    .SYNOPSIS
        Remove Disk Space notification scheduled task
    #>

    $taskName = "VLABS - Disk Space Notifications"
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

    if ($task) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-ColorMessage "Scheduled task '$taskName' removed" -Type Success
    } else {
        Write-ColorMessage "Scheduled task '$taskName' not found" -Type Warning
    }
}

# ============================================================================
# MENU FUNCTIONS
# ============================================================================

function Show-MainMenu {
    <#
    .SYNOPSIS
        Display the main menu
    #>

    Clear-Host
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "   VLABS Notifications Configuration Wizard  " -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host ""

    if ($Script:Config.NotificationsServerIP) {
        Write-Host "Current NotificationsServer IP: " -NoNewline
        Write-Host $Script:Config.NotificationsServerIP -ForegroundColor Green
        Write-Host ""
    }

    Write-Host "Choose an option:" -ForegroundColor Yellow
    Write-Host ""

    $wsbackupStatus = if ($Script:Config.WSBackupEnabled) { "[ENABLED]" } else { "" }
    Write-Host "  1. Notify Windows Server Backup Status $wsbackupStatus" -ForegroundColor White

    $diskspaceStatus = if ($Script:Config.DiskSpaceEnabled) { "[ENABLED]" } else { "" }
    Write-Host "  2. Notify Low Disk Space Alerts $diskspaceStatus" -ForegroundColor White
    Write-Host ""
    Write-Host "  9. Uninstall - View Instructions" -ForegroundColor DarkGray
    Write-Host "  0. Update Configuration and Exit" -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "Enter choice"
    return $choice
}

function Show-UninstallInstructions {
    <#
    .SYNOPSIS
        Display uninstall instructions
    #>

    Clear-Host
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║                                                              ║" -ForegroundColor Red
    Write-Host "║  " -NoNewline -ForegroundColor Red
    Write-Host "UNINSTALL INSTRUCTIONS" -NoNewline -ForegroundColor Yellow
    Write-Host "                                       ║" -ForegroundColor Red
    Write-Host "║                                                              ║" -ForegroundColor Red
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""
    Write-ColorMessage "To uninstall VLABS Notifications:" -Type Warning
    Write-Host ""
    Write-Host "  1. Open Task Scheduler:" -ForegroundColor White
    Write-Host "     - Press " -NoNewline -ForegroundColor Gray
    Write-Host "Win + R" -NoNewline -ForegroundColor Cyan
    Write-Host ", type " -NoNewline -ForegroundColor Gray
    Write-Host "taskschd.msc" -NoNewline -ForegroundColor Cyan
    Write-Host ", press Enter" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  2. Delete all scheduled tasks starting with:" -ForegroundColor White
    Write-Host "     " -NoNewline
    Write-Host "VLABS -" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "     Current tasks:" -ForegroundColor Gray

    # List current VLABS tasks
    $vlabsTasks = Get-ScheduledTask -TaskName "VLABS*" -ErrorAction SilentlyContinue
    if ($vlabsTasks) {
        foreach ($task in $vlabsTasks) {
            Write-Host "       • " -NoNewline -ForegroundColor DarkGray
            Write-Host $task.TaskName -ForegroundColor Cyan
        }
    } else {
        Write-Host "       (No VLABS tasks currently installed)" -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "  3. (Optional) Clean up generated scripts:" -ForegroundColor White
    Write-Host "     Delete folder: " -NoNewline -ForegroundColor Gray
    Write-Host "C:\ProgramData\VLABS\Notifications\" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  4. (Optional) Remove registry configuration:" -ForegroundColor White
    Write-Host "     Delete registry key: " -NoNewline -ForegroundColor Gray
    Write-Host "HKLM:\SOFTWARE\VLABS\Notifications" -ForegroundColor Cyan
    Write-Host ""
    Write-ColorMessage "Registry configuration is harmless and may be useful if you reinstall" -Type Info
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Gray
    Write-Host ""

    Read-Host "Press Enter to return to main menu"
}

function Invoke-WSBackupConfiguration {
    <#
    .SYNOPSIS
        Configure Windows Server Backup notifications
    #>

    Write-Host ""
    Write-Host "=== Windows Server Backup Notifications ===" -ForegroundColor Cyan
    Write-Host ""

    # Get or confirm server IP
    if ($Script:Config.NotificationsServerIP) {
        Write-Host "Current NotificationsServer IP: $($Script:Config.NotificationsServerIP)" -ForegroundColor Green
        $newIP = Read-Host "Press Enter to keep current IP, or enter new IP address"

        if ($newIP -and $newIP.Trim()) {
            $Script:Config.NotificationsServerIP = $newIP.Trim()
        }
    } else {
        do {
            $newIP = Read-Host "Enter NotificationsServer IP address"
            if ($newIP -and $newIP.Trim()) {
                $Script:Config.NotificationsServerIP = $newIP.Trim()
                break
            } else {
                Write-ColorMessage "IP address is required" -Type Error
            }
        } while ($true)
    }

    # Test connectivity
    Write-Host ""
    Write-ColorMessage "Testing connection to NotificationsServer..." -Type Info
    $serverReachable = Test-NotificationsServer -ServerIP $Script:Config.NotificationsServerIP

    if (-not $serverReachable) {
        Write-Host ""
        $continue = Read-Host "Server is not reachable. Continue anyway? (y/N)"
        if ($continue -ne 'y' -and $continue -ne 'Y') {
            Write-ColorMessage "Configuration cancelled" -Type Warning
            return
        }
    }

    # Create scheduled task
    Write-Host ""
    Write-ColorMessage "Creating/updating scheduled task..." -Type Info
    $taskCreated = New-WSBackupNotificationTask -ServerIP $Script:Config.NotificationsServerIP

    if ($taskCreated) {
        $Script:Config.WSBackupEnabled = $true
        Save-Configuration

        # Offer to send test notification
        Write-Host ""
        $sendTest = Read-Host "Send test notification to verify configuration? (Y/n)"

        if ($sendTest -ne 'n' -and $sendTest -ne 'N') {
            Write-Host ""
            Write-ColorMessage "Sending test notification..." -Type Info
            Send-TestNotification -ServerIP $Script:Config.NotificationsServerIP -Transport "SuccessfulBackups"
        }

        Write-Host ""
        Write-ColorMessage "Windows Server Backup notifications enabled successfully!" -Type Success
        Write-Host ""
        Write-Host "The scheduled task will now monitor for:" -ForegroundColor Gray
        Write-Host "  - Event ID 14 (Backup operation completed)" -ForegroundColor Gray
        Write-Host "  - Event ID 5 (Backup failed)" -ForegroundColor Gray
        Write-Host "and automatically send notifications using configured transports." -ForegroundColor Gray
    } else {
        Write-ColorMessage "Failed to create scheduled task" -Type Error
    }

    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Invoke-DiskSpaceConfiguration {
    <#
    .SYNOPSIS
        Configure Disk Space notifications
    #>

    Write-Host ""
    Write-Host "=== Disk Space Notifications ===" -ForegroundColor Cyan
    Write-Host ""

    # Get or confirm server IP
    if ($Script:Config.NotificationsServerIP) {
        Write-Host "Current NotificationsServer IP: $($Script:Config.NotificationsServerIP)" -ForegroundColor Green
        $newIP = Read-Host "Press Enter to keep current IP, or enter new IP address"

        if ($newIP -and $newIP.Trim()) {
            $Script:Config.NotificationsServerIP = $newIP.Trim()
        }
    } else {
        do {
            $newIP = Read-Host "Enter NotificationsServer IP address"
            if ($newIP -and $newIP.Trim()) {
                $Script:Config.NotificationsServerIP = $newIP.Trim()
                break
            } else {
                Write-ColorMessage "IP address is required" -Type Error
            }
        } while ($true)
    }

    # Test connectivity
    Write-Host ""
    Write-ColorMessage "Testing connection to NotificationsServer..." -Type Info
    $serverReachable = Test-NotificationsServer -ServerIP $Script:Config.NotificationsServerIP

    if (-not $serverReachable) {
        Write-Host ""
        $continue = Read-Host "Server is not reachable. Continue anyway? (y/N)"
        if ($continue -ne 'y' -and $continue -ne 'Y') {
            Write-ColorMessage "Configuration cancelled" -Type Warning
            return
        }
    }

    # Create scheduled task
    Write-Host ""
    Write-ColorMessage "Creating/updating scheduled task..." -Type Info
    $taskCreated = New-DiskSpaceNotificationTask -ServerIP $Script:Config.NotificationsServerIP

    if ($taskCreated) {
        $Script:Config.DiskSpaceEnabled = $true
        Save-Configuration

        # Offer to send test notification
        Write-Host ""
        $sendTest = Read-Host "Send test notification to verify configuration? (Y/n)"

        if ($sendTest -ne 'n' -and $sendTest -ne 'N') {
            Write-Host ""
            Write-ColorMessage "Sending test notification..." -Type Info
            Send-TestNotification -ServerIP $Script:Config.NotificationsServerIP -Transport "LowDiskSpace"
        }

        Write-Host ""
        Write-ColorMessage "Disk space notifications enabled successfully!" -Type Success
        Write-Host ""
        Write-Host "The scheduled task will monitor for:" -ForegroundColor Gray
        Write-Host "  - Time-based: Every 6 hours" -ForegroundColor Gray
        Write-Host "  - Event-based: Event ID 2013 (Srv - Low Disk Space)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Configuration:" -ForegroundColor Gray
        Write-Host "  - Monitors: Local fixed HDD/SSD drives only" -ForegroundColor Gray
        Write-Host "  - Excludes: USB, network mapped, iSCSI, optical drives" -ForegroundColor Gray
        Write-Host "  - Threshold: <20% free space" -ForegroundColor Gray
        Write-Host "  - Throttling: Once per 6 hours per drive" -ForegroundColor Gray
        Write-Host "  - Transport: LowDiskSpace" -ForegroundColor Gray
    } else {
        Write-ColorMessage "Failed to create scheduled task" -Type Error
    }

    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Invoke-UpdateConfiguration {
    <#
    .SYNOPSIS
        Update global configuration (server IP, etc.)
    #>

    Write-Host ""
    Write-Host "=== Update Configuration ===" -ForegroundColor Cyan
    Write-Host ""

    if ($Script:Config.NotificationsServerIP) {
        Write-Host "Current NotificationsServer IP: $($Script:Config.NotificationsServerIP)" -ForegroundColor Green
        $newIP = Read-Host "Enter new IP address (or press Enter to keep current)"

        if ($newIP -and $newIP.Trim()) {
            $oldIP = $Script:Config.NotificationsServerIP
            $Script:Config.NotificationsServerIP = $newIP.Trim()

            # Test new IP
            Write-Host ""
            Write-ColorMessage "Testing connection to new IP..." -Type Info
            $serverReachable = Test-NotificationsServer -ServerIP $Script:Config.NotificationsServerIP

            if (-not $serverReachable) {
                $rollback = Read-Host "New IP is not reachable. Keep it anyway? (y/N)"
                if ($rollback -ne 'y' -and $rollback -ne 'Y') {
                    $Script:Config.NotificationsServerIP = $oldIP
                    Write-ColorMessage "Reverted to previous IP" -Type Warning
                    Write-Host ""
                    Read-Host "Press Enter to continue"
                    return
                }
            }

            Save-Configuration

            # Update all enabled scheduled tasks
            Write-Host ""
            Write-ColorMessage "Updating scheduled tasks with new IP..." -Type Info

            if ($Script:Config.WSBackupEnabled) {
                New-WSBackupNotificationTask -ServerIP $Script:Config.NotificationsServerIP | Out-Null
            }

            Write-ColorMessage "Configuration updated successfully!" -Type Success
        } else {
            Write-ColorMessage "No changes made" -Type Info
        }
    } else {
        $newIP = Read-Host "Enter NotificationsServer IP address"

        if ($newIP -and $newIP.Trim()) {
            $Script:Config.NotificationsServerIP = $newIP.Trim()
            Save-Configuration
            Write-ColorMessage "IP address saved" -Type Success
        } else {
            Write-ColorMessage "No IP address provided" -Type Warning
        }
    }

    Write-Host ""
    Read-Host "Press Enter to continue"
}

# ============================================================================
# MAIN PROGRAM
# ============================================================================

function Main {
    <#
    .SYNOPSIS
        Main program entry point
    #>

    # Check for admin rights (already enforced by #Requires, but good practice)
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-ColorMessage "This script requires Administrator privileges" -Type Error
        Write-ColorMessage "Please run PowerShell as Administrator and try again" -Type Warning
        exit 1
    }

    # Check for updates
    Test-GitHubVersion

    # Load configuration
    Initialize-Configuration

    # Main menu loop
    do {
        $choice = Show-MainMenu

        switch ($choice) {
            '1' {
                Invoke-WSBackupConfiguration
            }
            '2' {
                Invoke-DiskSpaceConfiguration
            }
            '9' {
                Show-UninstallInstructions
            }
            '0' {
                Invoke-UpdateConfiguration
                break
            }
            default {
                Write-ColorMessage "Invalid choice. Please try again." -Type Warning
                Start-Sleep -Seconds 1
            }
        }

    } while ($choice -ne '0')

    # Exit
    Write-Host ""
    Write-ColorMessage "Configuration wizard completed" -Type Success
    Write-Host ""
}

# Run main program
Main
