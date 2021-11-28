Enable-PSRemoting -force -SkipNetworkProfileCheck

Install-PackageProvider -Name nuget -Force -ForceBootstrap -Scope AllUsers
Update-Module PackageManagement,PowerShellGet -Force

#run updates and installs in the background
Start-Job {Install-Module PSScriptTools,PSTeachingTools -Force}
Start-Job {Install-Module PSReleaseTools -Force; Install-PowerShell -Mode Quiet -EnableRemoting -EnableContextMenu}
Start-Job {Install-Module WTToolbox -Force; Install-WTRelease}
Start-Job -FilePath C:\GitRepos\Windows-Sandbox\WSBshare\Set-SandboxDesktop.ps1
Start-Job -FilePath C:\GitRepos\Windows-Sandbox\WSBshare\Install-VSCodeSandbox.ps1

#wait for everything to finish
Get-Job | Wait-Job