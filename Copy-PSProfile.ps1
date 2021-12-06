<#
.SYNOPSIS
 think this can be deleted? assuming it was here for testing before being put in teh sandbox ps1?

.DESCRIPTION
Long description

.PARAMETER ProfilePath
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
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
