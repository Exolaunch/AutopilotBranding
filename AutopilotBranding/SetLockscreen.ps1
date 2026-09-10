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
Start-Transcript "$($env:ProgramData)\Microsoft\ExoBranding\ExoBrandingLockScreen.log"


$installFolder = "$PSScriptRoot\"
Log "Install folder: $installFolder"

# STEP 2A: Set lock screen image, see https://www.systemcenterdudes.com/apply-custom-lock-screen-wallpaper-using-intune/


try {
    Log "Configuring lock screen image"
    $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"
    Mkdir "C:\Windows\web\wallpaper\Exo" -Force | Out-Null
    $LockScreenImage = "C:\Windows\web\wallpaper\Exo\ExoLock.jpg"
    Copy-Item "$installFolder\ExoLock.jpg" $LockScreenImage -Force
    if (!(Test-Path -Path $RegPath)) {
        New-Item -Path $RegPath -Force | Out-Null
    }
    New-ItemProperty -Path $RegPath -Name LockScreenImagePath -Value $LockScreenImage -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name LockScreenImageUrl -Value $LockScreenImage -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name LockScreenImageStatus -Value 1 -PropertyType DWORD -Force | Out-Null
}
catch {
    Log "Setting lock screen image failed."
    exit 1
}

# Creating tag file
Set-Content -Path "$($env:ProgramData)\Microsoft\ExoBranding\ExoBrandingLockScreen.ps1.tag" -Value "Installed"