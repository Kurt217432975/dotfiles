# System Configuration Restore Instructions
Backup created: 06/25/2025 15:08:54

## Package Managers
- Winget: `winget import -i winget-export.json`
- Scoop: `scoop import scoop-export.json`
- Chocolatey: Install packages listed in choco-export.txt manually

## PowerShell Modules
`Import-Csv powershell-modules.csv | ForEach-Object { Install-Module $_.Name -RequiredVersion $_.Version }`

## VS Code Extensions
`Get-Content vscode-extensions.txt | ForEach-Object { code --install-extension $_ }`

## Configuration Files
- Copy PowerShell_profile.ps1 to: `C:\Users\Kury\Documents\PowerShell\Microsoft.VSCode_profile.ps1`
- Copy terminal-settings.json to: `C:\Users\Kury\AppData\Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json`
- Copy vscode-settings.json to: `C:\Users\Kury\AppData\Roaming/Code/User/settings.json`
- Copy gitconfig to: `C:\Users\Kury/.gitconfig`
