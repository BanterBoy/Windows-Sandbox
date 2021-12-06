param([string]$repoPath, [string]$psProfileDir)

. $(Join-Path $repoPath "Windows-Sandbox\WSBshare\SandboxSettings.ps1")

function Install-Chocolatey($settings) {
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; 
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

    # chocolatey GUI
    if ($settings.ChocoGui) {
        choco install chocolateygui -y
    }

    # windows terminal
    if ($settings.WindowsTerminal) {
        choco install microsoft-windows-terminal -y
    }

    # vs code
    if ($settings.Vscode) {
        choco install vscode -y
    }

    # chrome
    if ($settings.Chrome) {
        choco install googlechrome -y
    }

    # firefox
    if ($settings.Firefox) {
        choco install firefox -y
    }

    # edge
    if ($settings.Edge) {
        choco install microsoft-edge -y
    }

    # notepad++
    if ($settings.Notepadplusplus) {
        choco install notepadplusplus.install -y
    }

    # 7zip
    if ($settings.SevenZip) {
        choco install 7zip.install -y
    }

    # git (https://community.chocolatey.org/packages/git.install)
    if ($settings.Git) {
        choco install git.install -y --params="'/WindowsTerminal /WindowsTerminalProfile /Editor:VisualStudioCode'"
    }

    # putty
    if ($settings.Putty) {
        choco install putty.install -y
    }
}

function Initialise-FileSystem() {
    mkdir c:\OutPutDir
}

Initialise-FileSystem

Enable-PSRemoting -Force -SkipNetworkProfileCheck
Install-PackageProvider -Name nuget -Force -ForceBootstrap
Install-Module PackageManagement, PowerShellGet -Force
# Update-Module PackageManagement,PowerShellGet -Force

# run updates and installs in the background
Start-Job { Install-Module PSReleaseTools -Force; Install-PowerShell -Mode Quiet -EnableRemoting -EnableContextMenu -EnableRunContext }
Start-Job { Install-Module WTToolbox -Force; Install-WTRelease }
Start-Job { Install-Module BurntToast -Force }

function Copy-PSProfile {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $ProfilePath = $(Join-Path $psProfileDir "Microsoft.PowerShell_profile.ps1")
    )
    if (Test-Path $ProfilePath) {
        New-Item $PROFILE -Force
        Copy-Item -Path $ProfilePath -Destination $PROFILE
    }
}
Copy-PSProfile

# Wait for everything to finish
Get-Job | Wait-Job

$settings = [SandboxSettings]::new((Get-Content -Raw $(Join-Path $repoPath "Windows-Sandbox\WSBShare\sandboxSettings.json") | Out-String | ConvertFrom-Json))

if ($settings.InstallChocolatey) {
    Install-Chocolatey($settings)
}

# Sandbox Configuration Complete Toast Notification
$params = @{
    Text    = "Windows Sandbox configuration is complete."
    Header  = $(New-BTHeader -Id 1 -Title "Sandbox Complete")
    Applogo = "$repoPath\Windows-Sandbox\WSBshare\ToastIcon.jpg"
}

New-BurntToastNotification @params