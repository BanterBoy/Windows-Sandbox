<#
	Script Name   : Microsoft.PowerShell_profile.ps1
	Author        : Rob Green
	Created       : 31/08/2020
	Notes         : This script has been created in order pre-configure the following setting:-
					- Shell Title - Rebranded
					- Shell Dimensions configured to 170 Width x 45 Height
					- Buffer configured to 9000 lines

Displays
- whether or not running as Administrator in the WindowTitle
- the Date and Time in the Console Window
- whether or not running as Administrator in the Console Window

When run from Elevated Prompt
- Preconfigures Executionpolicy settings per PowerShell Process Unrestricted
(un-necessary to configure execution policy manually
each new PowerShell session, is configured at run and disposed of on exit)
- Amend PSModulePath variable to include 'OneDrive\PowerShellModules'
- Configure LocalHost TrustedHosts value
- Measures script running performance and displays time upon completion

#>

#--------------------
# Start

Add-type -AssemblyName WindowsBase
Add-type -AssemblyName PresentationCore

# open ssl to path
if (Test-Path "C:\Program Files\OpenSSL\bin") 
{
	$env:path = "$env:path;C:\Program Files\OpenSSL\bin"
}

if (Test-Path "C:\certs\openssl.cnf")
{
	$env:OPENSSL_CONF = "C:\certs\openssl.cnf"
}

Start-Sleep -Milliseconds 100

if ([System.Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::LeftCtrl)) {
	Write-Warning -Message "LeftCtrl key pressed, no profile loaded"
	return;
}

#$Stopwatch = [system.diagnostics.stopwatch]::startNew()

#$History = (Get-PSReadlineOption).HistorySavePath
$History = "C:\Users\Rob\AppData\Roaming\Microsoft\Windows\PowerShell\History\PSHistory.txt"

Get-ChildItem C:\Users\Rob\OneDrive\Documents\PowerShell\ProfileFunctions\*.ps1 | ForEach-Object {. $_ }

# oh my posh
Import-Module oh-my-posh
oh-my-posh --init --shell pwsh --config 'C:\Users\rob\OneDrive\Documents\PowerShell\Modules\oh-my-posh\themes\_rob.omp.json' | Invoke-Expression

# posh git
Import-Module posh-git
$env:POSH_GIT_ENABLED = $true

# Function Get-ContainedCommand
function Get-ContainedCommand {
	param
	(
		[Parameter(Mandatory)][string]
		$Path,

		[string][ValidateSet('FunctionDefinition', 'Command')]
		$ItemType
	)

	$Token = $Err = $null
	$ast = [Management.Automation.Language.Parser]::ParseFile($Path, [ref] $Token, [ref] $Err)

	$ast.FindAll({ $args[0].GetType(). Name -eq "${ItemType}Ast" }, $true)
}

<#
.SYNOPSIS
Gets the parent functions from a ps1 script file (where parents are any functions that have no indentation preceding their declaration, and functions are in the format Verb-Name)

.EXAMPLE
Get-ScriptFunctionNames -Path 'C:\Users\Rob\OneDrive\Documents\PowerShell\ProfileFunctions\CognitoFunctions.ps1'
#>
function Get-ScriptFunctionNames {
    param (
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [AllowNull()]
        [System.String]$Path
    )

    Process{
        [System.Collections.Generic.List[String]]$funcNames = New-Object System.Collections.Generic.List[String]

        if (([System.String]::IsNullOrWhiteSpace($Path))) {
			return $funcNames
		}
        
		Select-String -Path "$Path" -Pattern "^[F|f]unction.*[A-Za-z0-9+]-[A-Za-z0-9+]" | 
			ForEach-Object {
				[System.Text.RegularExpressions.Regex] $regexp = New-Object Regex("([F|f]unction)( +)([\w-]+)")
				[System.Text.RegularExpressions.Match] $match = $regexp.Match("$_")

				if ($match.Success)	{
					$funcNames.Add("$($match.Groups[3])")
				}   
			}
        
        return ,$funcNames.ToArray()
    }
}

function Show-History {
	vscode $History
}

