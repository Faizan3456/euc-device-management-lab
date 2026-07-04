<#
.SYNOPSIS
    Reports compliance state for all Intune-managed devices via Microsoft Graph.

.DESCRIPTION
    Pulls every managed device (paginated automatically by the SDK's -All switch),
    prints a summary table to the console, and exports the full data to CSV.

.NOTES
    Run Connect-Lab.ps1 first in this session.
    Requires scope: DeviceManagementManagedDevices.Read.All
#>

[CmdletBinding()]
param(
    [string]$OutputFolder = (Join-Path $PSScriptRoot 'output')
)

if (-not (Get-MgContext)) {
    Write-Error "Not connected to Microsoft Graph. Run Connect-Lab.ps1 first."
    return
}

Write-Host "Fetching managed devices from Microsoft Graph..." -ForegroundColor Cyan

# Get-MgDeviceManagementManagedDevice with -All follows @odata.nextLink automatically,
# so we get the complete device list, not just the first page.
$devices = Get-MgDeviceManagementManagedDevice -All -Property `
    "deviceName,operatingSystem,osVersion,complianceState,lastSyncDateTime,userPrincipalName,managementAgent,ownerType"

if (-not $devices -or $devices.Count -eq 0) {
    Write-Warning "No managed devices found in this tenant. Nothing to report."
    return
}

$report = $devices | ForEach-Object {
    [PSCustomObject]@{
        DeviceName       = $_.DeviceName
        OperatingSystem  = $_.OperatingSystem
        OSVersion        = $_.OsVersion
        ComplianceState  = $_.ComplianceState
        LastSyncDateTime = $_.LastSyncDateTime
        UserPrincipalName = $_.UserPrincipalName
        ManagementAgent  = $_.ManagementAgent
        OwnerType        = $_.OwnerType
    }
}

Write-Host "`n=== Device Compliance Summary ===" -ForegroundColor Green
$report |
    Sort-Object ComplianceState, DeviceName |
    Format-Table DeviceName, OperatingSystem, ComplianceState, LastSyncDateTime -AutoSize

$counts = $report | Group-Object ComplianceState | Select-Object Name, Count
Write-Host "`n=== Compliance State Breakdown ===" -ForegroundColor Green
$counts | Format-Table -AutoSize

if (-not (Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder | Out-Null
}

$csvPath = Join-Path $OutputFolder "device-compliance-report_$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
$report | Export-Csv -Path $csvPath -NoTypeInformation

Write-Host "`nFull report exported to: $csvPath" -ForegroundColor Green
