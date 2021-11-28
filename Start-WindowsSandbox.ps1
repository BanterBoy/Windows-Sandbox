Function Start-WindowsSandbox {
    [cmdletbinding(DefaultParameterSetName = "config")]
    [alias("wsb")]
    Param(
        [Parameter(ParameterSetName = "config")]
        [ValidateScript({Test-Path $_})]
        [string]$Configuration = "C:\GitRepos\Windows-Sandbox\SandboxConfig.wsb",
        [Parameter(ParameterSetName = "normal")]
        [switch]$NoSetup
    )

    Write-Verbose "Starting $($myinvocation.mycommand)"

    if ($NoSetup) {
        Write-Verbose "Launching default WindowsSandbox.exe"
        c:\windows\system32\WindowsSandbox.exe
    }
    else {
        Write-Verbose "Launching WindowsSandbox using configuration file $Configuration"
        Invoke-Item $Configuration
    }

    Write-Verbose "Ending $($myinvocation.mycommand)"
}    
