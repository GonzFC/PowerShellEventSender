# Release Guide - PowerShell Event Sender

**One-Liner Deployment Model**

This project uses GitHub Releases to enable one-liner PowerShell deployment, similar to Chris Titus Tech's Windows Utility.

---

## Overview

Users install/update with a single command:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iwr -useb https://raw.githubusercontent.com/GonzFC/PowerShellEventSender/main/Install-Run-VLABS_NotificationsClient.ps1 | iex
```

This command:
- Downloads the script from the latest GitHub release
- Executes it immediately using `Invoke-Expression` (iex)
- Always gets the most current version
- Checks for updates automatically on each run

---

## Release Workflow

### Prerequisites

1. **GitHub Repository**: `https://github.com/GonzFC/PowerShellEventSender`
2. **Repository Access**: Push/release permissions
3. **Git Configured**: Local repository synced with remote

### Creating a New Release

#### Step 1: Update Version Number

Update the version in the main script:

```powershell
# In Install-Run-VLABS_NotificationsClient.ps1, line ~63:
$Script:Version = "0.3.0"  # Change this
```

Update the version in the script header:

```powershell
# In Install-Run-VLABS_NotificationsClient.ps1, line ~36:
.NOTES
    Version: 0.3.0  # Change this
```

#### Step 2: Update CHANGELOG.md

Add a new version entry:

```markdown
## [0.3.0] - 2025-11-16

### Added
- One-liner GitHub deployment support
- Automatic version checking via GitHub API
- Uninstall instructions in menu (option 9)

### Changed
- Renamed script to Install-Run-VLABS_NotificationsClient.ps1
- Updated deployment model to GitHub Releases
- README updated with one-liner installation

### Technical Details
- Uses GitHub API to check for updates on every run
- Downloads from /releases/latest/download/ endpoint
- Version check function: Test-GitHubVersion
```

#### Step 3: Commit Changes

```bash
cd /Users/gfernandez/NotificationsServer/PowerShellEventSender

# Stage changes
git add Install-Run-VLABS_NotificationsClient.ps1 CHANGELOG.md README.md AIQD_Methodology.md

# Commit with version tag
git commit -m "feat: Add one-liner GitHub deployment (v0.3.0)

[AIQD] Implement one-liner installation like Chris Titus Tech

ACKNOWLEDGE:
- Transform deployment from download-first to web-hosted one-liner
- Enable direct execution via GitHub Releases
- Maintain all existing functionality

FEATURES:
- One-liner command: irm ... | iex
- Automatic version checking
- Uninstall instructions menu
- Updated documentation

FILES:
- Renamed: Setup-VLABSNotifications.ps1 → Install-Run-VLABS_NotificationsClient.ps1
- Added: Test-GitHubVersion function
- Added: Show-UninstallInstructions function
- Added: AIQD_Methodology.md
- Added: RELEASE_GUIDE.md
- Updated: README.md (Quick Start section)
- Updated: CHANGELOG.md (v0.3.0 entry)

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

# Push to GitHub
git push origin main
```

#### Step 4: Create GitHub Release via Web Interface

1. **Navigate to Releases**:
   - Go to: `https://github.com/GonzFC/PowerShellEventSender/releases`
   - Click "Draft a new release"

2. **Tag the Release**:
   - Click "Choose a tag"
   - Type: `v0.3.0` (must start with 'v')
   - Select "Create new tag: v0.3.0 on publish"

3. **Release Title**:
   - Title: `v0.3.0 - One-Liner GitHub Deployment`

