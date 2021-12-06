Class SandboxSettings {
    [bool]$InstallChocolatey = $False
    [bool]$ChocoGui = $False
    [bool]$WindowsTerminal = $False
    [bool]$Vscode = $False
    [bool]$Chrome = $False
    [bool]$Firefox = $False
    [bool]$Notepadplusplus = $False
    [bool]$SevenZip = $False
    [bool]$Putty = $False

    SandboxSettings([bool]$installChocolatey, [bool]$chocoGui, [bool]$windowsTerminal, [bool]$vscode, [bool]$chrome, [bool]$firefox, [bool]$notepadplusplus, [bool]$sevenZip, [bool]$putty) {
        $this.InstallChocolatey = $installChocolatey
        $this.ChocoGui = $chocoGui
        $this.WindowsTerminal = $windowsTerminal
        $this.Vscode = $vscode
        $this.Chrome = $chrome
        $this.Firefox = $firefox
        $this.Notepadplusplus = $notepadplusplus
        $this.SevenZip = $sevenZip
        $this.Putty = $putty
    }

    SandboxSettings([PSCustomObject]$settings) {
        $this.InstallChocolatey = $settings.InstallChocolatey
        $this.ChocoGui = $settings.ChocoGui
        $this.WindowsTerminal = $settings.WindowsTerminal
        $this.Vscode = $settings.Vscode
        $this.Chrome = $settings.Chrome
        $this.Firefox = $settings.Firefox
        $this.Notepadplusplus = $settings.Notepadplusplus
        $this.SevenZip = $settings.SevenZip
        $this.Putty = $settings.Putty
    }

    [void]WriteAsJson([string]$path) {
        $this | ConvertTo-Json -Depth 4 -Compress | Out-File -FilePath $path -Encoding UTF8
    }
}