function Profile {
	param (
        [parameter(Mandatory = $true)]
        [string][ValidateSet('Edit', 'Refresh')]
		$Action
    )

	switch ($Action) {
		'Edit' { vscode $profile }
		'Refresh' { . $profile }
	}
}

function Connect-Phone {
	scrcpy
}

function IsAdmin {
    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

# Function        Restart-Profile
function Restart-Profile {
	@(
		$Profile.AllUsersAllHosts,
		$Profile.AllUsersCurrentHost,
		$Profile.CurrentUserAllHosts,
		$Profile.CurrentUserCurrentHost
	) |
	ForEach-Object {
		if (Test-Path $_) {
			Write-Verbose "Running $_"
			. $_
		}
	}
}

# Function        New-GitDrives
function New-GitDrives {
	$PSRootFolder = Select-FolderLocation
	$Exist = Test-Path -Path $PSRootFolder
	if (($Exist) = $true) {
		$PSDrivePaths = Get-ChildItem -Path "$PSRootFolder\"
		foreach ($item in $PSDrivePaths) {
			$paths = Test-Path -Path $item.FullName
			if (($paths) = $true) {
				New-PSDrive -Name $item.Name -PSProvider "FileSystem" -Root $item.FullName
			}
		}
	}
}

<#
.SYNOPSIS
Takes an array and breaks down into an array of arrays by a supplied batch size

.EXAMPLE
Invoke-BatchArray -Arr @(1,2,3,4,5,6,7,8,9) -BatchSize 5 | ForEach-Object { Write-Host $_ }
#>
function Invoke-BatchArray {
    param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "Array to be batched.")]
		[object[]]$Arr,

		[Parameter(Mandatory = $false, HelpMessage = "Number of objects in each batch.")]
        [int]$BatchSize = 5
    )

    for ($i = 0; $i -lt $Arr.Count; $i += $BatchSize) {
        , ($Arr | Select-Object -Skip $i -First $BatchSize)
    }
}

# Function NewGreeting
function NewGreeting {
	#Write-Host $((get-date).ToLocalTime()).ToString("ddd, dd MMM yyyy - H:mm:ss") + 
	
	$prv = "User"
	$frg = "Green"
	
	if (Test-IsAdmin) {
		$prv = "Admin"
		$frg = "Red"
	}

	Write-Host -ForegroundColor $frg "$($((get-date).ToLocalTime()).ToString("H:mm:ss on ddd, dd MMM yyyy"))  |  $prv Privileges"
	Write-Host ""
	
	# try {
	# 	Get-TorrentSummary	
	# }
	# catch {}

	Write-Host "Profile functions: " -NoNewline
	Write-Host -ForegroundColor "Yellow" "List-ProfileFunctions"
	# Write-Host ""

	# $psPath = "C:\Users\Rob\OneDrive\Documents\PowerShell"
	# $funcs = @();

	# Get-ChildItem "$psPath\ProfileFunctions\*.ps1" |
	# 	ForEach-Object {
	# 		$funcs = $funcs + (Get-ScriptFunctionNames -Path "$psPath\ProfileFunctions\$($_.Name)")
	# 	}

	# $funcs = $funcs + (Get-ScriptFunctionNames -Path "$psPath\Microsoft.PowerShell_profile.ps1")

	# if (Test-Path 'C:\Users\rob\Github\Windows-Sandbox') {
	# 	$funcs = $funcs + 'New-WindowsSandbox'
	# }

	# Invoke-BatchArray -Arr ($funcs | Sort-Object) -BatchSize 4 | 
	# 	ForEach-Object {
	# 		$line = ''
			
	# 		$_ | ForEach-Object {
	# 			$line += $_.PadRight(40, ' ')
	# 		}

	# 		Write-Host($line)
	# 	}

	# Write-Host ""
	#Start-Transcript -Path $History -Append -NoClobber 

	# Test-TransmissionSettings
}

