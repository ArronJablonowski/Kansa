<#
.Synopsis
    Run-KansaRemoteHost.ps1 
    Author: Aj 
    Last Modified: 7.8.2021

.DESCRIPTION
    This script is a handler script for Running Kansa Modules on the Remote Hosts 

    !!! THIS SCRIPT MUST BE RAN WITH LOCAL ADMIN PRIVILEGES !!!
    ###########################################################
    
#>

# $retryConection = 1  # Enable Retry   ### Uncomment to retry connections to a single host 

function KansaASCII {
    #Kansa ASCii art 
    cls
    Write-Host '   _  __     '                
    Write-Host '  | |/ /      '               
    Write-Host '  | '' / __ _ _ __  ___  __ _ '
    Write-Host '  |  < / _` | ''_ \/ __|/ _` | '
    Write-Host '  | . \ (_| | | | \__ \ (_| | '
    Write-Host '  |_|\_\__,_|_| |_|___/\__,_| '
    Write-Host '|=============================| ' 
}
KansaASCII

#Unblock all .ps1 files in dir
ls -r *.ps1 | Unblock-File

# temp add env variable for log parser 2.2
$env:Path = $env:Path + ';C:\Program Files (x86)\Log Parser 2.2'

#Share path to folder for mass collection of logs for threat hunting. (Optional)
#$sharePath = "\\Server_Name\share\Path\KansaAgent\ThreatHunting" 
$sharePath = ".\LogCollector"

#Target Host File
$targetHostList = ".\hostlist.txt"
#files to log live vs dead hosts
$liveHosts = ".\LiveHosts.txt"
$deadHosts = ".\DeadHosts.txt"
#Check for leftovers/Old Output Dirs
$oldOutputDir = ".\Output_*"
If(Test-Path $oldOutputDir){
    Write-Host ' ' 
    Write-Host '>>> WARNING! <<< - Another Output Directory has been Found' 
    Write-Host '----------------------------------------------------------'
    Write-Host 'A Directory Matching the naming convention of "Output_*" was found in Kansa''s root directory.'
    Write-Host 'This is most likely due to a terminated or crashed Kansa session.'
    Write-Host 'Please move or remove the Output folder. Then try again.' 
    #Write-host "Then try again."
    Write-host "" 
    Write-Host "Please Confirm Deletion by pressing Enter."
    # Write-Host "DELETE ALL?" 
    Remove-Item $oldOutputDir -Force
    Start-Sleep -Seconds 1
    #If leftovers still exist exit Kansa 
    If(Test-Path $oldOutputDir){
        Write-Host "Directory Still exists. Remove all 'Output_*' directories and try again."
        Write-Host "Exiting Kansa."
        exit
    }
    KansaASCII
}
#Sleep for 2 seconds 
Start-Sleep -s 2

#Verify WinRM can Communicate with host(s). This saves time, and makes Kansa more reliable when running against LARGE host lists. 
function verifyWinRMCommunications {
    Write-Host ' ' 
    Write-Host '>> Verifying PowerShell Remote Sessions' 
    Write-Host '---------------------------------------'   

    #vars to hold count  
    $testConnectionSuccess = 0
    $testConnectionFail = 0 
    $testedTotal = 0

    #Remove any Old Log files 
    If(Test-Path $liveHosts){Remove-Item $liveHosts}
    If(Test-Path $deadHosts){Remove-Item $deadHosts}

    #For each line in the supplied host file
    foreach($line in Get-Content $targetHostList) { # read file line by line
        $testResults = $null
        $testResults = Test-WSMan -ComputerName $line -Authentication default -ErrorAction SilentlyContinue
        if($null -ne $testResults){ 
            Write-Host " ~ WinRM Verification: $line - Successful "
            Add-Content -Path $liveHosts -Value $line
            $testConnectionSuccess = $testConnectionSuccess + 1
        }Else{ 
            Write-Host " x connection attempt: $line - Failed"
            $testConnectionFail = $testConnectionFail + 1
            Add-Content -Path $deadHosts -Value $line
        }
        $testedTotal = $testedTotal + 1
    }
    #Notify user verification has completed. 
    #Write-Host "Verification Complete."
    Start-Sleep -Seconds 1 

    #If more than 25 Hosts Scanned - Print Kansa ASCII Art again to clear the screen. 
    If ($testedTotal -gt 25) {KansaASCII}
    #Print Results to the screen  
    Write-Host " "
    Write-Host ">> WinRM Verification Results: "
    Write-Host "------------------------------ "
    Write-Host "  Total: $testedTotal"
    Write-Host "   Live: $testConnectionSuccess "
    Write-Host "   Dead: $testConnectionFail    "
    Start-Sleep -Seconds 2
} 
#Run Communications Verification 
verifyWinRMCommunications

