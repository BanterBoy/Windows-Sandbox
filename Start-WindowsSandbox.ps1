
. $(Join-Path $PSScriptRoot "\WSBShare\SandboxSettings.ps1")

<#
    .SYNOPSIS
    Spawn a Windows sandbox instance

    .PARAMETER CopyPsProfile
    If supplied your Powershell profile will be copied to the sandbox. Your profile is assumed to be the $PROFILE environemnt variable in your current session, unless overriden using the CustomPsProfilePath parameter.

    .PARAMETER CustomPsProfilePath
    To be used in conjunction with the CopyPsProfile parameter. If supplied, this will be the path to a custom profile ps1 file to copy to the sandbox. The file must be named Microsoft.PowerShell_profile.ps1.

    .PARAMETER Memory
    The amount of memory to allocate to the sandbox. Defaults to 8192 (8GB). If the memory value specified is insufficient to boot a sandbox, it will be automatically increased to the required minimum amount.

    .PARAMETER VGpu
    Enables or disables GPU sharing. Defaults to 'Default'. 
    Enable: Enables vGPU support in the sandbox.
    Disable: Disables vGPU support in the sandbox. If this value is set, the sandbox will use software rendering, which may be slower than virtualized GPU.
    Default This is the default value for vGPU support. Currently this means vGPU is disabled.
    
    .PARAMETER Networking
    Enables or disables networking in the sandbox. You can disable network access to decrease the attack surface exposed by the sandbox. Defaults to 'Default'.         
    Disable: Disables networking in the sandbox.
    Default: This is the default value for networking support. This value enables networking by creating a virtual switch on the host and connects the sandbox to it via a virtual NIC.
    
    .PARAMETER AudioInput
    Enables or disables audio input to the sandbox. Defaults to 'Default'.         
    Enable: Enables audio input in the sandbox. If this value is set, the sandbox will be able to receive audio input from the user. Applications that use a microphone may require this capability.
    Disable: Disables audio input in the sandbox. If this value is set, the sandbox can't receive audio input from the user. Applications that use a microphone may not function properly with this setting.
    Default: This is the default value for audio input support. Currently this means audio input is enabled.
    
    .PARAMETER VideoInput
    Enables or disables video input to the sandbox. Defaults to 'Default'.                 
    Enable: Enables video input in the sandbox.
    Disable: Disables video input in the sandbox. Applications that use video input may not function properly in the sandbox.
    Default: This is the default value for video input support. Currently this means video input is disabled. Applications that use video input may not function properly in the sandbox.
    
    .PARAMETER ProtectedClient
    Enables or disables video input to the sandbox. Defaults to 'Default'.                         
    Enable: Runs Windows sandbox in Protected Client mode. If this value is set, the sandbox runs with extra security mitigations enabled.
    Disable: Runs the sandbox in standard mode without extra security mitigations.
    Default: This is the default value for Protected Client mode. Currently, this means the sandbox doesn't run in Protected Client mode.
    
    .PARAMETER PrinterRedirection
    Enables or disables printer sharing from the host into the sandbox. Defaults to 'Default'.        
    Enable: Enables sharing of host printers into the sandbox.
    Disable: Disables printer redirection in the sandbox. If this value is set, the sandbox can't view printers from the host.
    Default: This is the default value for printer redirection support. Currently this means printer redirection is disabled.
    
    .PARAMETER ClipboardRedirection
    Enables or disables printer sharing from the host into the sandbox. Defaults to 'Default'.        
    Disable: Disables clipboard redirection in the sandbox. If this value is set, copy/paste in and out of the sandbox will be restricted.
    Default: This is the default value for clipboard redirection. Currently copy/paste between the host and sandbox are permitted under Default.

    .PARAMETER NoSetup
    If supplied, the sandbox will not be configured (will use default values, see: https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-sandbox/windows-sandbox-configure-using-wsb-file).

    .PARAMETER AllPredefinedPackages
    If supplied, chocolatey will be used to install all predefined packages.

    .PARAMETER ChocoGui
    If supplied, chocolatey will be used to install choco GUI.

    .PARAMETER WindowsTerminal
    If supplied, chocolatey will be used to install windows terminal.

    .PARAMETER VsCode
    If supplied, chocolatey will be used to install VS Code.

    .PARAMETER Chrome
    If supplied, chocolatey will be used to install chrome.

    .PARAMETER Firefox
    If supplied, chocolatey will be used to install firefox.

    .PARAMETER NotepadPlusPlus
    If supplied, chocolatey will be used to install Notepad++.

    .PARAMETER SevenZip
    If supplied, chocolatey will be used to install 7zip.

    .PARAMETER Git
    If supplied, chocolatey will be used to install git.

    .PARAMETER Putty
    If supplied, chocolatey will be used to install putty.

    .PARAMETER ChocoPackages
    If supplied, expects an array of PS Custom Objects with command (the chocolatey install command) and params (if required) properties, e.g. @([pscustomobject]@{ command = 'nodejs.install'; params = ''; })

    .PARAMETER LaunchScript
    Supply the full path to a ps1 script that will be run once the sandbox has been created.

    .PARAMETER ReadOnlyMappings
    Array of directories that will be made available to the sandbox via mappings with read only permissions.

    .PARAMETER ReadWriteMappings
    Array of directories that will be made available to the sandbox via mappings with read/write permissions.

    .EXAMPLE 
    Create a sandbox, copy your PS profile and install windows terminal, VS code, firefox, 7zip, git and nodejs.
    Start-WindowsSandbox -CopyPsProfile -WindowsTerminal -VsCode -Firefox -SevenZip -Git -ChocoPackages @([pscustomobject]@{ command = 'nodejs.install'; params = ''; })

    .EXAMPLE 
    Create a sandbox, install windows terminal, VS code, firefox, 7zip and git, and run a custom PS1 script after the sandbox has been created.
    Start-WindowsSandbox -WindowsTerminal -VsCode -Firefox -SevenZip -Git -LaunchScript "C:\Users\Arthur\MakeTea.ps1"

    .EXAMPLE 
    Create a sandbox, set read only and read/write directory mappings and a custom profile script to be copied.
    Start-WindowsSandbox -ReadOnlyMappings @('C:\Users\Zaphod\HeartOfGold') -ReadWriteMappings @('C:\Users\Ford\Betelgeuse') -CopyPsProfile -CustomPsProfilePath "C:\Trillian\Microsoft.PowerShell_profile.ps1"

