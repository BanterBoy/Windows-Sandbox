param([string]$repoPath)

mkdir c:\OutPutDir

Enable-PSRemoting -Force -SkipNetworkProfileCheck
Install-PackageProvider -Name nuget -Force -ForceBootstrap
Install-Module PackageManagement, PowerShellGet -Force
# Update-Module PackageManagement,PowerShellGet -Force

#run updates and installs in the background
Start-Job { Install-Module PSReleaseTools -Force; Install-PowerShell -Mode Quiet -EnableRemoting -EnableContextMenu -EnableRunContext }
Start-Job { Install-Module WTToolbox -Force; Install-WTRelease }
Start-Job { Install-Module BurntToast -Force }
Start-Job -FilePath "$repoPath\Windows-Sandbox\WSBshare\Set-SandboxDesktop.ps1" -ArgumentList $repoPath
Start-Job -FilePath "$repoPath\Windows-Sandbox\WSBshare\Install-VSCodeSandbox.ps1" -ArgumentList $repoPath

function Copy-PSProfile {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $ProfilePath = "C:\GitRepos\ProfileFunctions\Microsoft.PowerShell_profile.ps1"
    )
    if (Test-Path $ProfilePath) {
        New-Item $PROFILE -Force
        Copy-Item -Path $ProfilePath -Destination $PROFILE
    }
}
Copy-PSProfile

# Wait for everything to finish
Get-Job | Wait-Job

# Sandbox Configuration Complete Toast Notification
$params = @{
    Text    = "Windows Sandbox configuration is complete."
    Header  = $(New-BTHeader -Id 1 -Title "Sandbox Complete")
    Applogo = "$repoPath\Windows-Sandbox\WSBshare\ToastIcon.jpg"
}
New-BurntToastNotification @params
