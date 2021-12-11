# Windows Sandbox
 A repo for Windows Sandbox Configuration

## Include in your Powershell profile

```powershell
function New-WindowsSandbox {
    # include the powershell script
	. 'C:\Github\Windows-Sandbox\Start-WindowsSandbox.ps1'

    # run the function with your params
	Start-WindowsSandbox -PsProfileDir "C:\Documents\PowerShell\" -WindowsTerminal -VsCode -Firefox -SevenZip -Git -ChocoPackages @([pscustomobject]@{ command = 'nodejs.install'; params = ''; })
}
```

## Screenshots

![Windows 11 Sandbox](https://github.com/BanterBoy/Windows-Sandbox/blob/main/assets/images/Windows11Sandbox.png)

Windows 11 Sandbox

![Windows 10 Sandbox](https://github.com/BanterBoy/Windows-Sandbox/blob/main/assets/images/Windows10Sandbox.png)

Windows 10 Sandbox

![Load Time](https://github.com/BanterBoy/Windows-Sandbox/blob/main/assets/images/stopwatch.png)

Load Time