#Try to Enable PSRemoting - IF $retryConection = 1:  !!! OLD LOGIC _ FUNCTION REMOVED and Base64'ed PSEXEC removed from code !!!!
<#If ($retryConection -eq 1) {
#Check if live host file exists, if not then check that the dead host file has no more than 1 host name
    If(!(Test-Path $liveHosts)){ #IF Live Host file does NOT exist 
        If(Test-Path $deadHosts){ #IF Dead Host file does exist 
            $nlines = 0;
            Get-Content $deadHosts -read 10 | ForEach-Object { $nlines += $_.Length }; #Count the number of lines in the file, up to 10 lines max. 
            If($nlines -eq 1){ #IF Dead Host file contains only ONE hostname - This is to prevent spraying clear text creds across a network 
                #get contents of the dead host file 
                $tryHostAgain = Get-Content $deadHosts -TotalCount 1     

                verifyWinRMCommunications # Retry WinRM Connection 
            }
        }
    }
} #>

Write-Host ' ' 
Write-Host '>> Loading Kansa Modules... Please Wait.' 
Write-Host '---------------------------------------- ' 
Start-Sleep -Seconds 2
#Check if *Live Host* file exists, else error out on screen and exit 
If(Test-Path $liveHosts){
    #Call Kansa with the Analysis Flag, Pushbin flag to move AutoRuns to remote host - then remove autoruns from remote host via -rmbin 
    .\Kansa.ps1 -TargetList .\LiveHosts.txt -Pushbin -rmbin -Analysis
}Else {
    Write-Host " >>> ERROR! <<< - Kansa is unable to establish an active WinRM session."
    Write-Host " "
    Write-Host "Please Check the Following: "
    Write-Host " - Host is Live and Accessible on the target network."
    Write-Host " - WinRM is Enabled on the target host(s)."
    Write-Host " - You have Administrative Privileges on the target host(s)."
    Write-Host " - You can enter a remote PowerShell Session on the target host(s)."
    Write-Host " - Pro Tip: IF you know you are experiencing DNS issues:"
    Write-Host "      Try adding the known IP/Hostname to your host file. Then try again."
    Write-Host " " 
    Write-Host "No work to be done. Exiting Kansa."
    Exit 
}

Write-Host ' ' 
Write-Host '>> Cleaning Up Results... Please wait.' 
Write-Host '--------------------------------------'

If(Test-Path $liveHosts){Move-Item -Path $liveHosts -Destination .\Output*}
If(Test-Path $deadHosts){Move-Item -Path $deadHosts -Destination .\Output*}

