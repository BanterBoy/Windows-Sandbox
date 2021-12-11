Class SandboxSettings {
    [bool]$InstallChocolatey = $False
    [object[]]$ChocoPackages
    [string]$LaunchScript

    SandboxSettings([object[]]$chocoPackages, [string]$launchScript) {
        $this.ChocoPackages = $chocoPackages
        $this.LaunchScript = $launchScript

        $this.InstallChocolatey = $this.ChocoPackages.count -gt 0;
    }

    SandboxSettings([PSCustomObject]$settings) {
        $this.ChocoPackages = $settings.ChocoPackages
        $this.LaunchScript = $settings.LaunchScript

        $this.InstallChocolatey = $this.ChocoPackages.count -gt 0;
    }

    [void]WriteAsJson([string]$path) {
        $this | ConvertTo-Json -Depth 4 -Compress | Out-File -FilePath $path -Encoding UTF8
    }
}