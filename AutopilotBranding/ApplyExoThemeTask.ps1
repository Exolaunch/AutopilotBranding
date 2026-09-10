$taskName = "Apply Exo Theme"
$themePath = "C:\Windows\Resources\OEM Themes\Exo.theme"
$powerShellPath = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
$userAccount = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

$action = New-ScheduledTaskAction `
    -Execute $powerShellPath `
    -Argument "-NoProfile -WindowStyle Hidden -Command `"Start-Process -FilePath '$themePath'; Start-Sleep -Seconds 5; Unregister-ScheduledTask -TaskName '$taskName' -Confirm:`$false`""
$principal = New-ScheduledTaskPrincipal `
    -UserId $userAccount `
    -LogonType Interactive

Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Principal $principal `
    -Force | Out-Null

Start-ScheduledTask -TaskName $taskName