#>
Function Start-WindowsSandbox {
    [cmdletbinding(DefaultParameterSetName = "config")]
    [alias("wsb")]
    Param(
        [Parameter(Mandatory = $false, HelpMessage = 'If supplied your Powershell profile will be copied to the sandbox. Your profile is assumed to be the $PROFILE environemnt variable in your current session, unless overriden using the CustomPsProfilePath parameter.')]
        [switch]$CopyPsProfile,

        [Parameter(Mandatory = $false, HelpMessage = "To be used in conjunction with the CopyPsProfile parameter. If supplied, this will be the path to a custom profile ps1 file to copy to the sandbox. The file must be named Microsoft.PowerShell_profile.ps1.")]
        [ValidateScript({
            if (Test-Path $_) {
                if ($_ -like ("*Microsoft.PowerShell_profile.ps1")) {
                    $true
                } else {
                    throw "The supplied custom profile path does not appear to be a valid PowerShell profile."
                }
            } else {
                throw "The supplied custom profile path does not exist."
            }
        })]
        [switch]$CustomPsProfilePath,
        
        [Parameter(HelpMessage = "Amount of memory (in MB) to allocate to the sandbox. Defaults to 8192 (8GB). If the memory value specified is insufficient to boot a sandbox, it will be automatically increased to the required minimum amount.")]
        [ushort]$Memory = 8192,
        
        [Parameter(HelpMessage = "Enables or disables GPU sharing. Defaults to 'Default'. 
        Enable: Enables vGPU support in the sandbox.
        Disable: Disables vGPU support in the sandbox. If this value is set, the sandbox will use software rendering, which may be slower than virtualized GPU.
        Default This is the default value for vGPU support. Currently this means vGPU is disabled.")]
        [ValidateSet("Enable", "Disable", "Default")]
        [string]$VGpu = "Default",
        
        [Parameter(HelpMessage = "Enables or disables networking in the sandbox. You can disable network access to decrease the attack surface exposed by the sandbox. Defaults to 'Default'.         
        Disable: Disables networking in the sandbox.
        Default: This is the default value for networking support. This value enables networking by creating a virtual switch on the host and connects the sandbox to it via a virtual NIC.")]
        [ValidateSet("Disable", "Default")]
        [string]$Networking = "Default",
        
        [Parameter(HelpMessage = "Enables or disables audio input to the sandbox. Defaults to 'Default'.         
        Enable: Enables audio input in the sandbox. If this value is set, the sandbox will be able to receive audio input from the user. Applications that use a microphone may require this capability.
        Disable: Disables audio input in the sandbox. If this value is set, the sandbox can't receive audio input from the user. Applications that use a microphone may not function properly with this setting.
        Default: This is the default value for audio input support. Currently this means audio input is enabled.")]
        [ValidateSet("Enable", "Disable", "Default")]
        [string]$AudioInput = "Default",
        
        [Parameter(HelpMessage = "Enables or disables video input to the sandbox. Defaults to 'Default'.                 
        Enable: Enables video input in the sandbox.
        Disable: Disables video input in the sandbox. Applications that use video input may not function properly in the sandbox.
        Default: This is the default value for video input support. Currently this means video input is disabled. Applications that use video input may not function properly in the sandbox.")]
        [ValidateSet("Enable", "Disable", "Default")]
        [string]$VideoInput = "Default",
        
        [Parameter(HelpMessage = "Enables or disables video input to the sandbox. Defaults to 'Default'.                         
        Enable: Runs Windows sandbox in Protected Client mode. If this value is set, the sandbox runs with extra security mitigations enabled.
        Disable: Runs the sandbox in standard mode without extra security mitigations.
        Default: This is the default value for Protected Client mode. Currently, this means the sandbox doesn't run in Protected Client mode.")]
        [ValidateSet("Enable", "Disable", "Default")]
        [string]$ProtectedClient = "Default",
        
        [Parameter(HelpMessage = "Enables or disables printer sharing from the host into the sandbox. Defaults to 'Default'.        
        Enable: Enables sharing of host printers into the sandbox.
        Disable: Disables printer redirection in the sandbox. If this value is set, the sandbox can't view printers from the host.
        Default: This is the default value for printer redirection support. Currently this means printer redirection is disabled.")]
        [ValidateSet("Enable", "Disable", "Default")]
        [string]$PrinterRedirection = "Default",
        
        [Parameter(HelpMessage = "Enables or disables printer sharing from the host into the sandbox. Defaults to 'Default'.        
        Disable: Disables clipboard redirection in the sandbox. If this value is set, copy/paste in and out of the sandbox will be restricted.
        Default: This is the default value for clipboard redirection. Currently copy/paste between the host and sandbox are permitted under Default.")]
        [ValidateSet("Disable", "Default")]
        [string]$ClipboardRedirection = "Default",
        
        [Parameter(HelpMessage = "Launch a sandbox without any configuration (will use default values, see: https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-sandbox/windows-sandbox-configure-using-wsb-file)")]
        [switch]$NoSetup,

        [Parameter(Mandatory = $false, HelpMessage = "Install chocolatey and all predefined packages (i.e. no other package switches required)")]
        [switch]$AllPredefinedPackages,

        [Parameter(Mandatory = $false, HelpMessage = "Use chocolatey to install the chocolatey GUI on the sandbox")]
        [switch]$ChocoGui,

        [Parameter(Mandatory = $false, HelpMessage = "Use chocolatey to install windows terminal on the sandbox")]
        [switch]$windowsTerminal,

        [Parameter(Mandatory = $false, HelpMessage = "Use chocolatey to install VS code on the sandbox")]
        [switch]$VsCode,

        [Parameter(Mandatory = $false, HelpMessage = "Use chocolatey to install Chrome on the sandbox")]
        [switch]$Chrome,

        [Parameter(Mandatory = $false, HelpMessage = "Use chocolatey to install Firefox on the sandbox")]
        [switch]$Firefox,

        [Parameter(Mandatory = $false, HelpMessage = "Use chocolatey to install Notepad++ on the sandbox")]
        [switch]$NotepadPlusPlus,

        [Parameter(Mandatory = $false, HelpMessage = "Use chocolatey to install 7zip on the sandbox")]
        [switch]$SevenZip,

        [Parameter(Mandatory = $false, HelpMessage = "Use chocolatey to install git on the sandbox")]
        [switch]$Git,

        [Parameter(Mandatory = $false, HelpMessage = "Use chocolatey to install Putty on the sandbox")]
        [switch]$Putty,

        [Parameter(Mandatory = $false, HelpMessage = "Array of chocolatey package names to be installed. For predefined packages use switches, e.g. -VsCode -Chrome -Firefox")]
		[pscustomobject[]]$ChocoPackages,

        [Parameter(Mandatory = $false, HelpMessage = "File path of a ps1 script that will be run on the sandbox after it is created")]
        [ValidateScript({Test-Path $_})]
        [string]$LaunchScript,

        [Parameter(Mandatory = $false, HelpMessage = "Array of directories that will be made available to the sandbox via mappings with read only permissions")]
		[string[]]$ReadOnlyMappings,

        [Parameter(Mandatory = $false, HelpMessage = "Array of directories that will be made available to the sandbox via mappings with read/write permissions")]
		[string[]]$ReadWriteMappings
    )

    Write-Verbose "Starting $($myinvocation.mycommand)"

    $wsbShare = $(Join-Path $PSScriptRoot "WSBShare")

    # copy PS profile
    if ($CopyPsProfile.IsPresent) {
        if (![string]::IsNullOrWhiteSpace($CustomPsProfilePath)) {
            Copy-Item -Path $CustomPsProfilePath -Destination $wsbShare -Force
        } else {
            if ([string]::IsNullOrWhiteSpace($PROFILE) -or !(Test-Path $PROFILE)) {
                throw "CopyPsProfile was supplied but no profile was found. Please set the $PROFILE environment variable to the path of your PowerShell profile."
            }
    
            Copy-Item -Path $PROFILE -Destination $wsbShare -Force
        }
    }
    
    # if no configuration file is specified, spawn a default sandbox
    if ($NoSetup) {
        Write-Verbose "Launching default WindowsSandbox.exe"

        c:\windows\system32\WindowsSandbox.exe

        Write-Verbose "Ending $($myinvocation.mycommand)"

        return
    }

    Write-Verbose "Creating configuration file SandboxConfig.wsb"

    CreateSandboxConfig -Memory $Memory

    Write-Verbose "Creating settings json file SandboxConfig.wsb"

    if ($null -eq $ChocoPackages) {
        $ChocoPackages = [pscustomobject]@()
    }

    # predefined choco packages that can be included using parameter switches
    $packagesConfig = @(
        [pscustomobject]@{ exists = $ChocoGui.IsPresent; command = 'chocolateygui'; params = ''; },
        [pscustomobject]@{ exists = $windowsTerminal.IsPresent; command = 'microsoft-windows-terminal'; params = ''; },
        [pscustomobject]@{ exists = $VsCode.IsPresent; command = 'vscode'; params = ''; },
        [pscustomobject]@{ exists = $Chrome.IsPresent; command = 'googlechrome'; params = ''; },
        [pscustomobject]@{ exists = $Firefox.IsPresent; command = 'firefox'; params = ''; },
        [pscustomobject]@{ exists = $NotepadPlusPlus.IsPresent; command = 'notepadplusplus.install'; params = ''; },
        [pscustomobject]@{ exists = $SevenZip.IsPresent; command = '7zip.install'; params = ''; },
        [pscustomobject]@{ exists = $Git.IsPresent; command = 'git'; params = "'/WindowsTerminal /WindowsTerminalProfile /Editor:VisualStudioCode'"; },
        [pscustomobject]@{ exists = $Putty.IsPresent; command = 'putty'; params = ''; }
    )

    foreach ($package in $packagesConfig) {
        if ($package.exists -or $AllPredefinedPackages.IsPresent) {
            $ChocoPackages = $ChocoPackages + @([pscustomobject]@{ command = $package.command; params = $package.params; })
        }
    }

    [string]$launchScriptFileName = $null

    if (-Not [String]::IsNullOrWhiteSpace($LaunchScript)) {
        $launchScriptFileName = [System.IO.Path]::GetFileName($LaunchScript)

        Copy-Item -Path $LaunchScript -Destination $(Join-Path $wsbShare $launchScriptFileName) -Force
    }

    $settings = [SandboxSettings]::new($ChocoPackages, $launchScriptFileName)

    $settings.WriteAsJson($(Join-Path $wsbShare "sandboxSettings.json"))

    # uncomment to test deserialising the settings.json file back the to the SandboxSettings class
    # $settings = [SandboxSettings]::new((Get-Content -Raw $(Join-Path $wsbShare "sandboxSettings.json") | Out-String | ConvertFrom-Json))

    Write-Verbose "Launching WindowsSandbox using configuration file SandboxConfig.wsb"
    
    Invoke-Item $(Join-Path $PSScriptRoot "SandboxConfig.wsb")

    Write-Verbose "Ending $($myinvocation.mycommand)"
}

<#
    # Create a configuration file for the Windows Sandbox
    #
    # Parameters:
    #   -Memory: The amount of memory to allocate to the sandbox
#>
Function CreateSandboxConfig {
    Param(
        [Parameter()]
        [ushort]$Memory
    )

    $identifier = [System.Guid]::NewGuid().ToString().Replace("-", "")

    <#
        # Generate a List<string> variable int he C# script to declare any mappings provided in the parameters
        #
        # Parameters:
        #   -varName: Name of the variable to create
        #   -mappings: The mappings to create the variable with
    #>
    Function GenerateCSharpMappingVariable([string] $varName, [string[]] $mappings) {
        $scriptVar = "var $varName = new List<string> {"
    
        if ($null -ne $mappings) {
            foreach ($mapping in $mappings) {
                $scriptVar += "@""$mapping"","
            }
        }
        
        $scriptVar += "};"

        return $scriptVar
    }

    Add-Type @"
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Xml;
using System.Xml.Serialization;

namespace SandboxConfiguration
{
    public class Builder$identifier
    {
        public static void Build(string scriptDir)
        {
            var configFile = Path.Combine(scriptDir, "SandboxConfig.wsb");

            var sandboxCmd = $"{Path.Combine(scriptDir, $@"WSBshare\sandbox-config.ps1")}";

            var mappedFolders = new List<ConfigurationMappedFolder$identifier>
            {
                new ConfigurationMappedFolder$identifier
                {
                    HostFolder = Path.Combine(scriptDir, @"WSBshare"),
                    SandboxFolder = Path.Combine(scriptDir, @"WSBshare"),
                    ReadOnly = false
                }
            };

            $(GenerateCSharpMappingVariable -varName "readOnlyMappings" -mappings $ReadOnlyMappings)

            $(GenerateCSharpMappingVariable -varName "readWriteMappings" -mappings $ReadWriteMappings)

            foreach (var mappingConfig in new List<(List<string> mappings, bool readOnly)>
            {
                (mappings: readOnlyMappings, readOnly: true),
                (mappings: readWriteMappings, readOnly: false)
            })
            {
                foreach (var mapping in mappingConfig.mappings)
                {
                    mappedFolders.Add(new ConfigurationMappedFolder$identifier
                    {
                        HostFolder = mapping,
                        SandboxFolder = mapping,
                        ReadOnly = mappingConfig.readOnly
                    });
                }
            }

            var config = new Configuration$identifier
            {
                MappedFolders = mappedFolders.ToArray(),
                MemoryInMB = $Memory,
                Vgpu = "$VGpu",
                Networking = "$Networking",
                AudioInput = "$AudioInput",
                VideoInput = "$VideoInput",
                ProtectedClient = "$ProtectedClient",
                PrinterRedirection = "$PrinterRedirection",
                ClipboardRedirection = "$ClipboardRedirection",
                LogonCommand = new ConfigurationLogonCommand$identifier
                {
                    Command = $"powershell -executionpolicy unrestricted -command \"start powershell {{-noexit -file {sandboxCmd}}}\""
                } 
            };

            var configFilePath = Path.GetDirectoryName(configFile);

            if (!Directory.Exists(configFilePath))
                Directory.CreateDirectory(configFilePath);

            using var writer = new StreamWriter(configFile);
            using var xmlWriter = XmlWriter.Create(writer, new XmlWriterSettings { OmitXmlDeclaration = true, CloseOutput = true, ConformanceLevel = ConformanceLevel.Auto, Indent = true });
            new XmlSerializer(typeof(Configuration$identifier)).Serialize(xmlWriter, config, new XmlSerializerNamespaces(new[] { XmlQualifiedName.Empty }));
        }
    }

    [System.SerializableAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    [System.Xml.Serialization.XmlRootAttribute(ElementName = "Configuration", Namespace = "", IsNullable = false)]
    public class Configuration$identifier
    {
        [System.Xml.Serialization.XmlArrayItemAttribute("MappedFolder", IsNullable = false)]
        public ConfigurationMappedFolder$identifier[] MappedFolders { get; set; }

        public ushort MemoryInMB { get; set; }
        public string Vgpu { get; set; }
        public string Networking { get; set; }
        public string AudioInput { get; set; }
        public string VideoInput { get; set; }
        public string ProtectedClient { get; set; }
        public string PrinterRedirection { get; set; }
        public string ClipboardRedirection { get; set; }

        public ConfigurationLogonCommand$identifier LogonCommand { get; set; }
    }

    [System.SerializableAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public class ConfigurationMappedFolder$identifier
    {
        public string HostFolder { get; set; }
        public string SandboxFolder { get; set; }
        public bool ReadOnly { get; set; }
    }

    [System.SerializableAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public class ConfigurationLogonCommand$identifier
    {
        public string Command { get; set; }
    }
}
"@

    Invoke-Expression "[SandboxConfiguration.Builder$identifier]::Build('$PSScriptRoot')"
}

# rob env test
# Start-WindowsSandbox -WindowsTerminal -VsCode -Firefox -SevenZip -Git -ChocoPackages @([pscustomobject]@{ command = 'nodejs.install'; params = ''; }) -LaunchScript "C:\Users\rob\OneDrive\Desktop\test.ps1"
# Start-WindowsSandbox -ReadOnlyMappings @('C:\Users\rob\Github\Windows-Sandbox') -ReadWriteMappings @('C:\Users\rob\Github') 
#-CopyPsProfile -CustomPsProfilePath "C:\Users\rob\OneDrive\Desktop\test.ps1"

# luke env test
# Start-WindowsSandbox