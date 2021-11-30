# Set-SandboxDesktop.ps1

param([string]$repoPath)

function Update-Wallpaper {
  [cmdletbinding(SupportsShouldProcess)]
    Param(
        [Parameter(Position = 0,HelpMessage="The path to the wallpaper file.")]
        [alias("wallpaper")]
        [ValidateScript({Test-Path $_})]
        [string]$Path = $(Get-ItemPropertyValue -path 'hkcu:\Control Panel\Desktop\' -Name Wallpaper)
    )

    Add-Type @"

    using System;
    using System.Runtime.InteropServices;
    using Microsoft.Win32;

    namespace Wallpaper
    {
        public class UpdateImage
        {
            [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]

            private static extern int SystemParametersInfo (int uAction, int uParam, string lpvParam, int fuWinIni);

            public static void Refresh(string path)
            {
                SystemParametersInfo( 20, 0, path, 0x01 | 0x02 );
            }
        }
    }
"@

    if ($PSCmdlet.shouldProcess($path)) {
        [Wallpaper.UpdateImage]::Refresh($Path)
    }
}

#configure wallpaper
Set-ItemProperty 'hkcu:\Control Panel\Desktop\' -Name Wallpaper -Value "$repoPath\Windows-Sandbox\WSBshare\SuperPowerShell.jpg"
Set-ItemProperty 'hkcu:\Control Panel\Desktop\' -Name WallpaperOriginX -value 0
Set-ItemProperty 'hkcu:\Control Panel\Desktop\' -Name WallpaperOriginY -value 0
Set-ItemProperty 'hkcu:\Control Panel\Desktop\' -Name WallpaperStyle -value 10

Update-WallPaper

<# This doesn't work completely in newer versions of Windows 10 Invoke-Command {c:\windows\System32\RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters 1,True} #>
#this is a bit harsh but it works
# Get-Process explorer | Stop-Process -Force
Invoke-Command { C:\Windows\System32\RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters 1,True }
