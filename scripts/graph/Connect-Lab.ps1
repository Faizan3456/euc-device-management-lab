<#
.SYNOPSIS
    Connects to Microsoft Graph for the EUC device management lab using interactive auth.

.DESCRIPTION
    Requests only the scopes the lab scripts actually need (read-only), and prints
    the connected account + granted scopes so you can confirm consent worked before
    running the reporting scripts.

.NOTES
    Requires: Install-Module Microsoft.Graph -Scope CurrentUser
    Run this once per PowerShell session before Get-DeviceComplianceReport.ps1 or
    Get-NonCompliantDevices.ps1.
#>

[CmdletBinding()]
param()

$requiredScopes = @(
    'DeviceManagementManagedDevices.Read.All'
    'DeviceManagementConfiguration.Read.All'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Host "Microsoft.Graph module not found. Install it first:" -ForegroundColor Yellow
    Write-Host "  Install-Module Microsoft.Graph -Scope CurrentUser" -ForegroundColor Yellow
    return
}

Write-Host "Connecting to Microsoft Graph with scopes:" -ForegroundColor Cyan
$requiredScopes | ForEach-Object { Write-Host "  - $_" -ForegroundColor Cyan }

# Interactive sign-in: a browser window opens for auth + admin/user consent.
Connect-MgGraph -Scopes $requiredScopes -NoWelcome

$context = Get-MgContext

if (-not $context) {
    Write-Error "Connect-MgGraph did not return a context. Connection failed."
    return
}

Write-Host "`nConnected." -ForegroundColor Green
Write-Host "Account:   $($context.Account)"
Write-Host "Tenant Id: $($context.TenantId)"
Write-Host "Scopes granted:"
$context.Scopes | ForEach-Object { Write-Host "  - $_" }

$missing = $requiredScopes | Where-Object { $_ -notin $context.Scopes }
if ($missing) {
    Write-Warning "Missing expected scopes: $($missing -join ', '). Reporting scripts may fail with a 403."
} else {
    Write-Host "`nAll required scopes granted. Ready to run the reporting scripts." -ForegroundColor Green
}