4. **Release Description**:
   ```markdown
   ## 🚀 One-Liner Installation

   Install or update with a single PowerShell command:

   \`\`\`powershell
   [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iwr -useb https://raw.githubusercontent.com/GonzFC/PowerShellEventSender/main/Install-Run-VLABS_NotificationsClient.ps1 | iex
   \`\`\`

   ## ✨ What's New in v0.3.0

   ### Added
   - **One-liner deployment** - No manual downloads required
   - **Automatic version checking** - Notifies when updates available
   - **Uninstall instructions** - Menu option 9 shows removal steps
   - **AIQD Methodology** - Structured development approach documented

   ### Changed
   - **Script renamed** to `Install-Run-VLABS_NotificationsClient.ps1` (more descriptive)
   - **Deployment model** now uses GitHub Releases (like Chris Titus Tech)
   - **README updated** with prominent one-liner instructions
   - **Version tracking** built into script

   ### Features
   - ✅ Windows Server Backup monitoring (Event IDs 14, 5, 4)
   - ✅ Disk Space monitoring (hybrid triggers: time + event)
   - ✅ Transports integration with NotificationsServer
   - ✅ Interactive wizard with color-coded messages
   - ✅ Registry-based configuration
   - ✅ Test notifications

   ## 📋 Requirements

   - Windows Server 2012 R2+ or Windows 10/11
   - PowerShell 5.1+
   - Administrator privileges
   - NotificationsServer running on your LAN

   ## 📖 Documentation

   - [README.md](https://github.com/GonzFC/PowerShellEventSender/blob/main/README.md) - Quick start and features
   - [ARCHITECTURE.md](https://github.com/GonzFC/PowerShellEventSender/blob/main/ARCHITECTURE.md) - Technical details
   - [CHANGELOG.md](https://github.com/GonzFC/PowerShellEventSender/blob/main/CHANGELOG.md) - Full version history

   ## 🔒 Security Note

   This one-liner downloads and executes code from GitHub. To inspect before running:

   \`\`\`powershell
   $script = irm https://github.com/GonzFC/PowerShellEventSender/releases/latest/download/Install-Run-VLABS_NotificationsClient.ps1
   $script | Out-File "$env:TEMP\\VLABS-Install.ps1"
   notepad "$env:TEMP\\VLABS-Install.ps1"
   # Run after inspection
   \`\`\`

   **Full Changelog**: https://github.com/GonzFC/PowerShellEventSender/blob/main/CHANGELOG.md
   ```

5. **Attach Script File**:
   - Scroll to "Attach binaries" section
   - Drag and drop or click to upload: `Install-Run-VLABS_NotificationsClient.ps1`
   - This creates the `/releases/latest/download/Install-Run-VLABS_NotificationsClient.ps1` endpoint

6. **Publish**:
   - Click "Publish release"
   - GitHub automatically makes this the "latest" release
   - The download URL is now active

---

## Verifying the Release

After publishing, test the one-liner:

```powershell
# Test in PowerShell (as Administrator)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iwr -useb https://raw.githubusercontent.com/GonzFC/PowerShellEventSender/main/Install-Run-VLABS_NotificationsClient.ps1 | iex
```

**Expected Behavior:**
1. Script downloads and executes
2. Version check runs: "You are running the latest version (v0.3.0)"
3. Wizard displays menu
4. All features work normally

---

## Alternative: GitHub CLI Method

If you have `gh` (GitHub CLI) installed:

```bash
# Create release and upload file
gh release create v0.3.0 \
    --title "v0.3.0 - One-Liner GitHub Deployment" \
    --notes "See CHANGELOG.md for details" \
    Install-Run-VLABS_NotificationsClient.ps1
```

This is faster but requires `gh` CLI tool installed.

---

## Version Numbering

**Semantic Versioning**: `MAJOR.MINOR.PATCH`

- **MAJOR** (1.0.0): Breaking changes, major redesign
- **MINOR** (0.3.0): New features, backward compatible
- **PATCH** (0.3.1): Bug fixes, documentation

**Current Version**: v0.3.0

**Next Planned Versions**:
- `v0.3.1` - Bug fixes, documentation improvements
- `v0.4.0` - Windows Update monitoring
- `v0.5.0` - Service status monitoring
- `v1.0.0` - Production release with all planned features

---

## GitHub Release URL Structure

Once published, these URLs become available:

**Latest Release Script:**
```
https://github.com/GonzFC/PowerShellEventSender/releases/latest/download/Install-Run-VLABS_NotificationsClient.ps1
```

