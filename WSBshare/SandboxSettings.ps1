Class SandboxSettings {
    [bool]$InstallChocolatey = $False

    [object[]]$ChocoPackages

    SandboxSettings([object[]]$chocoPackages) {
        $this.ChocoPackages = $chocoPackages

        $this.InstallChocolatey = $this.ChocoPackages.count -gt 0;
    }

    SandboxSettings([PSCustomObject]$settings) {
        $this.ChocoPackages = $settings.ChocoPackages

        $this.InstallChocolatey = $this.ChocoPackages.count -gt 0;
    }

    [void]WriteAsJson([string]$path) {
        $this | ConvertTo-Json -Depth 4 -Compress | Out-File -FilePath $path -Encoding UTF8
    }
}