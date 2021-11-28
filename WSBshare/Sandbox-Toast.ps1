#sandbox-toast.ps1
$params = @{
    Text = "Windows Sandbox configuration is complete."
    Header = $(New-BTHeader -Id 1 -Title "Sandbox Complete")
    Applogo = "C:\GitRepos\Windows-Sandbox\WSBshare\ToastIcon.jpg"
}

New-BurntToastNotification @params
