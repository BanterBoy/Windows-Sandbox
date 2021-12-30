# Windows Sandbox
 A Powershell project that allows the configuration of Windows Sandbox and creation from the command line.

## What's the Windows Sandbox?

*From the Microsoft docs:*

> Windows Sandbox provides a lightweight desktop environment to safely run applications in isolation. Software installed inside the Windows Sandbox environment remains "sandboxed" and runs separately from the host machine.
> 
> A sandbox is temporary. When it's closed, all the software and files and the state are deleted. You get a brand-new instance of the sandbox every time you open the application.

For further information and details on how to set up Windows Sandbox on your machine, please refer to the [Microsoft documentation](https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-sandbox/windows-sandbox-overview).

## Project Description

This project provides a way to create a Windows Sandbox environment using the command line. The sandbox configuration XML file is built on the fly allowing you to easily set options without having to worry about creating a correctly formatted file and also provides advanced features, such as:

* Install a set of pre-defined applications using [chocolatey](https://chocolatey.org/), or pass in any applications not pre-defined that [chocolatey](https://chocolatey.org/) can install.
* Run your own custom Powershell script once the Sandbox has been created.
* Installs Powershell 7 (by default the Sandbox uses Powershell 5). Installing PS7 is not optional.
* Copy your Powershell profile so both Powershell 5 and Powershell 7 environments are configured for you.

## Parameters

#### CopyPsProfile
*Optional*. If supplied your Powershell profile will be copied to the sandbox

#### Memory
The amount of memory to allocate to the sandbox. Defaults to 8192 (8GB).

#### NoSetup
*Optional*. If supplied, the sandbox will not be configured.

#### AllPredefinedPackages
*Optional*. If supplied, chocolatey will be used to install all predefined packages.

#### ChocoGui
*Optional*. If supplied, chocolatey will be used to install choco GUI.

#### WindowsTerminal
*Optional*. If supplied, chocolatey will be used to install windows terminal.

#### VsCode
*Optional*. If supplied, chocolatey will be used to install VS Code.

#### Chrome
*Optional*. If supplied, chocolatey will be used to install chrome.

#### Firefox
*Optional*. If supplied, chocolatey will be used to install firefox.

#### NotepadPlusPlus
*Optional*. If supplied, chocolatey will be used to install Notepad++.

#### SevenZip
*Optional*. If supplied, chocolatey will be used to install 7zip.

#### Git
*Optional*. If supplied, chocolatey will be used to install git.

#### Putty
*Optional*. If supplied, chocolatey will be used to install putty.

#### ChocoPackages
*Optional*. If supplied, expects an array of PS Custom Objects with command (the chocolatey install command) and params (if required) properties, e.g. @([pscustomobject]@{ command = 'nodejs.install'; params = ''; })

#### LaunchScript
*Optional*. Supply the full path to a ps1 script that will be run once the sandbox has been created.

#### ReadOnlyMappings
*Optional*. Array of directories that will be made available to the sandbox via mappings with read only permissions.

#### ReadWriteMappings
*Optional*. Array of directories that will be made available to the sandbox via mappings with read/write permissions.

## Examples

Create a sandbox, copy your PS profile and install windows terminal, VS code, firefox, 7zip, git and nodejs:

```powershell
PS C:\> Start-WindowsSandbox -CopyPsProfile -WindowsTerminal -VsCode -Firefox -SevenZip -Git -ChocoPackages @([pscustomobject]@{ command = 'nodejs.install'; params = ''; })
```

Create a sandbox, install windows terminal, VS code, firefox, 7zip and git, and run a custom PS1 script after the sandbox has been created:

```powershell
PS C:\> Start-WindowsSandbox -WindowsTerminal -VsCode -Firefox -SevenZip -Git -LaunchScript "C:\Users\Arthur\MakeTea.ps1"
```

Create a sandbox, install windows terminal, VS code, firefox, 7zip and git, and set read only and read/write directory mappings:

```powershell
PS C:\> Start-WindowsSandbox -WindowsTerminal -VsCode -Firefox -SevenZip -Git -ReadOnlyMappings @('C:\Users\Zaphod\HeartOfGold') -ReadWriteMappings @('C:\Users\Ford\Betelgeuse')
```

## Include in your Powershell profile

```powershell
function New-WindowsSandbox {
    # include the powershell script
    . 'C:\Users\Slartibartfast\Github\Windows-Sandbox\Start-WindowsSandbox.ps1'

    # run the function with your params
    Start-WindowsSandbox -PsProfileDir "C:\Documents\PowerShell\" -WindowsTerminal -VsCode -Firefox -SevenZip -Git -ChocoPackages @([pscustomobject]@{ command = 'nodejs.install'; params = ''; })
}
```



<!-- ## Contribute

Please raise an issue if you find a bug or want to request a new feature, or create a pull request to contribute. -->



<!-- ## Screenshots

![Windows 11 Sandbox](https://github.com/BanterBoy/Windows-Sandbox/blob/main/assets/images/Windows11Sandbox.png)

Windows 11 Sandbox

![Windows 10 Sandbox](https://github.com/BanterBoy/Windows-Sandbox/blob/main/assets/images/Windows10Sandbox.png)

Windows 10 Sandbox

![Load Time](https://github.com/BanterBoy/Windows-Sandbox/blob/main/assets/images/stopwatch.png)

Load Time -->
