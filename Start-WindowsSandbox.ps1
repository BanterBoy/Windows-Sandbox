. "./WSBShare/SandboxSettings.ps1"

<#
    Spawn a Windows sandbox instance
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

        [bool]$installChocolatey = $True,
        [bool]$chocoGui = $True,
        [bool]$windowsTerminal = $True,
        [bool]$vscode = $True,
        [bool]$chrome = $True,
        [bool]$firefox = $True,
        [bool]$notepadplusplus = $True,
        [bool]$7zip = $True,
        [bool]$putty = $True
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

    $settings = [SandboxSettings]::new($installChocolatey, $chocoGui, $windowsTerminal, $vscode, $chrome, $firefox, $notepadplusplus, $7zip, $putty)

    $settings.WriteAsJson($(Join-Path $RepoDir $SettingsJson))

    # $settings = [SandboxSettings]::new((Get-Content -Raw $(Join-Path $RepoDir $SettingsJson) | Out-String | ConvertFrom-Json))

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
# Start-WindowsSandbox -RepoDir "C:\Users\rob\Github\" -PsProfileDir "C:\Users\rob\OneDrive\Documents\PowerShell\"

# luke env test
# Start-WindowsSandbox