#Requires -Version 5.1

<#
.SYNOPSIS
Downloads third-party Kansa helper binaries into their expected locations.

.DESCRIPTION
This script rebuilds the third-party tool layout expected by the current Kansa
modules without requiring those vendor binaries to be committed to source
control.

It downloads from official vendor locations where a direct download is
available. Memoryze is not downloaded automatically because the vendor download
flow does not expose a stable direct download URL; provide -MemoryzeZipPath if
you have downloaded it separately.

.PARAMETER KansaRoot
Path to the Kansa repository root. Defaults to the folder containing this script.

.PARAMETER MemoryzeZipPath
Optional path to a separately downloaded Memoryze zip. It will be copied to
Modules\bin\memoryze.zip.

.PARAMETER Force
Overwrite existing binaries.

.EXAMPLE
.\Install-KansaThirdPartyBinaries.ps1 -Force

.EXAMPLE
.\Install-KansaThirdPartyBinaries.ps1 -MemoryzeZipPath C:\Downloads\memoryze.zip
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$KansaRoot = $PSScriptRoot,

    [Parameter(Mandatory = $false)]
    [string]$MemoryzeZipPath,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$KansaRoot = (Resolve-Path -LiteralPath $KansaRoot).Path
$BinDir = Join-Path $KansaRoot 'Modules\bin'
$TempRoot = Join-Path ([IO.Path]::GetTempPath()) ("kansa-third-party-" + [guid]::NewGuid())
$UserAgent = 'Kansa third-party binary installer'
$Installed = New-Object System.Collections.Generic.List[string]
$Warnings = New-Object System.Collections.Generic.List[string]

function New-Directory {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }
}

function Write-Step {
    param([Parameter(Mandatory = $true)][string]$Message)

    Write-Host ">> $Message"
}

function Save-Download {
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][string]$OutFile
    )

    Write-Verbose "Downloading $Uri"
    Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing -UserAgent $UserAgent
    return $OutFile
}

function Expand-ZipArchive {
    param(
        [Parameter(Mandatory = $true)][string]$ArchivePath,
        [Parameter(Mandatory = $true)][string]$DestinationPath
    )

    New-Directory $DestinationPath
    Expand-Archive -LiteralPath $ArchivePath -DestinationPath $DestinationPath -Force
}

function Copy-ExpectedFile {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath,
        [Parameter(Mandatory = $true)][string]$DestinationPath,
        [Parameter(Mandatory = $false)][string]$DisplayName = (Split-Path -Leaf $DestinationPath)
    )

    if ((Test-Path -LiteralPath $DestinationPath -PathType Leaf) -and -not $Force) {
        Write-Verbose "Skipping existing $DestinationPath"
        return
    }

    New-Directory (Split-Path -Parent $DestinationPath)
    Copy-Item -LiteralPath $SourcePath -Destination $DestinationPath -Force
    $Installed.Add($DisplayName) | Out-Null
}

function Find-OneFile {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Filter
    )

    $match = Get-ChildItem -LiteralPath $Root -Recurse -File -Filter $Filter | Select-Object -First 1
    if (-not $match) {
        throw "Unable to find '$Filter' under '$Root'."
    }

    return $match.FullName
}

function Get-GitHubLatestAsset {
    param(
        [Parameter(Mandatory = $true)][string]$Repository,
        [Parameter(Mandatory = $true)][string]$AssetRegex
    )

    $apiUri = "https://api.github.com/repos/$Repository/releases/latest"
    $release = Invoke-RestMethod -Uri $apiUri -Headers @{ 'User-Agent' = $UserAgent }
    $asset = $release.assets |
        Where-Object { $_.name -match $AssetRegex } |
        Sort-Object -Property name |
        Select-Object -First 1

    if (-not $asset) {
        throw "No release asset matching '$AssetRegex' was found for $Repository."
    }

    return $asset.browser_download_url
}

function Expand-With7Zip {
    param(
        [Parameter(Mandatory = $true)][string]$SevenZipPath,
        [Parameter(Mandatory = $true)][string]$ArchivePath,
        [Parameter(Mandatory = $true)][string]$DestinationPath
    )

    New-Directory $DestinationPath
    & $SevenZipPath x $ArchivePath "-o$DestinationPath" -y | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "7-Zip extraction failed for '$ArchivePath'."
    }
}

