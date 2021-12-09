. "./WSBShare/SandboxSettings.ps1"

<#
    .SYNOPSIS
    Spawn a Windows sandbox instance

    .PARAMETER RepoDir
    The directory where the repository is located, i.e. where this was checked out.

    .PARAMETER PsProfileDir
    The directory where your PowerShell profile is located.

    .PARAMETER Configuration
    The location of the sandbox configuration file. This is created by the function and should probably be left alone.

    .PARAMETER Memory
    The amount of memory to allocate to the sandbox. Defaults to 8192 (8GB).

    .PARAMETER SettingsJson
    The location the generated settings file will be written to. This should be the shared folder for the sandbox, i.e. "./WSBShare/SandboxSettings.json", best not to change.

    .PARAMETER NoSetup
    If set to true, the sandbox will not be configured.

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

    .EXAMPLE 
    Create a sandbox and install windows terminal, VS code, firefox, 7zip, git and nodejs
    Start-WindowsSandbox -RepoDir "C:\Github\" -PsProfileDir "C:\Documents\PowerShell\" -WindowsTerminal -VsCode -Firefox -SevenZip -Git -ChocoPackages @([pscustomobject]@{ command = 'nodejs.install'; params = ''; })

#>
Function Start-WindowsSandbox {
    [cmdletbinding(DefaultParameterSetName = "config")]
    [alias("wsb")]
    Param(
        [Parameter(ParameterSetName = "config")]
        [ValidateSet("C:\GitRepos\","C:\Users\rob\Github\")]
        [string]$RepoDir = "C:\GitRepos\",
        
        [Parameter(ParameterSetName = "config")]
        [ValidateSet("C:\GitRepos\ProfileFunctions\","C:\Users\rob\OneDrive\Documents\PowerShell\")]
        [string]$PsProfileDir = "C:\GitRepos\ProfileFunctions\",
        
        [Parameter(ParameterSetName = "config")]
        [ValidateScript({Test-Path $(Join-Path $RepoDir $Configuration)})]
        [string]$Configuration = "Windows-Sandbox\SandboxConfig.wsb",
        
        [Parameter()]
        [ushort]$Memory = 8192,
        
        [Parameter(ParameterSetName = "config")]
        [string]$SettingsJson = "Windows-Sandbox\WSBShare\sandboxSettings.json",
        
        [Parameter(ParameterSetName = "normal")]
        [switch]$NoSetup,

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

        [Parameter(Mandatory = $false, HelpMessage = "Array of chocolatey package names to be installed. For predefined packages use switches, e.g. -vscode -chrome -firefox")]
		[pscustomobject[]]$ChocoPackages
    )

    Write-Verbose "Starting $($myinvocation.mycommand)"

    # if no configuration file is specified, spawn a default sandbox
    if ($NoSetup) {
        Write-Verbose "Launching default WindowsSandbox.exe"

        c:\windows\system32\WindowsSandbox.exe

        Write-Verbose "Ending $($myinvocation.mycommand)"

        return
    }

    # test config file here as no point validating the parameter if we're using the NoSetup switch
    try {
        $configFile = $(Join-Path $RepoDir $Configuration)

        if (!(Test-Path $configFile)) {
            Write-Error "Configuration file not found at $configFile"

            return
        }
    }
    catch {
        Write-Error "Configuration file not found at $configFile"

        return
    }

    Write-Verbose "Creating configuration file $Configuration"

    CreateSandboxConfig -RepoDir $RepoDir -Configuration $Configuration -Memory $Memory

    Write-Verbose "Creating settings json file $Configuration"

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
        if ($package.exists) {
            $ChocoPackages = $ChocoPackages + @([pscustomobject]@{ command = $package.command; params = $package.params; })
        }
    }

    $settings = [SandboxSettings]::new($ChocoPackages)

    # $settings = [SandboxSettings]::new($ChocoGui.IsPresent(), $windowsTerminal.IsPresent(), $VsCode.IsPresent(), $Chrome.IsPresent(), $Firefox.IsPresent(), $NotepadPlusPlus.IsPresent(), $7zip.IsPresent(), $Putty.IsPresent())

    $settings.WriteAsJson($(Join-Path $RepoDir $SettingsJson))

    $settings = [SandboxSettings]::new((Get-Content -Raw $(Join-Path $RepoDir $SettingsJson) | Out-String | ConvertFrom-Json))

    Write-Verbose "Launching WindowsSandbox using configuration file $Configuration"
    
    Invoke-Item $(Join-Path $RepoDir $Configuration)

    Write-Verbose "Ending $($myinvocation.mycommand)"
}

<#
    # Create a configuration file for the Windows Sandbox
    #
    # Parameters:
    #   -RepoDir: The directory containing the repository
    #   -Configuration: The name of the configuration file to use
    #   -Memory: The amount of memory to allocate to the sandbox
#>
Function CreateSandboxConfig {
    Param(
        [Parameter()]
        [string]$RepoDir,
        
        [Parameter()]
        [string]$Configuration,
        
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
        public static void Build(string repoDir, string psProfileDir, string configFileAndPath, ushort memory)
        {
            var configFile = Path.Combine(repoDir, configFileAndPath);

            var sandboxCmd = Path.Combine(repoDir, $@"Windows-Sandbox\WSBshare\sandbox-config.ps1 {repoDir} {psProfileDir}");

            var config = new Configuration$identifier
            {
                MappedFolders = new ConfigurationMappedFolder$identifier[]
                {
                    new ConfigurationMappedFolder$identifier
                    {
                        HostFolder = Path.Combine(repoDir, @"Windows-Sandbox\WSBshare"),
                        SandboxFolder = Path.Combine(repoDir, @"Windows-Sandbox\WSBshare"),
                        ReadOnly = false
                    },
                    new ConfigurationMappedFolder$identifier
                    {
                        HostFolder = repoDir,
                        SandboxFolder = repoDir,
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

    Invoke-Expression "[SandboxConfiguration.Builder$identifier]::Build('$RepoDir', '$PsProfileDir', '$Configuration', $Memory)"
}

# rob env test
# Start-WindowsSandbox -RepoDir "C:\Users\rob\Github\" -PsProfileDir "C:\Users\rob\OneDrive\Documents\PowerShell\" -WindowsTerminal -VsCode -Firefox -SevenZip -Git -ChocoPackages @([pscustomobject]@{ command = 'nodejs.install'; params = ''; })

# luke env test
# Start-WindowsSandbox