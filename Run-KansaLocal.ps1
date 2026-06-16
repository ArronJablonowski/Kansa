<#
.Synopsis
    Run-KansaLocal.ps1 
    Author: Aj 
    Last Modified: 7.8.21

.DESCRIPTION
    This script is a handler script for Running Kansa Modules on the local Host 

    !!! THIS SCRIPT MUST BE RAN WITH LOCAL ADMIN PRIVILEGES !!!
    ###########################################################
    
#>

#Kansa ASCii art
cls
Write-Host '   _  __     '                
    Write-Host '  | |/ /      '               
    Write-Host '  | '' / __ _ _ __  ___  __ _ '
    Write-Host '  |  < / _` | ''_ \/ __|/ _` | '
    Write-Host '  | . \ (_| | | | \__ \ (_| | '
    Write-Host '  |_|\_\__,_|_| |_|___/\__,_| '
    Write-Host '|=============================| ' 
    Write-Host ' ' 
    Write-Host '    Running Modules on:' $env:computername

Function Copy-KansaBinaryToSystemRoot {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$FileName
    )

    $source = Join-Path $PSScriptRoot "Modules\bin\$FileName"
    $destination = Join-Path $ENV:SYSTEMROOT $FileName

    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        if ($FileName -ieq '7z.zip') {
            return
        }

        Write-Warning "Helper binary '$FileName' was not found in Modules\bin. Related modules may be skipped or return no results."
        return
    }

    try {
        Copy-Item -LiteralPath $source -Destination $destination -Force -ErrorAction Stop
    }
    catch {
        Write-Warning "Unable to stage helper binary '$FileName' in $ENV:SYSTEMROOT. Related modules may be skipped. $($_.Exception.Message)"
        $Error.RemoveAt(0)
    }
}

Function Remove-KansaBinaryFromSystemRoot {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$FileName
    )

    $target = Join-Path $ENV:SYSTEMROOT $FileName
    if (Test-Path -LiteralPath $target -PathType Leaf) {
        Remove-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
    }
}

$kansaHelperBinaries = @(
    '7z.dll',
    '7z.exe',
    '7z.zip',
    'autorunsc.exe',
    'pdftotext.exe',
    'pii.zip',
    'sigcheck.exe',
    'streams.exe',
    'winpmem-2.1.post4.exe',
    'handle.exe',
    'pslist.exe',
    'BrowsingHistoryView.exe',
    'BrowserAddonsView.exe'
)

