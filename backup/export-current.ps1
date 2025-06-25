# Enhanced System Configuration Backup Script
param(
    [string]$BackupRoot = "backup",
    [switch]$Compress,
    [switch]$Verbose
)

# Function to safely copy files with error handling
function Copy-FileIfExists {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Description
    )
    
    if (Test-Path $Source) {
        try {
            Copy-Item $Source $Destination -Force
            Write-Host "✓ Backed up $Description" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to backup $Description`: $_"
        }
    }
    else {
        Write-Host "⚠ $Description not found, skipping..." -ForegroundColor Yellow
    }
}

# Function to run command with error handling
function Invoke-SafeCommand {
    param(
        [string]$Command,
        [string]$Description
    )
    
    try {
        Write-Host "Exporting $Description..." -ForegroundColor Cyan
        Invoke-Expression $Command
        Write-Host "✓ $Description exported successfully" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to export $Description`: $_"
    }
}

Write-Host "🔄 Starting system configuration backup..." -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

# Create backup directory with timestamp
$timestamp = Get-Date -Format 'yyyy-MM-dd-HHmmss'
$backupDir = Join-Path $BackupRoot $timestamp
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

Write-Host "📁 Backup directory: $backupDir" -ForegroundColor Yellow

# Export package managers
Write-Host "`n📦 Exporting package managers..." -ForegroundColor Magenta

# Winget
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Invoke-SafeCommand "winget export -o `"$backupDir/winget-export.json`"" "Winget packages"
} else {
    Write-Host "⚠ Winget not found, skipping..." -ForegroundColor Yellow
}

# Scoop
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    Invoke-SafeCommand "scoop export > `"$backupDir/scoop-export.json`"" "Scoop packages"
} else {
    Write-Host "⚠ Scoop not found, skipping..." -ForegroundColor Yellow
}

# Chocolatey
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Invoke-SafeCommand "choco list --local-only > `"$backupDir/choco-export.txt`"" "Chocolatey packages"
} else {
    Write-Host "⚠ Chocolatey not found, skipping..." -ForegroundColor Yellow
}

# PowerShell modules
Write-Host "`n🔧 Exporting PowerShell modules..." -ForegroundColor Magenta
try {
    Get-InstalledModule | Select-Object Name, Version | Export-Csv "$backupDir/powershell-modules.csv" -NoTypeInformation
    Write-Host "✓ PowerShell modules exported" -ForegroundColor Green
}
catch {
    Write-Warning "Failed to export PowerShell modules: $_"
}

# Configuration files
Write-Host "`n⚙️ Backing up configuration files..." -ForegroundColor Magenta

# PowerShell profile
Copy-FileIfExists $PROFILE "$backupDir/PowerShell_profile.ps1" "PowerShell profile"

# Alternative Terminal locations (including Windows Terminal Preview)
$terminalLocations = @(
    "$env:LOCALAPPDATA/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json",
    "$env:LOCALAPPDATA/Packages/Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe/LocalState/settings.json"
)

$terminalFound = $false
foreach ($location in $terminalLocations) {
    if (Test-Path $location) {
        Copy-FileIfExists $location "$backupDir/terminal-settings.json" "Windows Terminal settings"
        $terminalFound = $true
        break
    }
}

if (-not $terminalFound) {
    Write-Host "⚠ Windows Terminal settings not found, skipping..." -ForegroundColor Yellow
}

# VS Code settings and extensions
$vscodeSettings = "$env:APPDATA/Code/User/settings.json"
$vscodeKeybindings = "$env:APPDATA/Code/User/keybindings.json"
Copy-FileIfExists $vscodeSettings "$backupDir/vscode-settings.json" "VS Code settings"
Copy-FileIfExists $vscodeKeybindings "$backupDir/vscode-keybindings.json" "VS Code keybindings"

# Export VS Code extensions
if (Get-Command code -ErrorAction SilentlyContinue) {
    Invoke-SafeCommand "code --list-extensions > `"$backupDir/vscode-extensions.txt`"" "VS Code extensions"
} else {
    Write-Host "⚠ VS Code CLI not found, skipping extensions..." -ForegroundColor Yellow
}

# Git configuration
$gitConfig = "$env:USERPROFILE/.gitconfig"
Copy-FileIfExists $gitConfig "$backupDir/gitconfig" "Git configuration"

# SSH keys (public keys only for security)
$sshDir = "$env:USERPROFILE/.ssh"
if (Test-Path $sshDir) {
    $sshBackupDir = "$backupDir/ssh"
    New-Item -ItemType Directory -Path $sshBackupDir -Force | Out-Null
    Get-ChildItem "$sshDir/*.pub" -ErrorAction SilentlyContinue | Copy-Item -Destination $sshBackupDir
    Copy-FileIfExists "$sshDir/config" "$sshBackupDir/config" "SSH config"
    Write-Host "✓ SSH public keys and config backed up" -ForegroundColor Green
}

# Windows features (with elevation check)
Write-Host "`n🪟 Exporting Windows features..." -ForegroundColor Magenta
if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    try {
        Get-WindowsOptionalFeature -Online | Where-Object State -eq Enabled | 
            Select-Object FeatureName | Export-Csv "$backupDir/windows-features.csv" -NoTypeInformation
        Write-Host "✓ Windows optional features exported" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to export Windows features: $_"
    }
} else {
    Write-Host "⚠ Windows features export requires admin privileges, skipping..." -ForegroundColor Yellow
    Write-Host "  💡 Run as administrator to include Windows features" -ForegroundColor Cyan
}

# Create restore instructions
$restoreInstructions = @"
# System Configuration Restore Instructions
Backup created: $(Get-Date)

## Package Managers
- Winget: ``winget import -i winget-export.json``
- Scoop: ``scoop import scoop-export.json``
- Chocolatey: Install packages listed in choco-export.txt manually

## PowerShell Modules
``Import-Csv powershell-modules.csv | ForEach-Object { Install-Module `$_.Name -RequiredVersion `$_.Version }``

## VS Code Extensions
``Get-Content vscode-extensions.txt | ForEach-Object { code --install-extension `$_ }``

## Configuration Files
- Copy PowerShell_profile.ps1 to: ``$PROFILE``
- Copy terminal-settings.json to: ``$env:LOCALAPPDATA/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json``
- Copy vscode-settings.json to: ``$env:APPDATA/Code/User/settings.json``
- Copy gitconfig to: ``$env:USERPROFILE/.gitconfig``
"@

$restoreInstructions | Out-File "$backupDir/RESTORE_INSTRUCTIONS.md" -Encoding UTF8

# Optional compression
if ($Compress) {
    Write-Host "`n📦 Compressing backup..." -ForegroundColor Magenta
    $zipPath = "$BackupRoot/backup-$timestamp.zip"
    Compress-Archive -Path $backupDir -DestinationPath $zipPath -Force
    Remove-Item $backupDir -Recurse -Force
    Write-Host "✓ Backup compressed to: $zipPath" -ForegroundColor Green
}

Write-Host "`n🎉 Backup completed successfully!" -ForegroundColor Green
Write-Host "📍 Location: $(if ($Compress) { $zipPath } else { $backupDir })" -ForegroundColor Yellow
Write-Host "📋 Check RESTORE_INSTRUCTIONS.md for restoration steps" -ForegroundColor Cyan