#Rename the listed files to .TXT because they are not formatted as CSVs
Function FormatResults { 
    Get-ChildItem -Filter ASEPImagePathLaunchStringMD5UnsignedStack.csv -Recurse -Depth 2 | Rename-Item -NewName {$_.name -replace '.csv', '.txt'}
    Get-ChildItem -Filter ASEPImagePathLaunchStringPublisherStack.csv -Recurse -Depth 2 | Rename-Item -NewName {$_.name -replace '.csv', '.txt'}
    Get-ChildItem -Filter ASEPImagePathLaunchStringStack.csv -Recurse -Depth 2 | Rename-Item -NewName {$_.name -replace '.csv', '.txt'}
    Get-ChildItem -Filter LogUserAssistValueStack.csv -Recurse -Depth 2 | Rename-Item -NewName {$_.name -replace '.csv', '.txt'}
    Get-ChildItem -Filter SMBShareStack.csv -Recurse -Depth 2 | Rename-Item -NewName {$_.name -replace '.csv', '.txt'}
    Get-ChildItem -Filter OSStack.csv -Recurse -Depth 2 | Rename-Item -NewName {$_.name -replace '.csv', '.txt'}
    Get-ChildItem -Filter IISStack.csv -Recurse -Depth 2 | Rename-Item -NewName {$_.name -replace '.csv', '.txt'}
    Get-ChildItem -Filter CriticalEventsStack.csv -Recurse -Depth 2 | Rename-Item -NewName {$_.name -replace '.csv', '.txt'}
    Get-ChildItem -Filter DNSServerSearchOrderStack.csv -Recurse -Depth 2 | Rename-Item -NewName {$_.name -replace '.csv', '.txt'}
    Get-ChildItem -Filter PSProfileScriptStack.csv -Recurse -Depth 2 | Rename-Item -NewName {$_.name -replace '.csv', '.txt'}
    Get-ChildItem -Filter PSProfileNameStack.csv -Recurse -Depth 2 | Rename-Item -NewName {$_.name -replace '.csv', '.txt'}
    Get-ChildItem -Filter StartupCommandStack.csv -Recurse -Depth 2 | Rename-Item -NewName {$_.name -replace '.csv', '.txt'}
    Get-ChildItem -Filter SystemModelStack.csv -Recurse -Depth 2 | Rename-Item -NewName {$_.name -replace '.csv', '.txt'}
}
FormatResults

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

#Function to add "sep=," to the top of all CSV files - this allows Excell to open the file without having to import the csv 
function add-toTopOfFile {
	foreach ($path in Get-ChildItem -Filter "*.csv" -Recurse -Depth 2 -Exclude "*\LogCollector\*") {
		#echo $path.fullname
		$orig = Get-Content $path.fullname
        $new = 'sep=,'
        if (!($orig -contains $new )) {
		    set-content $path.fullname -value $new, $orig
        }
	}
}
add-toTopOfFile

#Cleanup completed 
Write-Host 'Cleanup Complete.'
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

Function 7ZipResultsAndMove { 
    $resultsPath = Join-Path $PSScriptRoot 'Results'
    If(!(Test-Path -LiteralPath $resultsPath)){New-Item -Path $resultsPath -ItemType Directory -Force | Out-Null}

    #Check if this is a memeory dump - don't want to waste time compressing LARGE files. Especially memdumps in aff4 format, because its already compressed.
    $path = Get-ChildItem -Path ".\"  -Filter "*.aff4" -Recurse -Depth 2 -ErrorAction SilentlyContinue -Force
    If ($path.count -lt 1){
        
       #if Share/folder (.\LogCollector) available send data to folder  
       If([System.IO.Directory]::Exists("$sharePath")){    
            $folder = Get-childitem -path $PSScriptRoot -filter "Output*"
            Copy-Item -Path ".\$folder\*" -Destination $sharePath -Recurse -Force
            If(Test-path "$sharePath\AnalysisReports"){Remove-item -path "$sharePath\AnalysisReports" -Recurse -force }
            If(Test-path "$sharePath\DeadHosts.txt"){Remove-item -path "$sharePath\DeadHosts.txt" -Recurse -force }
            if(test-path "$sharePath\Error.log"){Remove-item -path "$sharePath\Error.log" -Recurse -force }
            if(test-path "$sharePath\LiveHosts.txt"){Remove-item -path "$sharePath\LiveHosts.txt" -Recurse -force }
        }

        #Add Sep=, to top of all Csv files for Excel - After uploading filed to share 
        # add-toTopOfFile

        #add files to zip folder 
        Write-Host ' '  
        Write-Host '>> Adding Kansa Results to Archive'
        Write-Host '---------------------------------------- ' 
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
        Remove-Item .\Output* -Exclude *.7z,*.zip -Recurse -Force
    }else {
        Move-Item ".\Output_*" $resultsPath -Force

    }
   
}
7ZipResultsAndMove

Write-Host ' '
Write-Host '>> Kansa Results Can be Found in the "Results" Folder:  ' 
Write-Host '------------------------------------------------------ '
$currentDir = Get-Location
$currentDirPath = $currentDir.Path
Write-Host " --> $currentDirPath\Results\{ *HERE* }"
#Write-Host ' '
