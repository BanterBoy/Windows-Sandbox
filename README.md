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
*Optional*. If supplied your Powershell profile will be copied to the sandbox. Your profile is assumed to be the $PROFILE environemnt variable in your current session, unless overriden using the **CustomPsProfilePath** parameter.

#### CustomPsProfilePath
*Optional*. To be used in conjunction with the **CopyPsProfile** parameter. If supplied, this will be the path to a custom profile ps1 file to copy to the sandbox. The file must be named Microsoft.PowerShell_profile.ps1.

#### Memory
The amount of memory to allocate to the sandbox. Defaults to 8192 (8GB). If the memory value specified is insufficient to boot a sandbox, it will be automatically increased to the required minimum amount.

#### VGpu
Enables or disables GPU sharing. Defaults to 'Default'. 
*Enable*: Enables vGPU support in the sandbox.  
*Disable*: Disables vGPU support in the sandbox. If this value is set, the sandbox will use software rendering, which may be slower than virtualized GPU.  
*Default*: This is the default value for vGPU support. Currently this means vGPU is disabled.

#### Networking
Enables or disables networking in the sandbox. You can disable network access to decrease the attack surface exposed by the sandbox. Defaults to 'Default'.         
*Disable*: Disables networking in the sandbox.  
*Default*: This is the default value for networking support. This value enables networking by creating a virtual switch on the host and connects the sandbox to it via a virtual NIC.

#### AudioInput
Enables or disables audio input to the sandbox. Defaults to 'Default'.         
*Enable*: Enables audio input in the sandbox. If this value is set, the sandbox will be able to receive audio input from the user. Applications that use a microphone may require this capability.  
*Disable*: Disables audio input in the sandbox. If this value is set, the sandbox can't receive audio input from the user. Applications that use a microphone may not function properly with this setting.  
*Default*: This is the default value for audio input support. Currently this means audio input is enabled.

#### VideoInput
Enables or disables video input to the sandbox. Defaults to 'Default'.                 
*Enable*: Enables video input in the sandbox.  
*Disable*: Disables video input in the sandbox. Applications that use video input may not function properly in the sandbox.  
*Default*: This is the default value for video input support. Currently this means video input is disabled. Applications that use video input may not function properly in the sandbox.

#### ProtectedClient
Enables or disables video input to the sandbox. Defaults to 'Default'.                         
*Enable*: Runs Windows sandbox in Protected Client mode. If this value is set, the sandbox runs with extra security mitigations enabled.  
*Disable*: Runs the sandbox in standard mode without extra security mitigations.  
*Default*: This is the default value for Protected Client mode. Currently, this means the sandbox doesn't run in Protected Client mode.

#### PrinterRedirection
Enables or disables printer sharing from the host into the sandbox. Defaults to 'Default'.        
*Enable*: Enables sharing of host printers into the sandbox.  
*Disable*: Disables printer redirection in the sandbox. If this value is set, the sandbox can't view printers from the host.  
*Default*: This is the default value for printer redirection support. Currently this means printer redirection is disabled.

#### ClipboardRedirection
Enables or disables printer sharing from the host into the sandbox. Defaults to 'Default'.  
*Disable*: Disables clipboard redirection in the sandbox. If this value is set, copy/paste in and out of the sandbox will be restricted.  
*Default*: This is the default value for clipboard redirection. Currently copy/paste between the host and sandbox are permitted under Default.

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

Create a sandbox, set read only and read/write directory mappings and a custom profile script to be copied:

```powershell
PS C:\> Start-WindowsSandbox -ReadOnlyMappings @('C:\Users\Zaphod\HeartOfGold') -ReadWriteMappings @('C:\Users\Ford\Betelgeuse') -CopyPsProfile -CustomPsProfilePath "C:\Trillian\Microsoft.PowerShell_profile.ps1"
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
