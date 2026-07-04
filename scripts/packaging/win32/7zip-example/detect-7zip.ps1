<#
.SYNOPSIS
    Custom detection script for the 7-Zip Win32 app in Intune.

.DESCRIPTION
    Intune's Win32 app "Detection rules" tab can use a built-in rule (MSI product
    code, file version/existence, registry value) or a custom PowerShell script.
    This uses a custom script so the logic is explicit and version-aware.

    Detection logic:
      1. Look up the app's uninstall registry key under both the 64-bit and
         32-bit uninstall hives (7-Zip is a 64-bit app here, but checking both
         is a good habit since Intune runs detection in a 32-bit PowerShell host
         by default unless you configure it otherwise).
      2. Confirm DisplayName matches "7-Zip".
      3. Confirm DisplayVersion is present (so future runs can be extended to
         check for a *minimum* version, enabling supersedence/upgrade detection).

.NOTES
    Intune requirement: a detection script must write to STDOUT and exit 0 to be
    considered "detected" (installed). Any STDOUT output + exit 0 = detected.
    No output, or a non-zero exit code = not detected. Do NOT use Write-Host here -
    Intune only reads STDOUT via Write-Output, not the host UI stream.
#>

$appName = "7-Zip"

$uninstallKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$installed = Get-ItemProperty -Path $uninstallKeys -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -eq $appName }

if ($installed -and $installed.DisplayVersion) {
    # Detected: write anything to STDOUT and exit 0.
    Write-Output "Detected $appName version $($installed.DisplayVersion)"
    exit 0
} else {
    # Not detected: no output, non-zero exit.
    exit 1
}
