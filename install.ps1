# Windows Fresh Install Script
Write-Host "Starting fresh Windows setup..." -ForegroundColor Green

# Enable execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Install package managers
Write-Host "Installing package managers..." -ForegroundColor Yellow

# Install Scoop (portable apps)
if (!(Get-Command scoop -ErrorAction SilentlyContinue)) {
    Invoke-RestMethod get.scoop.sh | Invoke-Expression
    #scoop bucket add extras
    #scoop bucket add games
}

# Install Chocolatey (system packages)
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# Install apps from lists
Write-Host "Installing applications..." -ForegroundColor Yellow

# Winget apps (built into Windows)
Get-Content "scripts/winget-apps.txt" | ForEach-Object {
    if ($_ -and !$_.StartsWith("#")) {
        winget install $_ --accept-source-agreements --accept-package-agreements
    }
}

# Chocolatey apps
Get-Content "scripts/choco-apps.txt" | ForEach-Object {
    if ($_ -and !$_.StartsWith("#")) {
        choco install $_ -y
    }
}

# Scoop apps (portable)
Get-Content "scripts/scoop-apps.txt" | ForEach-Object {
    if ($_ -and !$_.StartsWith("#")) {
        scoop install $_
    }
}

# Apply registry tweaks
Write-Host "Applying registry tweaks..." -ForegroundColor Yellow
Get-ChildItem "configs/registry/*.reg" | ForEach-Object {
    reg import $_.FullName
}

# Copy config files
Write-Host "Copying configurations..." -ForegroundColor Yellow

# PowerShell profile
$profileDir = Split-Path $PROFILE -Parent
if (!(Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force }
Copy-Item "configs/powershell/Microsoft.PowerShell_profile.ps1" $PROFILE -Force

# Windows Terminal
$terminalDir = "$env:LOCALAPPDATA/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState"
if (Test-Path $terminalDir) {
    Copy-Item "configs/windows-terminal/settings.json" "$terminalDir/settings.json" -Force
}

# VS Code settings
$vscodeDir = "$env:APPDATA/Code/User"
if (Test-Path $vscodeDir) {
    Copy-Item "configs/vscode/settings.json" "$vscodeDir/settings.json" -Force
}

# Run post-install script
Write-Host "Running post-install tweaks..." -ForegroundColor Yellow
& "./scripts/post-install.ps1"

Write-Host "Setup complete! Restart required." -ForegroundColor Green