function Install-7Zip {
    Write-Step 'Installing 7-Zip console files'

    $work = Join-Path $TempRoot '7zip'
    New-Directory $work

    $bootstrap7zr = Join-Path $work '7zr.exe'
    $installer = Join-Path $work '7z2601-x64.exe'
    $extractDir = Join-Path $work 'extract'

    Save-Download -Uri 'https://www.7-zip.org/a/7zr.exe' -OutFile $bootstrap7zr | Out-Null
    Save-Download -Uri 'https://www.7-zip.org/a/7z2601-x64.exe' -OutFile $installer | Out-Null
    Expand-With7Zip -SevenZipPath $bootstrap7zr -ArchivePath $installer -DestinationPath $extractDir

    $sevenZipExe = Find-OneFile -Root $extractDir -Filter '7z.exe'
    $sevenZipDll = Find-OneFile -Root $extractDir -Filter '7z.dll'

    Copy-ExpectedFile -SourcePath $sevenZipExe -DestinationPath (Join-Path $KansaRoot '7z.exe') -DisplayName '7z.exe (root)'
    Copy-ExpectedFile -SourcePath $sevenZipDll -DestinationPath (Join-Path $KansaRoot '7z.dll') -DisplayName '7z.dll (root)'
    Copy-ExpectedFile -SourcePath $sevenZipExe -DestinationPath (Join-Path $BinDir '7z.exe') -DisplayName 'Modules\bin\7z.exe'
    Copy-ExpectedFile -SourcePath $sevenZipDll -DestinationPath (Join-Path $BinDir '7z.dll') -DisplayName 'Modules\bin\7z.dll'

    $sevenZipZip = Join-Path $BinDir '7z.zip'
    if ((-not (Test-Path -LiteralPath $sevenZipZip -PathType Leaf)) -or $Force) {
        $zipStaging = Join-Path $work 'zip-staging'
        New-Directory $zipStaging
        Copy-Item -LiteralPath $sevenZipExe -Destination (Join-Path $zipStaging '7z.exe') -Force
        Copy-Item -LiteralPath $sevenZipDll -Destination (Join-Path $zipStaging '7z.dll') -Force
        Compress-Archive -Path (Join-Path $zipStaging '*') -DestinationPath $sevenZipZip -Force
        $Installed.Add('Modules\bin\7z.zip') | Out-Null
    }
}

function Install-SysinternalsArchive {
    param(
        [Parameter(Mandatory = $true)][string]$ArchiveName,
        [Parameter(Mandatory = $false)][string[]]$FallbackArchiveNames = @(),
        [Parameter(Mandatory = $true)][hashtable]$FileMap
    )

    Write-Step "Installing Sysinternals $ArchiveName"

    $work = Join-Path $TempRoot ("sysinternals-" + [IO.Path]::GetFileNameWithoutExtension($ArchiveName))
    $extractDir = Join-Path $work 'extract'
    New-Directory $work

    $downloaded = $false
    $zipPath = $null
    foreach ($candidateName in @($ArchiveName) + $FallbackArchiveNames) {
        $candidatePath = Join-Path $work $candidateName
        try {
            Save-Download -Uri "https://download.sysinternals.com/files/$candidateName" -OutFile $candidatePath | Out-Null
            $zipPath = $candidatePath
            $downloaded = $true
            break
        }
        catch {
            Write-Verbose "Unable to download Sysinternals archive '$candidateName'. $($_.Exception.Message)"
        }
    }

    if (-not $downloaded) {
        throw "Unable to download Sysinternals archive '$ArchiveName'. Tried: $((@($ArchiveName) + $FallbackArchiveNames) -join ', ')."
    }

    Expand-ZipArchive -ArchivePath $zipPath -DestinationPath $extractDir

    foreach ($sourceName in $FileMap.Keys) {
        $sourcePath = Find-OneFile -Root $extractDir -Filter $sourceName
        $destinationName = $FileMap[$sourceName]
        Copy-ExpectedFile -SourcePath $sourcePath -DestinationPath (Join-Path $BinDir $destinationName) -DisplayName "Modules\bin\$destinationName"
    }
}

function Install-NirSoftTool {
    param(
        [Parameter(Mandatory = $true)][string]$ZipName,
        [Parameter(Mandatory = $true)][string]$ExecutableName
    )

    Write-Step "Installing NirSoft $ExecutableName"

    $work = Join-Path $TempRoot ("nirsoft-" + [IO.Path]::GetFileNameWithoutExtension($ZipName))
    $zipPath = Join-Path $work $ZipName
    $extractDir = Join-Path $work 'extract'
    New-Directory $work

    Save-Download -Uri "https://www.nirsoft.net/utils/$ZipName" -OutFile $zipPath | Out-Null
    Expand-ZipArchive -ArchivePath $zipPath -DestinationPath $extractDir

    $sourcePath = Find-OneFile -Root $extractDir -Filter $ExecutableName
    Copy-ExpectedFile -SourcePath $sourcePath -DestinationPath (Join-Path $BinDir $ExecutableName) -DisplayName "Modules\bin\$ExecutableName"
}

