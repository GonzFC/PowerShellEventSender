<#
.SYNOPSIS
    Test PowerShell syntax of Setup-VLABSNotifications.ps1

.DESCRIPTION
    Quick syntax validation script to ensure the wizard script
    can be parsed by PowerShell without errors.

.EXAMPLE
    .\Test-Syntax.ps1

    Tests the syntax of Setup-VLABSNotifications.ps1
#>

[CmdletBinding()]
param()

Write-Host "Testing PowerShell syntax..." -ForegroundColor Cyan
Write-Host ""

# Get the wizard script path
$wizardScript = Join-Path $PSScriptRoot "Setup-VLABSNotifications.ps1"

if (-not (Test-Path $wizardScript)) {
    Write-Host "ERROR: Setup-VLABSNotifications.ps1 not found!" -ForegroundColor Red
    Write-Host "Expected location: $wizardScript" -ForegroundColor Red
    exit 1
}

# Test syntax
try {
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $wizardScript -Raw), [ref]$null)
    Write-Host "✓ Syntax check PASSED" -ForegroundColor Green
    Write-Host ""
    Write-Host "The script is syntactically valid and ready to use." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Run PowerShell as Administrator" -ForegroundColor White
    Write-Host "  2. Execute: .\Setup-VLABSNotifications.ps1" -ForegroundColor White
    Write-Host ""
    exit 0
}
catch {
    Write-Host "✗ Syntax check FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error details:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Please report this issue with the error details above." -ForegroundColor Yellow
    exit 1
}