**Specific Version:**
```
https://github.com/GonzFC/PowerShellEventSender/releases/download/v0.3.0/Install-Run-VLABS_NotificationsClient.ps1
```

**Release Page:**
```
https://github.com/GonzFC/PowerShellEventSender/releases
```

**Release API (for version checking):**
```
https://api.github.com/repos/GonzFC/PowerShellEventSender/releases/latest
```

The script uses this API endpoint to check for updates.

---

## Troubleshooting

### Release Not Found (404)

**Problem**: `irm` returns 404 error

**Solutions**:
1. Ensure release is published (not draft)
2. Ensure file was attached to release
3. Check filename matches exactly: `Install-Run-VLABS_NotificationsClient.ps1`
4. Wait 1-2 minutes for GitHub CDN to propagate

### Version Check Fails

**Problem**: Script can't check for updates

**Cause**: GitHub API unreachable or rate limited

**Solution**: Non-critical, script continues with warning message

### Old Version Downloaded

**Problem**: `/latest/download/` gives old version

**Cause**: GitHub caching

**Solutions**:
1. Use specific version URL temporarily
2. Wait 5-10 minutes for cache to clear
3. Create new release if needed

---

## Best Practices

### Before Each Release:

✅ **Test locally** - Run script and verify all features
✅ **Update version** - Script header and `$Script:Version`
✅ **Update CHANGELOG** - Document all changes
✅ **Git commit** - With descriptive AIQD-formatted message
✅ **Git push** - Ensure remote is up to date
✅ **Create tag** - Use `v` prefix (v0.3.0, not 0.3.0)
✅ **Upload file** - Attach script to release
✅ **Test one-liner** - Verify download and execution work

### After Release:

✅ **Test installation** - Run one-liner on test machine
✅ **Verify version** - Check version displayed is correct
✅ **Check GitHub API** - Ensure version check works
✅ **Update documentation** - If needed
✅ **Announce** - Notify users of update (if applicable)

---

## Security Considerations

### Code Signing (Future Enhancement)

Currently, the script is **not code-signed**.

**Pros of signing**:
- Increased trust
- Better compatibility with strict execution policies
- Professional appearance

**Cons of signing**:
- Cost (~$100-300/year for certificate)
- Annual renewal required
- Setup complexity

**Current approach**: Rely on GitHub HTTPS + repository transparency

**Future**: Consider signing for v1.0.0 release

### Execution Policy

Users may need to adjust execution policy:

```powershell
# Check current policy
Get-ExecutionPolicy

# Common settings:
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser  # Recommended
Set-ExecutionPolicy Bypass -Scope Process            # Temporary, for one session
```

**Documented in README** - Users are informed

---

## Changelog Entry Template

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New feature 1
- New feature 2

### Changed
- Changed behavior 1
- Changed behavior 2

### Fixed
- Bug fix 1
- Bug fix 2

### Removed
- Deprecated feature 1

### Security
- Security improvement 1

### Technical Details
- Implementation detail 1
- Implementation detail 2
```

---

## Quick Release Checklist

```
[ ] Update $Script:Version in script
[ ] Update .NOTES version in script header
[ ] Update CHANGELOG.md with new version
[ ] Test script locally
[ ] Git commit with AIQD format
[ ] Git push to main
[ ] Create GitHub release (tag vX.Y.Z)
[ ] Attach Install-Run-VLABS_NotificationsClient.ps1
[ ] Publish release
[ ] Test one-liner installation
[ ] Verify version check works
```

---

## Related Documentation

- [AIQD_Methodology.md](AIQD_Methodology.md) - Development methodology
- [CHANGELOG.md](CHANGELOG.md) - Version history
- [README.md](README.md) - User documentation
- [ARCHITECTURE.md](ARCHITECTURE.md) - Technical details

---

**Last Updated**: November 16, 2025
**Current Version**: v0.3.0
**Release Model**: GitHub Releases with `/latest/download/` endpoint
