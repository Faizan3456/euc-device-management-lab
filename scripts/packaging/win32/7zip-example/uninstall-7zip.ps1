<#
.SYNOPSIS
    Reference notes for the 7-Zip Win32 app uninstall command used in Intune.

.DESCRIPTION
    Like install-7zip.ps1, this documents the plain uninstall COMMAND entered into
    Intune's Program tab, rather than being a script that Intune executes directly.
#>

# Uninstall command to enter in Intune (Apps > Windows > Win32 app > Program > Uninstall command):
#
#   "C:\Program Files\7-Zip\Uninstall.exe" /S
#
# 7-Zip ships its own Uninstall.exe rather than routing through msiexec, so the
# uninstall command points directly at it with the same silent switch as install.
# Always verify the exact path and switch against a real installed copy of the app -
# uninstall paths differ from install paths more often than you'd expect.

Write-Host "This is a reference file, not meant to be run directly."
Write-Host 'Uninstall command for Intune: "C:\Program Files\7-Zip\Uninstall.exe" /S'