# Copy Bin Items to C:Windowns <-> $ENV:SYSTEMROOT -- !!THIS SCRIPT ASSUMES AUTORUNSC.EXE WILL BE IN $ENV:SYSTEMROOT!!
foreach ($binary in $kansaHelperBinaries) {
    Copy-KansaBinaryToSystemRoot -FileName $binary
}
<# Make output dir #>
#get date  
$date = Get-Date
$dateTime = $Date.ToString("yyyyMMddHHmmss")
#get computer name 
$output_dir = "Output_$env:computername"
#make folder "Output_<$PCName>_DateTime"
$folder = $output_dir + "_" + $dateTime
New-Item -ItemType directory -Path ".\$folder" 
Start-Sleep -Seconds 1 
#For loop to read Local_Modules.conf
foreach($line in Get-Content .\Modules\Modules.conf) {
    if($line -notlike "#*" -and $line -notlike "" -and $line -notlike " "){
        $module = $line
                
        $pathArray = $line.Split('-')
        $moduleName = $pathArray[1] -replace '.ps1',''
        $moduleName = $moduleName -replace ' ',''
        $moduleName = $moduleName -replace '\\',''
        $moduleName = $moduleName -replace ':',''
        $moduleName = $moduleName -replace '"',''
        $subfolder = ".\"+ $folder +"\"+ $moduleName      
        If(![System.IO.File]::Exists($subfolder )) {
            New-Item -ItemType Directory -Path $subfolder -ErrorAction SilentlyContinue
        }
        $formatModule = $module -replace '.ps1',''
        $formatedModuleName = $formatModule.Split('\')
        $tester = $formatedModuleName[1] 
        Write-Verbose "Waiting for $tester to complete." -Verbose
        #echo "Sub $subfolder"
        $cmd = ".\Modules\"+ $module
        #echo "CMD  $cmd "   
        $outputFile = $subfolder +"\"+ $env:computername +"-"+ $moduleName + ".csv"
        #echo $outputFile
        $moduleOutput = Invoke-Expression $cmd -ErrorAction SilentlyContinue
        if ($null -ne $moduleOutput) {
            $moduleOutput | Export-Csv -Path $outputFile -NoTypeInformation
        }
        else {
            Write-Warning "$tester returned no records. Output file was not created."
        }
        Write-Host " MODULE: $tester has completed." 
        #Write-Host "   HOST: $env:computername"
    }
}
# Remove staged helper binaries from C:\Windows <-> $ENV:SYSTEMROOT
foreach ($binary in $kansaHelperBinaries) {
    Remove-KansaBinaryFromSystemRoot -FileName $binary
}
Write-Host ' ' 
Write-Host '>> Cleaning Up Results... Please wait.' 
Write-Host '--------------------------------------'

#Cleanup the formatting of PsList
function formatPsListData{
    Get-ChildItem -Filter *pslist.csv -Recurse | Rename-Item -NewName {$_.name -replace '.csv', '.txt'}
	foreach ($path in Get-ChildItem -Filter "*pslist.txt" -Recurse) {
		#echo $path.fullname
		$fileContent = Get-Content $path.fullname
        $fileContent = $fileContent.Replace('"','')
        $fileContent = $fileContent.Replace('_',' ')	
        set-content $path.fullname -value $fileContent	
	}
}
formatPsListData

Write-Host ' '
Write-Host ' Cleanup Complete.'
Write-Host ' '
Start-Sleep -s 1 

Function New-KansaResultsArchive {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ArchiveBaseName
    )

    $root7Zip = Join-Path $PSScriptRoot '7z.exe'
    $path7Zip = Get-Command 7z.exe -ErrorAction SilentlyContinue
    $outputFolders = @(Get-ChildItem -Path $PSScriptRoot -Directory -Filter 'Output*' -ErrorAction SilentlyContinue)

    if ($outputFolders.Count -lt 1) {
        Write-Warning "No Output* folders were found to archive."
        return $null
    }

    $archiveName = "$ArchiveBaseName.7z"
    $archivePath = Join-Path $PSScriptRoot $archiveName

    if (Test-Path -LiteralPath $root7Zip -PathType Leaf) {
        & $root7Zip a $archiveName .\Output* | Out-Null
        if (($LASTEXITCODE -eq 0) -and (Test-Path -LiteralPath $archivePath -PathType Leaf)) {
            return $archiveName
        }

        Write-Warning "7-Zip was found in the Kansa root, but it did not create '$archiveName'. Falling back to Windows native ZIP compression."
    }
    elseif ($path7Zip) {
        & $path7Zip.Source a $archiveName .\Output* | Out-Null
        if (($LASTEXITCODE -eq 0) -and (Test-Path -LiteralPath $archivePath -PathType Leaf)) {
            return $archiveName
        }

        Write-Warning "7-Zip was found on PATH, but it did not create '$archiveName'. Falling back to Windows native ZIP compression."
    }
    else {
        Write-Warning "7-Zip was not found in the Kansa root or on PATH. Using Windows native ZIP compression."
    }

    $archiveName = "$ArchiveBaseName.zip"
    $archivePath = Join-Path $PSScriptRoot $archiveName
    Compress-Archive -Path $outputFolders.FullName -DestinationPath $archivePath -Force
    return $archiveName
}

Function ZipResultsAndMove { 
    #add files to zip folder  
    Write-Host ' '  
    Write-Host '>> Adding Kansa Results to Archive'
    Write-Host '---------------------------------------- ' 
    $resultsPath = Join-Path $PSScriptRoot 'Results'
    If(!(Test-Path -LiteralPath $resultsPath)){New-Item -Path $resultsPath -ItemType Directory -Force | Out-Null}
    $todaysDate = Get-Date -format "yyyyMMddHHmmss"
    $archiveName = New-KansaResultsArchive -ArchiveBaseName "Output_$todaysDate"
    if (-not $archiveName) {
        Write-Warning "Kansa results were not archived."
        return
    }

    #move Output*
    $archivePath = Join-Path $PSScriptRoot $archiveName
    if (Test-Path -LiteralPath $archivePath -PathType Leaf) {
        Move-Item -LiteralPath $archivePath -Destination $resultsPath -Force
    }
    else {
        Write-Warning "Archive '$archiveName' was expected but could not be found. Results were left unarchived in the Output folder."
        return
    }

    #remove Output* folder 
    Remove-Item .\Output* -Exclude *.7z,*.zip -Recurse -ErrorAction SilentlyContinue
}
ZipResultsAndMove

Write-Host ' '
Write-Host '>> Kansa Results Can be Found in the "Results" Folder:  ' 
Write-Host '------------------------------------------------------ '
$currentDir = Get-Location
$currentDirPath = $currentDir.Path
Write-Host " --> $currentDirPath\Results\{ *HERE* }"
