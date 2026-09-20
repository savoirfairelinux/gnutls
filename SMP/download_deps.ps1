[CmdletBinding()]
param(
    [string]$TargetDir = "",
    [int]$MsvcVer = 17,
    [string]$GitHubToken = $env:GITHUB_TOKEN
)

$ErrorActionPreference = 'Stop'

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13

$smpDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$repoDir = (Resolve-Path (Join-Path $smpDir "..")).Path
$repoParentDir = (Resolve-Path (Join-Path $repoDir "..")).Path

$repoPrebuiltDir = Join-Path $repoDir "prebuilt"
$siblingPrebuiltDir = Join-Path $repoParentDir "prebuilt"

if (-not $TargetDir) {
    $TargetDir = $repoPrebuiltDir
}
$TargetDir = [System.IO.Path]::GetFullPath($TargetDir)

Write-Host "Prebuilt destination directory: $TargetDir"
if (-not (Test-Path -Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
}
if (-not (Test-Path -Path $siblingPrebuiltDir)) {
    New-Item -ItemType Directory -Path $siblingPrebuiltDir -Force | Out-Null
}

$deps = @('nettle', 'gmp', 'zlib')

$headers = @{
    'User-Agent' = 'SMP-Dependency-Downloader'
}
if ($GitHubToken) {
    $headers['Authorization'] = "token $GitHubToken"
}

foreach ($dep in $deps) {
    Write-Host "Fetching latest release information for ${dep}..."
    $apiUrl = "https://api.github.com/repos/ShiftMediaProject/$dep/releases/latest"
    try {
        $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
    } catch {
        Write-Error "Failed to fetch latest release metadata for ${dep}. Error: $_"
        exit 1
    }

    $assetNamePattern = "*msvc$MsvcVer.zip"
    $matchingAsset = $release.assets | Where-Object { $_.name -like $assetNamePattern } | Select-Object -First 1

    if (-not $matchingAsset) {
        Write-Error "No matching asset ending in 'msvc$MsvcVer.zip' found for $dep in release $($release.tag_name)"
        exit 1
    }

    $downloadUrl = $matchingAsset.browser_download_url
    $tempZip = Join-Path -Path $TargetDir -ChildPath "$($matchingAsset.name)"
    Write-Host "Downloading $($matchingAsset.name) from $downloadUrl..."
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZip -Headers @{ 'User-Agent' = 'SMP-Dependency-Downloader' }
    } catch {
        Write-Error "Failed downloading ${downloadUrl}. Error: $_"
        exit 1
    }

    Write-Host "Extracting $($matchingAsset.name) to $TargetDir..."
    try {
        Expand-Archive -Path $tempZip -DestinationPath $TargetDir -Force
    } catch {
        Write-Error "Failed extracting ${tempZip}. Error: $_"
        exit 1
    } finally {
        if (Test-Path -Path $tempZip) {
            Remove-Item -Path $tempZip -Force
        }
    }
}

# Fix SMP nettle release packaging bug where version.h contains floating-point versions:
#   #define NETTLE_VERSION_MAJOR 3.10
#   #define NETTLE_VERSION_MINOR 10.1
# MSVC rejects floating-point numbers in preprocessor #if conditionals with error C1017.
$nettleVerH = Join-Path $TargetDir "include\nettle\version.h"
if (Test-Path $nettleVerH) {
    Write-Host "Sanitizing $nettleVerH for integer version macros..."
    $content = Get-Content $nettleVerH -Raw
    $content = $content -replace '(?m)^(\s*#\s*define\s+NETTLE_VERSION_MAJOR\s+)([0-9]+)\.[0-9]+', '$1$2'
    $content = $content -replace '(?m)^(\s*#\s*define\s+NETTLE_VERSION_MINOR\s+)([0-9]+)\.[0-9]+', '$1$2'
    Set-Content -Path $nettleVerH -Value $content
}

# Create debug library aliases (*d.lib) from release libraries
foreach ($libName in @('hogweed', 'libhogweed', 'nettle', 'libnettle', 'gmp', 'libgmp', 'zlib', 'libzlib')) {
    Get-ChildItem -Path $TargetDir -Recurse -Filter "${libName}.lib" | ForEach-Object {
        $debugPath = Join-Path $_.DirectoryName "${libName}d.lib"
        if (-not (Test-Path $debugPath)) {
            Write-Host "Creating debug lib alias: ${libName}d.lib in $($_.DirectoryName)"
            Copy-Item -Path $_.FullName -Destination $debugPath -Force
        }
    }
}

# Mirror prebuilt to sibling and repo directories to satisfy all possible MSBuild relative paths
foreach ($mirrorDir in @($siblingPrebuiltDir, $repoPrebuiltDir)) {
    $fullMirror = [System.IO.Path]::GetFullPath($mirrorDir)
    if ($fullMirror -ne $TargetDir) {
        Write-Host "Mirroring prebuilt to $fullMirror..."
        if (-not (Test-Path -Path $fullMirror)) {
            New-Item -ItemType Directory -Path $fullMirror -Force | Out-Null
        }
        Copy-Item -Path "$TargetDir\*" -Destination $fullMirror -Recurse -Force
    }
}

Write-Host "All dependencies downloaded and extracted successfully."