function Install-AppCompatCacheParser {
    Write-Step 'Installing AppCompatCacheParser'

    $work = Join-Path $TempRoot 'appcompatcacheparser'
    $zipPath = Join-Path $work 'AppCompatCacheParser.zip'
    $extractDir = Join-Path $work 'extract'
    New-Directory $work

    $assetUrl = 'https://download.ericzimmermanstools.com/AppCompatCacheParser.zip'
    Save-Download -Uri $assetUrl -OutFile $zipPath | Out-Null
    Expand-ZipArchive -ArchivePath $zipPath -DestinationPath $extractDir

    $sourcePath = Find-OneFile -Root $extractDir -Filter 'AppCompatCacheParser.exe'
    Copy-ExpectedFile -SourcePath $sourcePath -DestinationPath (Join-Path $BinDir 'AppCompatCacheParser.exe') -DisplayName 'Modules\bin\AppCompatCacheParser.exe'
}

function Install-WinPmem {
    Write-Step 'Installing WinPmem'

    $work = Join-Path $TempRoot 'winpmem'
    New-Directory $work

    $assetUrl = Get-GitHubLatestAsset -Repository 'Velocidex/WinPmem' -AssetRegex '(?i)winpmem.*\.exe$'
    $downloadPath = Join-Path $work (Split-Path -Leaf ([Uri]$assetUrl).AbsolutePath)
    Save-Download -Uri $assetUrl -OutFile $downloadPath | Out-Null
    Copy-ExpectedFile -SourcePath $downloadPath -DestinationPath (Join-Path $BinDir 'winpmem-2.1.post4.exe') -DisplayName 'Modules\bin\winpmem-2.1.post4.exe'
}

function Install-XpdfPdfToText {
    Write-Step 'Installing Xpdf pdftotext'

    $work = Join-Path $TempRoot 'xpdf'
    $zipPath = Join-Path $work 'xpdf-tools-win-4.06.zip'
    $extractDir = Join-Path $work 'extract'
    New-Directory $work

    Save-Download -Uri 'https://dl.xpdfreader.com/xpdf-tools-win-4.06.zip' -OutFile $zipPath | Out-Null
    Expand-ZipArchive -ArchivePath $zipPath -DestinationPath $extractDir

    $sourcePath = Find-OneFile -Root (Join-Path $extractDir 'xpdf-tools-win-4.06\bin64') -Filter 'pdftotext.exe'
    Copy-ExpectedFile -SourcePath $sourcePath -DestinationPath (Join-Path $BinDir 'pdftotext.exe') -DisplayName 'Modules\bin\pdftotext.exe'
}

function New-PiiZip {
    Write-Step 'Creating pii.zip helper package'

    $required = @('7z.exe', '7z.dll', 'pdftotext.exe')
    foreach ($file in $required) {
        $path = Join-Path $BinDir $file
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Cannot create pii.zip because '$path' is missing."
        }
    }

    $destination = Join-Path $BinDir 'pii.zip'
    if ((Test-Path -LiteralPath $destination -PathType Leaf) -and -not $Force) {
        return
    }

    $staging = Join-Path $TempRoot 'pii-staging'
    New-Directory $staging
    foreach ($file in $required) {
        Copy-Item -LiteralPath (Join-Path $BinDir $file) -Destination (Join-Path $staging $file) -Force
    }

    @'
This package is generated by Install-KansaThirdPartyBinaries.ps1.
It contains helper tools used by Kansa PII audit modules:
- 7-Zip console files from https://www.7-zip.org/
- Xpdf pdftotext from https://www.xpdfreader.com/

Review each upstream license before redistributing this package.
'@ | Set-Content -Path (Join-Path $staging 'THIRD_PARTY_NOTICE.txt') -Encoding ASCII

    Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $destination -Force
    $Installed.Add('Modules\bin\pii.zip') | Out-Null
}

function Install-Memoryze {
    if ([string]::IsNullOrWhiteSpace($MemoryzeZipPath)) {
        $Warnings.Add('Memoryze was not downloaded automatically. Download it from FireEye/Trellix Market and rerun with -MemoryzeZipPath <path>.') | Out-Null
        return
    }

    $resolved = Resolve-Path -LiteralPath $MemoryzeZipPath
    Copy-ExpectedFile -SourcePath $resolved.Path -DestinationPath (Join-Path $BinDir 'memoryze.zip') -DisplayName 'Modules\bin\memoryze.zip'
}

