REM sandbox-setup.cmd
REM This code runs in the context of the Windows Sandbox
REM Create my standard Work folder
mkdir c:\OutPutDir

REM set execution policy first so that a setup script can be run
powershell.exe -command "&{ Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser }"

REM Now run the true configuration script
powershell.exe -file C:\GitRepos\Windows-Sandbox\WSBshare\sandbox-config.ps1


