Function Start-WindowsSandbox {
    [cmdletbinding(DefaultParameterSetName = "config")]
    [alias("wsb")]
    Param(
        [Parameter(ParameterSetName = "config")]
        [ValidateScript({Test-Path $_})]
        [string]$RepoDir = "C:\Users\rob\Github",
        
        [Parameter(ParameterSetName = "config")]
        [ValidateScript({Test-Path $_})]
        [string]$Configuration = "Windows-Sandbox\SandboxConfig.wsb",
        
        [Parameter()]
        [ushort]$Memory = 8192,
        
        [Parameter(ParameterSetName = "normal")]
        [switch]$NoSetup
    )

    Write-Verbose "Starting $($myinvocation.mycommand)"

    if ($NoSetup) {
        Write-Verbose "Launching default WindowsSandbox.exe"
        c:\windows\system32\WindowsSandbox.exe
    }
    else {
        Write-Verbose "Creating configuration file $Configuration"

        CreateSandboxConfig -RepoDir $RepoDir -Configuration $Configuration -Memory $Memory

        Write-Verbose "Launching WindowsSandbox using configuration file $Configuration"
        
        Invoke-Item $(Join-Path $RepoDir $Configuration)
    }

    Write-Verbose "Ending $($myinvocation.mycommand)"
}    

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
        public static void Build(string repoDir, string configFileAndPath, ushort memory)
        {
            var configFile = Path.Combine(repoDir, configFileAndPath);

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
                ClipboardRedirection = true,
                MemoryInMB = memory,
                LogonCommand = new ConfigurationLogonCommand$identifier
                {
                    Command = $"powershell -executionpolicy unrestricted -command \"start powershell {{-noexit -file {Path.Combine(repoDir, $@"Windows-Sandbox\WSBshare\sandbox-config.ps1 {repoDir}")}}}\""
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

        public bool ClipboardRedirection { get; set; }
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

    Invoke-Expression "[SandboxConfiguration.Builder$identifier]::Build('$RepoDir', '$Configuration', $Memory)"
}

# Start-WindowsSandbox