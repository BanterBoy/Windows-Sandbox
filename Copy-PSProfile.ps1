function Copy-PSProfile {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $ProfilePath = "C:\GitRepos\ProfileFunctions\Microsoft.PowerShell_profile.ps1"
    )
    if (Test-Path $ProfilePath) {
        New-Item $PROFILE -Force
        Copy-Item -Path $ProfilePath -Destination $PROFILE
    }
}