function Invoke-InstallStep {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][scriptblock]$ScriptBlock
    )

    try {
        & $ScriptBlock
    }
    catch {
        $Warnings.Add("$Name was not installed. $($_.Exception.Message)") | Out-Null
        Write-Warning "$Name was not installed. Continuing with remaining tools."
    }
}

try {
    New-Directory $BinDir
    New-Directory $TempRoot

    Invoke-InstallStep -Name '7-Zip' -ScriptBlock { Install-7Zip }

    Invoke-InstallStep -Name 'Sysinternals Autoruns' -ScriptBlock {
        Install-SysinternalsArchive -ArchiveName 'Autoruns.zip' -FileMap @{
            'Autorunsc.exe' = 'autorunsc.exe'
            'Autorunsc64.exe' = 'autorunsc64.exe'
        }
    }
    Invoke-InstallStep -Name 'Sysinternals DU' -ScriptBlock {
        Install-SysinternalsArchive -ArchiveName 'DU.zip' -FileMap @{
            'du.exe' = 'du.exe'
            'du64.exe' = 'du64.exe'
        }
    }
    Invoke-InstallStep -Name 'Sysinternals Handle' -ScriptBlock {
        Install-SysinternalsArchive -ArchiveName 'Handle.zip' -FileMap @{
            'handle.exe' = 'handle.exe'
            'handle64.exe' = 'handle64.exe'
        }
    }
    Invoke-InstallStep -Name 'Sysinternals ProcDump' -ScriptBlock {
        Install-SysinternalsArchive -ArchiveName 'Procdump.zip' -FileMap @{
            'procdump.exe' = 'procdump.exe'
        }
    }
    Invoke-InstallStep -Name 'Sysinternals PsTools' -ScriptBlock {
        Install-SysinternalsArchive -ArchiveName 'PSTools.zip' -FallbackArchiveNames @('PsTools.zip') -FileMap @{
            'PsList.exe' = 'pslist.exe'
        }
    }
    Invoke-InstallStep -Name 'Sysinternals Sigcheck' -ScriptBlock {
        Install-SysinternalsArchive -ArchiveName 'Sigcheck.zip' -FileMap @{
            'sigcheck.exe' = 'sigcheck.exe'
            'sigcheck64.exe' = 'sigcheck64.exe'
        }
    }
    Invoke-InstallStep -Name 'Sysinternals Streams' -ScriptBlock {
        Install-SysinternalsArchive -ArchiveName 'Streams.zip' -FileMap @{
            'streams.exe' = 'streams.exe'
        }
    }

    Invoke-InstallStep -Name 'NirSoft BrowserAddonsView' -ScriptBlock {
        Install-NirSoftTool -ZipName 'browseraddonsview-x64.zip' -ExecutableName 'BrowserAddonsView.exe'
    }
    Invoke-InstallStep -Name 'NirSoft BrowsingHistoryView' -ScriptBlock {
        Install-NirSoftTool -ZipName 'browsinghistoryview-x64.zip' -ExecutableName 'BrowsingHistoryView.exe'
    }

    Invoke-InstallStep -Name 'AppCompatCacheParser' -ScriptBlock { Install-AppCompatCacheParser }
    Invoke-InstallStep -Name 'WinPmem' -ScriptBlock { Install-WinPmem }
    Invoke-InstallStep -Name 'Xpdf pdftotext' -ScriptBlock { Install-XpdfPdfToText }
    Invoke-InstallStep -Name 'pii.zip helper package' -ScriptBlock { New-PiiZip }
    Invoke-InstallStep -Name 'Memoryze' -ScriptBlock { Install-Memoryze }

    Write-Host ''
    Write-Host 'Installed/updated:'
    if ($Installed.Count -gt 0) {
        $Installed | Sort-Object -Unique | ForEach-Object { Write-Host " - $_" }
    }
    else {
        Write-Host ' - Nothing; all expected files already existed. Use -Force to overwrite.'
    }

    if ($Warnings.Count -gt 0) {
        Write-Host ''
        Write-Host 'Warnings:'
        $Warnings | ForEach-Object { Write-Warning $_ }
    }
}
finally {
    if (Test-Path -LiteralPath $TempRoot) {
        Remove-Item -LiteralPath $TempRoot -Recurse -Force
    }
}
