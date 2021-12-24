
. $(Join-Path $PSScriptRoot "\WSBShare\SandboxSettings.ps1")

<#
    .SYNOPSIS
    Spawn a Windows sandbox instance

    .PARAMETER CopyPsProfile
    If supplied your Powershell profile will be copied to the sandbox

    .PARAMETER Memory
    The amount of memory to allocate to the sandbox. Defaults to 8192 (8GB).

    .PARAMETER NoSetup
    If set to true, the sandbox will not be configured.

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
    Supply the full path to a ps1 script that will be run once the sandbox has been created

    .EXAMPLE 
    Create a sandbox, copy your PS profile and install windows terminal, VS code, firefox, 7zip, git and nodejs
    Start-WindowsSandbox -CopyPsProfile -WindowsTerminal -VsCode -Firefox -SevenZip -Git -ChocoPackages @([pscustomobject]@{ command = 'nodejs.install'; params = ''; })

#>
Function Start-WindowsSandbox {
    [cmdletbinding(DefaultParameterSetName = "config")]
    [alias("wsb")]
    Param(
        [Parameter(ParameterSetName = "config")]
        [switch]$CopyPsProfile,
        
        [Parameter()]
        [ushort]$Memory = 8192,
        
        [Parameter(ParameterSetName = "normal")]
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
        [string]$LaunchScript
    )

    Write-Verbose "Starting $($myinvocation.mycommand)"

    $wsbShare = $(Join-Path $PSScriptRoot "WSBShare")

    if ($CopyPsProfile.IsPresent) {
        Copy-Item -Path $PROFILE -Destination $wsbShare -Force
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

    # uncomment to test desrialising the settings.json file back the to the SandboxSettings class
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

    Add-Type @"
using System;
using System.ComponentModel;
using System.IO;
using System.Xml;
using System.Xml.Serialization;

namespace SandboxConfiguration
{
    public class Builder$identifier
    {
        public static void Build(string scriptDir, ushort memory)
        {
            var configFile = Path.Combine(scriptDir, "SandboxConfig.wsb");

            var sandboxCmd = $"{Path.Combine(scriptDir, $@"WSBshare\sandbox-config.ps1")}";
            
            var config = new Configuration$identifier
            {
                MappedFolders = new ConfigurationMappedFolder$identifier[]
                {
                    new ConfigurationMappedFolder$identifier
                    {
                        HostFolder = Path.Combine(scriptDir, @"WSBshare"),
                        SandboxFolder = Path.Combine(scriptDir, @"WSBshare"),
                        ReadOnly = false
                    },
                    new ConfigurationMappedFolder$identifier
                    {
                        HostFolder = scriptDir,
                        SandboxFolder = scriptDir,
                        ReadOnly = true
                    }
                },
                ClipboardRedirection = "Default",
                MemoryInMB = memory,
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

        public string ClipboardRedirection { get; set; }
        public ushort MemoryInMB { get; set; }

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

    Invoke-Expression "[SandboxConfiguration.Builder$identifier]::Build('$PSScriptRoot', $Memory)"
}

# rob env test
# Start-WindowsSandbox -WindowsTerminal -VsCode -Firefox -SevenZip -Git -ChocoPackages @([pscustomobject]@{ command = 'nodejs.install'; params = ''; }) -LaunchScript "C:\Users\rob\OneDrive\Desktop\test.ps1"

# luke env test
# Start-WindowsSandbox