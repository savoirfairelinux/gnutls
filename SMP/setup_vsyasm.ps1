[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13

$zipPath = "$env:TEMP\VSYASM.zip"
$extractDir = "$env:TEMP\VSYASM"

Write-Host "Downloading VSYASM from ShiftMediaProject..."
Invoke-WebRequest -Uri 'https://github.com/ShiftMediaProject/VSYASM/releases/download/0.7/VSYASM.zip' -OutFile $zipPath

if (Test-Path $extractDir) {
    Remove-Item -Path $extractDir -Recurse -Force
}
Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force

# Locate VS 2022 VC and MSBuild paths using vswhere
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vswhere)) {
    Write-Error "vswhere.exe not found at $vswhere"
    exit 1
}

$vsInstallPath = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $vsInstallPath) {
    Write-Error "Visual Studio installation path not found"
    exit 1
}
Write-Host "Found Visual Studio installation at: $vsInstallPath"

# Find BuildCustomizations directory
$targets = Get-ChildItem -Path "$vsInstallPath\MSBuild\Microsoft\VC" -Recurse -Filter "BuildCustomizations" -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
if (-not $targets) {
    $targets = @("$vsInstallPath\MSBuild\Microsoft\VC\v170\BuildCustomizations")
}

foreach ($target in $targets) {
    Write-Host "Installing VSYASM customization files into: $target"
    if (-not (Test-Path $target)) {
        New-Item -ItemType Directory -Path $target -Force | Out-Null
    }
    Copy-Item -Path "$extractDir\yasm.props" -Destination $target -Force
    Copy-Item -Path "$extractDir\yasm.targets" -Destination $target -Force
    Copy-Item -Path "$extractDir\yasm.xml" -Destination $target -Force
}

# Find MSVC Tools directory (where cl.exe, link.exe etc live)
$vcToolsVersion = Get-Content "$vsInstallPath\VC\Auxiliary\Build\Microsoft.VCToolsVersion.default.txt" -ErrorAction SilentlyContinue
if ($vcToolsVersion) {
    $vcToolsVersion = $vcToolsVersion.Trim()
}
$vcToolsDirs = @()
if ($vcToolsVersion -and (Test-Path "$vsInstallPath\VC\Tools\MSVC\$vcToolsVersion")) {
    $vcToolsDirs += "$vsInstallPath\VC\Tools\MSVC\$vcToolsVersion"
} else {
    $vcToolsDirs += Get-ChildItem -Path "$vsInstallPath\VC\Tools\MSVC" -Directory | Select-Object -ExpandProperty FullName
}

$yasm64Exe = "$extractDir\yasm\yasm-64.exe"
$yasm32Exe = "$extractDir\yasm\yasm-32.exe"

# Copy yasm.exe directly to $(VCInstallDir) which is $vsInstallPath\VC
Write-Host "Installing yasm.exe into VC root: $vsInstallPath\VC"
Copy-Item -Path $yasm64Exe -Destination "$vsInstallPath\VC\yasm.exe" -Force -ErrorAction SilentlyContinue

foreach ($toolDir in $vcToolsDirs) {
    Write-Host "Installing yasm.exe into: $toolDir"
    Copy-Item -Path $yasm64Exe -Destination "$toolDir\bin\Hostx64\x64\yasm.exe" -Force -ErrorAction SilentlyContinue
    Copy-Item -Path $yasm64Exe -Destination "$toolDir\bin\Hostx64\x86\yasm.exe" -Force -ErrorAction SilentlyContinue
    Copy-Item -Path $yasm32Exe -Destination "$toolDir\bin\Hostx86\x86\yasm.exe" -Force -ErrorAction SilentlyContinue
    Copy-Item -Path $yasm32Exe -Destination "$toolDir\bin\Hostx86\x64\yasm.exe" -Force -ErrorAction SilentlyContinue
    Copy-Item -Path $yasm64Exe -Destination "$toolDir\yasm.exe" -Force -ErrorAction SilentlyContinue
}

# Also copy into Windows System32 and directory on PATH
Copy-Item -Path $yasm64Exe -Destination "C:\Windows\System32\yasm.exe" -Force -ErrorAction SilentlyContinue

Write-Host "VSYASM setup complete."
