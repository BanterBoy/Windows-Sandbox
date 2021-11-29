Enable-PSRemoting -Force -SkipNetworkProfileCheck
Install-PackageProvider -Name nuget -Force -ForceBootstrap
Update-Module PackageManagement,PowerShellGet -Force

#run updates and installs in the background
Start-Job { Install-Module PSReleaseTools -Force; Install-PowerShell -Mode Quiet -EnableRemoting -EnableContextMenu -EnableRunContext }
Start-Job { Install-Module WTToolbox -Force; Install-WTRelease }
Start-Job { Install-Module BurntToast -Force }
Start-Job -FilePath C:\GitRepos\Windows-Sandbox\WSBshare\Set-SandboxDesktop.ps1
Start-Job -FilePath C:\GitRepos\Windows-Sandbox\WSBshare\Install-VSCodeSandbox.ps1

# Wait for everything to finish
Get-Job | Wait-Job

# Sandbox Configuration Complete Toast Notification
$params = @{
    Text = "Windows Sandbox configuration is complete."
    Header = $(New-BTHeader -Id 1 -Title "Sandbox Complete")
    Applogo = "C:\GitRepos\Windows-Sandbox\WSBshare\ToastIcon.jpg"
}
New-BurntToastNotification @params
