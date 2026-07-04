<#
.SYNOPSIS
    Wraps a Win32 app installer folder into a .intunewin package.

.DESCRIPTION
    Downloads Microsoft's IntuneWinAppUtil.exe if it isn't already present locally,
    then uses it to wrap a source folder (containing an installer + any support files)
    into the .intunewin format that Intune's Win32 app upload expects.

.PARAMETER SourceFolder
    Folder containing the installer and any supporting files (e.g. the 7-Zip .exe).

.PARAMETER SetupFile
    The installer file inside SourceFolder that gets executed (e.g. 7z2301-x64.exe).

.PARAMETER OutputFolder
    Where the resulting .intunewin file is written. Defaults to .\output next to this script.

.EXAMPLE
    ./package-app.ps1 -SourceFolder "C:\intune-lab\7zip-source" -SetupFile "7z2301-x64.exe"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourceFolder,

    [Parameter(Mandatory = $true)]
    [string]$SetupFile,

    [string]$OutputFolder = (Join-Path $PSScriptRoot 'output'),

    [string]$ToolsFolder = (Join-Path $PSScriptRoot 'tools')
)

$ErrorActionPreference = 'Stop'

$toolExe = Join-Path $ToolsFolder 'IntuneWinAppUtil.exe'
$toolDownloadUrl = 'https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/raw/master/IntuneWinAppUtil.exe'

if (-not (Test-Path $ToolsFolder)) {
    New-Item -ItemType Directory -Path $ToolsFolder | Out-Null
}

if (-not (Test-Path $toolExe)) {
    Write-Host "IntuneWinAppUtil.exe not found locally. Downloading from Microsoft's GitHub repo..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $toolDownloadUrl -OutFile $toolExe -UseBasicParsing
    Write-Host "Downloaded to $toolExe" -ForegroundColor Green
} else {
    Write-Host "Using existing IntuneWinAppUtil.exe at $toolExe" -ForegroundColor DarkGray
}

if (-not (Test-Path $SourceFolder)) {
    throw "SourceFolder '$SourceFolder' does not exist."
}

$setupPath = Join-Path $SourceFolder $SetupFile
if (-not (Test-Path $setupPath)) {
    throw "SetupFile '$SetupFile' was not found inside '$SourceFolder'."
}

if (-not (Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder | Out-Null
}

Write-Host "Packaging '$SetupFile' from '$SourceFolder' into a .intunewin file..." -ForegroundColor Cyan

# IntuneWinAppUtil is interactive by default; -q runs it quietly with the args below.
& $toolExe -c $SourceFolder -s $SetupFile -o $OutputFolder -q

$producedFile = Get-ChildItem -Path $OutputFolder -Filter '*.intunewin' |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if ($producedFile) {
    Write-Host "`nSuccess: $($producedFile.FullName)" -ForegroundColor Green
    Write-Host "Upload this file in Intune under Apps > Windows > Add > Win32 app." -ForegroundColor Green
} else {
    Write-Warning "No .intunewin file found in $OutputFolder — check the tool's output above for errors."
}