function List-ProfileFunctions 
{
	Write-Host "Profile functions:"
	Write-Host ""

	$psPath = "C:\Users\Rob\OneDrive\Documents\PowerShell"
	$funcs = @();

	Get-ChildItem "$psPath\ProfileFunctions\*.ps1" |
		ForEach-Object {
			$funcs = $funcs + (Get-ScriptFunctionNames -Path "$psPath\ProfileFunctions\$($_.Name)")
		}

	$funcs = $funcs + (Get-ScriptFunctionNames -Path "$psPath\Microsoft.PowerShell_profile.ps1")

	if (Test-Path 'C:\Users\rob\Github\Windows-Sandbox') {
		$funcs = $funcs + 'New-WindowsSandbox'
	}
	
	Invoke-BatchArray -Arr ($funcs | Sort-Object) -BatchSize 4 | 
		ForEach-Object {
			for ($i = 0; $i -lt $_.Count; $i++) {
				if ($i -eq 3) {
					Write-Host($_[$i].PadRight(40, ' '))
				}
				else {
					Write-Host($_[$i].PadRight(40, ' ')) -NoNewline
				}
			}
		}

	Write-Host ""
}

<#
.SYNOPSIS
Generates a password.

.DESCRIPTION
Generates a password of a supplied length, defaulted to 8 characters.

Loops through password generation until a password matches the validation rule of 1 uppercase, 1 lowercase, 1 numeric and 1 special.

Optionally write the loop count required to fulfil the password validation rule to host.

.PARAMETER Length
Length of the generated password, defaults to 8 characters.

.PARAMETER ShowLoopCount
If present, writes the number of loops required to generate a password that fulfils the validation rule requirements.

.EXAMPLE
Generate an 8 character password.
Get-Password

.EXAMPLE
Generate a 20 character password, and write the number of passwords generated to fulfil the validation rule to host.
Get-Password -Length 20 -ShowLoopCount
#>
function Invoke-GeneratePassword {
	param (
		[Parameter(Mandatory = $false, HelpMessage = "Length of the generated password.")]
		[int]$Length = 8,

		[Parameter(Mandatory = $false, HelpMessage = "If present, writes the number of loops required to generate a password that fulfils the validation rule requirements.")]
		[switch]$ShowLoopCount
	)

	$alphabets = "abcdefghijklmnopqstuvwxyz1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#%^&*"

	$char = for ($i = 0; $i -lt $alphabets.length; $i++) { 
		$alphabets[$i] 
	}

	$password = ''
	$runCount = 1

	while (-not ($password -match '^(?=.*[A-Z])(?=.*[!@#%^&*])(?=.*[0-9])(?=.*[a-z]).{8,}$')) {
		$password = ''

		for ($i = 0; $i -le $Length; $i++) {
			$password = "$password$(get-random $char)"
		}

		$runCount++
	}

	if ($ShowLoopCount.IsPresent) {
		Write-Host "ran $runCount times"
	}

	return $password
}

# Function        New-ObjectToHashTable
function New-ObjectToHashTable {
	param([
		Parameter(Mandatory , ValueFromPipeline)]
		$object)
	process	{
		$object |
		Get-Member -MemberType *Property |
		Select-Object -ExpandProperty Name |
		Sort-Object |
		ForEach-Object { [PSCustomObject ]@{
				Item  = $_
				Value = $object. $_
			}
		}
	}
}

# Function        New-PSDrives
function New-PSDrives {
	$PSRootFolder = Select-FolderLocation
	$PSDrivePaths = Get-ChildItem -Path "$PSRootFolder\"
	foreach ($item in $PSDrivePaths) {
		$paths = Test-Path -Path $item.FullName
		if (($paths) = $true) {
			New-PSDrive -Name $item.Name -PSProvider "FileSystem" -Root $item.FullName
		}
	}
}

