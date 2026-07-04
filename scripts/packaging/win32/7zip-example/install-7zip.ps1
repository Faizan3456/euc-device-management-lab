<#
.SYNOPSIS
    Reference notes for the 7-Zip Win32 app install command used in Intune.

.DESCRIPTION
    Intune's Win32 app "Program" tab wants a plain install COMMAND, not a script,
    so the real value entered in Intune is just the one-liner below. This file
    exists so the command and its reasoning are documented in source control,
    and so it can be tested locally before pasting into Intune.
#>

# Install command to enter in Intune (Apps > Windows > Win32 app > Program > Install command):
#
#   7z2301-x64.exe /S
#
# /S = silent install, no UI, no reboot prompt. This is 7-Zip's NSIS-based silent switch.
# Always confirm the correct silent switch from the vendor - NSIS uses /S, InstallShield
# uses /s /v"/qn", MSI-based installers use msiexec /i ... /qn. Guessing wrong is the
# #1 cause of a Win32 app that "installs" in testing but the assignment shows as failed
# for real users (because the silent flag actually shows a UI that no one dismisses).

Write-Host "This is a reference file, not meant to be run directly."
Write-Host "Install command for Intune: 7z2301-x64.exe /S"
