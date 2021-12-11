param([string]$psProfileDir)

. $(Join-Path $PSScriptRoot "SandboxSettings.ps1")

<#
.SYNOPSIS
 If any packages have been passed into the settings file, then this function will install them using chocolatey.
#>
function Install-Chocolatey($settings) {
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; 
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

    foreach ($package in $settings.ChocoPackages) {
        if ([String]::IsNullOrWhiteSpace($package.params)) {
            choco install $package.command -y
        } else {
            choco install $package.command -y --params=$($package.params)
        }
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
Start-Job -FilePath $(Join-Path $PSScriptRoot "Set-SandboxDesktop.ps1")

function Copy-PSProfile {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$ProfilePath
    )

    $profileFile = $(Join-Path $ProfilePath "Microsoft.PowerShell_profile.ps1")

    if (Test-Path $profileFile) {
        New-Item $PROFILE -Force
        Copy-Item -Path $profileFile -Destination $PROFILE
    }
}

Copy-PSProfile -ProfilePath $psProfileDir

# Wait for everything to finish
Get-Job | Wait-Job

$settings = [SandboxSettings]::new((Get-Content -Raw $(Join-Path $PSScriptRoot "sandboxSettings.json") | Out-String | ConvertFrom-Json))

if ($settings.InstallChocolatey) {
    Install-Chocolatey($settings)
}

if (-Not [String]::IsNullOrWhiteSpace($settings.LaunchScript)) {
    . (Join-Path $PSScriptRoot $settings.LaunchScript)
}

# Sandbox Configuration Complete Toast Notification
$params = @{
    Text    = "Windows Sandbox configuration is complete."
    Header  = $(New-BTHeader -Id 1 -Title "Sandbox Complete")
    Applogo = $(Join-Path $PSScriptRoot "ToastIcon.jpg")
}

New-BurntToastNotification @params