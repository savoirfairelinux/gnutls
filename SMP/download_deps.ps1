[CmdletBinding()]
param(
    [string]$TargetDir = "$PSScriptRoot\..\..\prebuilt",
    [int]$MsvcVer = 17,
    [string]$GitHubToken = $env:GITHUB_TOKEN
)

$ErrorActionPreference = 'Stop'

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13

$TargetDir = [System.IO.Path]::GetFullPath($TargetDir)
Write-Host "Prebuilt destination directory: $TargetDir"
if (-not (Test-Path -Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
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

Write-Host "All dependencies downloaded and extracted successfully."
