<#
.SYNOPSIS
    Reports noncompliant devices and the specific policy each one is failing.

.DESCRIPTION
    Filters managed devices down to complianceState = 'noncompliant', then queries
    each device's compliance policy states so we can show *why* it's noncompliant,
    not just that it is. That's the difference between a report a helpdesk can act
    on and one that just says "red".

.NOTES
    Run Connect-Lab.ps1 first in this session.
    Requires scopes: DeviceManagementManagedDevices.Read.All, DeviceManagementConfiguration.Read.All
#>

[CmdletBinding()]
param(
    [string]$OutputFolder = (Join-Path $PSScriptRoot 'output')
)

if (-not (Get-MgContext)) {
    Write-Error "Not connected to Microsoft Graph. Run Connect-Lab.ps1 first."
    return
}

Write-Host "Fetching noncompliant managed devices..." -ForegroundColor Cyan

$allDevices = Get-MgDeviceManagementManagedDevice -All -Property `
    "id,deviceName,operatingSystem,complianceState,lastSyncDateTime,userPrincipalName"

$nonCompliant = $allDevices | Where-Object { $_.ComplianceState -eq 'noncompliant' }

if (-not $nonCompliant -or $nonCompliant.Count -eq 0) {
    Write-Host "No noncompliant devices found. Fleet is clean." -ForegroundColor Green
    return
}

Write-Host "Found $($nonCompliant.Count) noncompliant device(s). Checking failing policies..." -ForegroundColor Cyan

$results = foreach ($device in $nonCompliant) {

    # Per-device compliance policy states tell us exactly which policy failed,
    # e.g. "Lab-Compliance-Windows" with state 'nonCompliant', vs a generic red flag.
    $policyStates = Get-MgDeviceManagementManagedDeviceCompliancePolicyState `
        -ManagedDeviceId $device.Id -ErrorAction SilentlyContinue

    $failingPolicies = $policyStates | Where-Object { $_.State -eq 'nonCompliant' }

    if ($failingPolicies) {
        foreach ($policy in $failingPolicies) {
            [PSCustomObject]@{
                DeviceName       = $device.DeviceName
                OperatingSystem  = $device.OperatingSystem
                UserPrincipalName = $device.UserPrincipalName
                LastSyncDateTime = $device.LastSyncDateTime
                FailingPolicy    = $policy.DisplayName
                PolicyState      = $policy.State
            }
        }
    } else {
        # Device is flagged noncompliant overall but policy-state detail wasn't available
        # (e.g. permissions, timing, or the policy check hasn't run yet).
        [PSCustomObject]@{
            DeviceName       = $device.DeviceName
            OperatingSystem  = $device.OperatingSystem
            UserPrincipalName = $device.UserPrincipalName
            LastSyncDateTime = $device.LastSyncDateTime
            FailingPolicy    = "(policy detail unavailable)"
            PolicyState      = "noncompliant"
        }
    }
}

Write-Host "`n=== Noncompliant Devices - Failing Policy Detail ===" -ForegroundColor Yellow
$results | Format-Table DeviceName, OperatingSystem, FailingPolicy, LastSyncDateTime -AutoSize

if (-not (Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder | Out-Null
}

$csvPath = Join-Path $OutputFolder "noncompliant-devices_$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
$results | Export-Csv -Path $csvPath -NoTypeInformation

Write-Host "`nReport exported to: $csvPath" -ForegroundColor Green
