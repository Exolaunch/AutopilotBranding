function Log() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)] [String] $message
    )

    $ts = get-date -f "yyyy/MM/dd hh:mm:ss tt"
    Write-Output "$ts $message"
}

# Get the Current start time in UTC format, so that Time Zone Changes don't affect total runtime calculation
$startUtc = [datetime]::UtcNow

# Don't show progress bar for Add-AppxPackage - there's a weird issue where the progress stays on the screen after the apps are installed
$OriginalProgressPreference = $ProgressPreference
$ProgressPreference = 'SilentlyContinue'

# If we are running as a 32-bit process on an x64 system, re-launch as a 64-bit process
if ("$env:PROCESSOR_ARCHITEW6432" -ne "ARM64") {
    if (Test-Path "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe") {
        & "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy bypass -NoProfile -File "$PSCommandPath"
        Exit $lastexitcode
    }
}

# Create output folder
if (-not (Test-Path "$($env:ProgramData)\Microsoft\ExoBranding")) {
    Mkdir "$($env:ProgramData)\Microsoft\ExoBranding" -Force
}

# Start logging
Start-Transcript "$($env:ProgramData)\Microsoft\ExoBranding\ExoBrandingTheme.log"

$installFolder = "$PSScriptRoot\"
Log "Install folder: $installFolder"

try {
    # PREP: Load the stuff
    $installFolder = "$PSScriptRoot\"
    Log "Install folder: $installFolder"
    
    $userAccount = (Get-CimInstance Win32_ComputerSystem).UserName
    Log "User account is $userAccount"
    $userName = $userAccount.Split('\')[-1]
    Log "Username is $userName."
    $profile = Get-CimInstance Win32_UserProfile |
    Where-Object {
        $_.Loaded -and
        -not $_.Special -and
        (Split-Path $_.LocalPath -Leaf) -eq $userName
    } |
    Select-Object -First 1
    Log "Profile is $profile."
    
    # PREP: Load the default user registry
    
    $registryRoot = "HKU\$($profile.SID)"
    Log "User Registry root is $registryRoot"
    # STEP 2: Configure background
    Log "Setting up Exo theme"
    Mkdir "C:\Windows\Resources\OEM Themes" -Force | Out-Null
    Copy-Item "$installFolder\Exo.theme" "C:\Windows\Resources\OEM Themes\Exo.theme" -Force
    Mkdir "C:\Windows\web\wallpaper\Exo" -Force | Out-Null
    Copy-Item "$installFolder\Exo.jpg" "C:\Windows\web\wallpaper\Exo\Exo.jpg" -Force
    Log "Setting Exo theme as the user default"
    & reg.exe add "$registryRoot\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes" /v InstallTheme /t REG_EXPAND_SZ /d "%SystemRoot%\resources\OEM Themes\Exo.theme" /f /reg:64 2>&1 | Out-Null
    & reg.exe add "$registryRoot\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes" /v CurrentTheme /t REG_EXPAND_SZ /d "%SystemRoot%\resources\OEM Themes\Exo.theme" /f /reg:64 2>&1 | Out-Null
    $taskName = "Apply Exo Theme"
    $themePath = "C:\Windows\Resources\OEM Themes\Exo.theme"

    $action = New-ScheduledTaskAction `
        -Execute "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" `
        -Argument "-NoProfile -WindowStyle Hidden -Command `"Start-Process -FilePath '$themePath'`""

    $principal = New-ScheduledTaskPrincipal `
        -UserId $userAccount `
        -LogonType Interactive `

    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Principal $principal `
        -Force 

    Start-ScheduledTask -TaskName $taskName
    Start-Sleep -Seconds 5
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false

    Set-Content -Path "$($env:ProgramData)\Microsoft\ExoBranding\ExoBrandingTheme.ps1.tag" -Value "Installed"
}
catch {
    Log "Failed to set Exo theme"
    Stop-Transcript
}
# Creating tag file
Stop-Transcript