# Function        Select-FolderLocation
function Select-FolderLocation {
	<#
        Example.
        $directoryPath = Select-FolderLocation
        if (![string]::IsNullOrEmpty($directoryPath)) {
            Write-Host "You selected the directory: $directoryPath"
        }
        else {
            "You did not select a directory."
        }
    #>
	[Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$browse = New-Object System.Windows.Forms.FolderBrowserDialog
	$browse.SelectedPath = "C:\"
	$browse.ShowNewFolderButton = $true
	$browse.Description = "Select a directory for your report"
	$loop = $true
	while ($loop) {
		if ($browse.ShowDialog() -eq "OK") {
			$loop = $false
		}
		else {
			$res = [System.Windows.Forms.MessageBox]::Show("You clicked Cancel. Would you like to try again or exit?", "Select a location", [System.Windows.Forms.MessageBoxButtons]::RetryCancel)
			if ($res -eq "Cancel") {
				#Ends script
				return
			}
		}
	}
	$browse.SelectedPath
	$browse.Dispose()
}

# Function        Test-IsAdmin
function Test-IsAdmin {
	<#
	.Synopsis
	Tests if the user is an administrator
	.Description
	Returns true if a user is an administrator, false if the user is not an administrator
	.Example
	Test-IsAdmin
	#>
	$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
	$principal = New-Object Security.Principal.WindowsPrincipal $identity
	$principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

# Function        New-AdminShell
function New-AdminShell {
	<#
	.Synopsis
	Starts an Elevated PowerShell Console.
	.Description
	Opens a new PowerShell Console Elevated as Administrator. If the user is already running and elevated
	administrator shell, a message is printed to the screen.
	.Example
	New-AdminShell
	#>
	if (Test-IsAdmin = $True) {
		Write-Warning -Message "Admin Shell already running!"
	}
	else {
		Start-Process -FilePath "powershell.exe" -Verb runas -PassThru
	}
}

function Get-DiskInfo { wmic diskdrive get Name, Size, Model, InterfaceType, MediaType, SerialNumber }

# Set-ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

#--------------------
# Display Privileges (User/Admin) in WindowTitle
$whoami = whoami /Groups /FO CSV | ConvertFrom-Csv -Delimiter ','
$MSAccount = $whoami."Group Name" | Where-Object { $_ -like 'MicrosoftAccount*' }
$AccountType = (Get-LocalUser -Name $env:USERNAME).PrincipalSource
if ((Test-IsAdmin) -eq $true) {
	if ( $AccountType -eq 'MicrosoftAccount' ) {
		$host.UI.RawUI.WindowTitle = "$($MSAccount.Split('\')[1]) - Admin Privileges"
	}
	elseif ( $AccountType -eq 'ActiveDirectory' ) {
		$host.UI.RawUI.WindowTitle = "$("$env:USERDOMAIN" + "\" + "$env:USERNAME") - Admin Privileges"
	}
	else {
		$host.UI.RawUI.WindowTitle = "$($env:USERNAME) - Admin Privileges"
	}
}
else {
	if ( $AccountType -eq 'MicrosoftAccount' ) {
		$host.UI.RawUI.WindowTitle = "$($MSAccount.Split('\')[1]) - User Privileges"
	}
	elseif ( $AccountType -eq 'ActiveDirectory' ) {
		$host.UI.RawUI.WindowTitle = "$("$env:USERDOMAIN" + "\" + "$env:USERNAME") - User Privileges"
	}
	else {
		$host.UI.RawUI.WindowTitle = "$($env:USERNAME) - User Privileges"
	}
}

# GitRepos Path
$GitPath = "C:\Users\Rob\GitHub\"
if (Test-Path $GitPath) {
	Set-Location -Path C:\Users\Rob\GitHub
}
else {
	Set-Location -Path C:\
}

#--------------------
# Aliases

@(
	[pscustomobject]@{Name = 'Notepad++'; Value = 'C:\Program Files\Notepad++\notepad++.exe'; Desc = 'Launch Notepad++'}
	[pscustomobject]@{Name = 'vscode'; Value = 'C:\Program Files\Microsoft VS Code\Code.exe'; Desc = 'Launch VS Code'}
	[pscustomobject]@{Name = 'vs'; Value = 'C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\devenv.exe'; Desc = 'Launch VS 2019'}
) | Foreach-Object {
	if (-Not (Test-Path alias:$($_.Name))) {
		New-Alias -Name $($_.Name) -Value $($_.Value) -Description $($_.Desc)
	}
}


#--------------------
# Profile Starts here!
NewGreeting
Write-Host ""

#--------------------
# Display Profile Load time and Stop the timer
#$Stopwatch.Stop()
# End --------------#>
