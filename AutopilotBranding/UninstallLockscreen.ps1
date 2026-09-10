function Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)] [string] $Message
    )

    $timestamp = Get-Date -Format "yyyy/MM/dd hh:mm:ss tt"
    Write-Output "$timestamp $Message"
}

# If we are running as a 32-bit process on an x64 system, re-launch as a 64-bit process
if ("$env:PROCESSOR_ARCHITEW6432" -ne "ARM64") {
    if (Test-Path "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe") {
        & "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy bypass -NoProfile -File "$PSCommandPath"
        Exit $lastexitcode
    }
}



$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"
$tag = "$($env:ProgramData)\Microsoft\ExoBranding\ExoBrandingLockScreen.ps1.tag"
$logPath = "$($env:ProgramData)\Microsoft\ExoBranding\ExoBrandingLockScreenUninstall.log"

Start-Transcript -Path $logPath
try {
    Log "Clearing lock-screen registry values from $RegPath"
    Remove-ItemProperty -Path $RegPath -Name LockScreenImagePath, LockScreenImageUrl, LockScreenImageStatus -ErrorAction Stop
    Log "Lock-screen registry values cleared"

    Log "Removing tag file $tag"
    Remove-Item -Path $tag -Force -ErrorAction Stop
    Log "Tag file removed"
}
catch {
    Log "Lock-screen uninstall failed: $_"
    throw
}
finally {
    Stop-Transcript
}
